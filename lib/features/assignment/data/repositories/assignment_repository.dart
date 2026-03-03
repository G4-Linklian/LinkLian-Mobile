import '../../../../core/services/api_client.dart';
import '../../../../core/utils/logger.dart';
import '../models/assignment_model.dart';
import '../models/group_model.dart';

class AssignmentRepository {
  final ApiClient _apiClient;

  AssignmentRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

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
      appLog.info('❌ Error fetching class assignments: $e');
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

      appLog.info('🔍 getPostAssignment response: ${response.data}');

      if (response.statusCode == 200) {
        return response.data['data'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      appLog.info('❌ Error fetching assignment post: $e');
      return null;
    }
  }

  Future<List<AssignmentModel>> searchAssignments({
    required int sectionId,
    required String keyword,
    String role = 'student',
    int limit = 50,
  }) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/assignment/search',
      queryParameters: {
        'section_id': sectionId,
        'keyword': keyword,
        'role': role,
        'limit': limit,
      },
    );

    final rawList =
        (response.data as Map<String, dynamic>)['data'] as List? ?? [];

    return rawList
        .map<AssignmentModel>(
            (e) => AssignmentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ===== Group =====

  Future<GroupModel?> getGroup({required int assignmentId}) async {
    try {
      final response = await _apiClient.get(
        '/assignment/group',
        queryParameters: {'assignment_id': assignmentId},
      );

      appLog.info('🔍 getGroup response: ${response.data}');

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final data = response.data['data'] as Map<String, dynamic>?;
        if (data == null) return null;
        return GroupModel.fromJson(data);
      }
      return null;
    } catch (e) {
      appLog.info('❌ Error fetching group: $e');
      return null;
    }
  }

  Future<List<GroupModel>> getAllGroups({required int assignmentId}) async {
    try {
      appLog.info('📡 Fetching all groups for assignment_id: $assignmentId');

      final response = await _apiClient.get(
        '/assignment/all-groups',
        queryParameters: {'assignment_id': assignmentId},
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as List? ?? [];
        appLog.info('All groups: ${data.length} groups');
        return data
            .map((e) => GroupModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      appLog.info('❌ Error fetching all groups: $e');
      return [];
    }
  }

  Future<bool> createGroup({
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
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      appLog.info('❌ Error creating group: $e');
      return false;
    }
  }

  Future<bool> updateGroup({
    required int assignmentId,
    required int groupId,
    required String groupName,
    required List<int> memberIds,
  }) async {
    try {
      appLog.info('📡 updateGroup: assignmentId=$assignmentId, groupId=$groupId');

      final response = await _apiClient.post(
        '/assignment/update-group',
        data: {
          'assignment_id': assignmentId,
          'group_id': groupId,
          'group_name': groupName,
          'member_ids': memberIds,
        },
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      appLog.info('❌ Error updating group: $e');
      return false;
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
      appLog.info('❌ Error fetching students: $e');
      return [];
    }
  }
}
