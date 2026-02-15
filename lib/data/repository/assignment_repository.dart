import '../../core/services/api_client.dart';
import '../../core/utils/logger.dart';
import '../model/assignment_model.dart';
import 'package:get/get.dart' hide Response;

class AssignmentRepository {
  final ApiClient _apiClient = Get.find<ApiClient>();

  /// Get assignments for a specific section
  /// Calls: GET /social-feed/assignment?section_id=X&role=Y
  /// Header: x-user-id (attached automatically by ApiClient)
  Future<List<AssignmentModel>> getClassAssignments({
    required int sectionId,
    String? role,
     int offset = 0,
  int limit = 10,
  }) async {
    try {
      final response = await _apiClient.get(
        '/assignment',
        queryParameters: {
          'section_id': sectionId,
          if (role != null) 'role': role,
          'offset': offset,
        'limit': limit,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List
            ? response.data
            : (response.data['data'] ?? []);
        return data.map((json) => AssignmentModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      AppLogger.info('❌ Error fetching class assignments: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getPostAssignment({
    required int postId,
    String? role,
  }) async {
    try {
      final response = await _apiClient.get(
        '/assignment/post',
        queryParameters: {'post_id': postId, if (role != null) 'role': role},
      );

      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      AppLogger.info('❌ Error fetching assignment post: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> createGroup({
    required int assignmentId,
    required String groupName,
    required List<int> memberIds,
  }) async {
    try {
      final response = await _apiClient.post(
        '/assignment/create-group',
        data: {
          'assignment_id': assignmentId,
          'group_name': groupName,
          'member_ids': memberIds,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      }
      return null;
    } catch (e) {
      AppLogger.info('❌ Error creating group: $e');
      return null;
    }
  }

  // assignment_repository.dart
  Future<Map<String, dynamic>?> getGroup({required int assignmentId}) async {
    try {
      final response = await _apiClient.get(
        '/assignment/group',
        queryParameters: {'assignment_id': assignmentId},
      );

      AppLogger.info('🔍 getGroup response: ${response.data}');

      if (response.statusCode == 200) {
        // ✅ ตอนนี้ดึงจาก data wrapper
        if (response.data is Map<String, dynamic>) {
          final data = response.data['data'];
          return data as Map<String, dynamic>?;
        }
        return null;
      }

      return null;
    } catch (e) {
      AppLogger.info('❌ Error fetching group: $e');
      return null;
    }
  }

  // assignment_repository.dart
  Future<List<Map<String, dynamic>>> getAllGroups({
    required int assignmentId,
  }) async {
    try {
      AppLogger.info('📡 กำลังดึงกลุ่มทั้งหมดจาก assignment_id: $assignmentId');

      final response = await _apiClient.get(
        '/assignment/all-groups',
        queryParameters: {'assignment_id': assignmentId},
      );

      AppLogger.info('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? [];
        AppLogger.info('✅ ได้กลุ่มทั้งหมด: ${data.length} กลุ่ม');
        return List<Map<String, dynamic>>.from(data);
      }
      return [];
    } catch (e) {
      AppLogger.info('❌ Error fetching all groups: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getStudentsInSection({
    required int sectionId,
  }) async {
    try {
      final response = await _apiClient.get(
        '/section/enrollment',
        queryParameters: {'section_id': sectionId, 'flag_valid': true},
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
      }
      return [];
    } catch (e) {
      AppLogger.info('❌ Error fetching students: $e');
      return [];
    }
  }

// assignment_repository.dart
Future<Map<String, dynamic>?> updateGroup({
  required int assignmentId,
  required int groupId,
  required String groupName,
  required List<int> memberIds,
}) async {
  try {
    AppLogger.info('📡 updateGroup API call:');
    AppLogger.info('  - assignmentId: $assignmentId');
    AppLogger.info('  - groupId: $groupId');
    AppLogger.info('  - groupName: $groupName');
    AppLogger.info('  - memberIds: $memberIds');

    final response = await _apiClient.post(
      '/assignment/update-group',
      data: {
        'assignment_id': assignmentId,
        'group_id': groupId,
        'group_name': groupName,
        'member_ids': memberIds,
      },
    );

    AppLogger.info('📥 updateGroup response status: ${response.statusCode}');
    AppLogger.info('📥 updateGroup response data: ${response.data}');
    AppLogger.info('📥 updateGroup response type: ${response.data.runtimeType}');

    // ✅ เช็ค status code ให้ครอบคลุม
    if (response.statusCode == 200 || response.statusCode == 201) {
      // ✅ ตรวจสอบว่า response.data เป็น Map หรือไม่
      if (response.data is Map<String, dynamic>) {
        AppLogger.info('✅ Returning response.data as Map');
        return response.data as Map<String, dynamic>;
      } else {
        AppLogger.info('⚠️ response.data is not a Map: ${response.data}');
        // ถ้า response.data ไม่ใช่ Map ให้ wrap มันใหม่
        return {
          'success': true,
          'data': response.data,
        };
      }
    }

    AppLogger.info('❌ Status code not 200/201: ${response.statusCode}');
    return null;
  } catch (e, stackTrace) {
    AppLogger.info('❌ Error updating group: $e');
    AppLogger.info('❌ Stack trace: $stackTrace');
    return null;
  }
}


}
