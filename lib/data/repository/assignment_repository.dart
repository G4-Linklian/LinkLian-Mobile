import '../../core/services/api_client.dart';
import '../../core/utils/logger.dart';
import '../model/assignment_model.dart';
import 'package:get/get.dart' hide Response;
import 'package:dio/dio.dart' as dio;

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
      appLog.info('❌ Error creating group: $e');
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

      appLog.info('🔍 getGroup response: ${response.data}');

      if (response.statusCode == 200) {
        if (response.data is Map<String, dynamic>) {
          final data = response.data['data'];
          return data as Map<String, dynamic>?;
        }
        return null;
      }

      return null;
    } catch (e) {
      appLog.info('❌ Error fetching group: $e');
      return null;
    }
  }

  // assignment_repository.dart
  Future<List<Map<String, dynamic>>> getAllGroups({
    required int assignmentId,
  }) async {
    try {
      appLog.info('📡 Fetching all groups from assignment_id: $assignmentId');

      final response = await _apiClient.get(
        '/assignment/all-groups',
        queryParameters: {'assignment_id': assignmentId},
      );

      appLog.info('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? [];
        appLog.info('All group: ${data.length} groups');
        return List<Map<String, dynamic>>.from(data);
      }
      return [];
    } catch (e) {
      appLog.info('❌ Error fetching all groups: $e');
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
      appLog.info('❌ Error fetching students: $e');
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
      appLog.info('📡 updateGroup API call:');
      appLog.info('  - assignmentId: $assignmentId');
      appLog.info('  - groupId: $groupId');
      appLog.info('  - groupName: $groupName');
      appLog.info('  - memberIds: $memberIds');

      final response = await _apiClient.post(
        '/assignment/update-group',
        data: {
          'assignment_id': assignmentId,
          'group_id': groupId,
          'group_name': groupName,
          'member_ids': memberIds,
        },
      );

      appLog.info('📥 updateGroup response status: ${response.statusCode}');
      appLog.info('📥 updateGroup response data: ${response.data}');
      appLog.info(
        '📥 updateGroup response type: ${response.data.runtimeType}',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data is Map<String, dynamic>) {
          appLog.info('✅ Returning response.data as Map');
          return response.data as Map<String, dynamic>;
        } else {
          appLog.info('⚠️ response.data is not a Map: ${response.data}');
          return {'success': true, 'data': response.data};
        }
      }

      appLog.info('❌ Status code not 200/201: ${response.statusCode}');
      return null;
    } catch (e, stackTrace) {
      appLog.info('❌ Error updating group: $e');
      appLog.info('❌ Stack trace: $stackTrace');
      return null;
    }
  }

  /// Search assignments by keyword
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

  /// Create a new submission
  Future<Map<String, dynamic>?> createSubmission({
    required int assignmentId,
    int? groupId,
    List<Map<String, String>>? files,
  }) async {
    try {
      appLog.info('📤 createSubmission: assignmentId=$assignmentId, groupId=$groupId, files=${files?.length}');
      
      final response = await _apiClient.post(
        '/assignment/create-submission',
        data: {
          'assignment_id': assignmentId,
          if (groupId != null) 'group_id': groupId,
          if (files != null && files.isNotEmpty) 'files': files,
        },
      );

      appLog.info('📥 createSubmission response: ${response.statusCode} ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data as Map<String, dynamic>?;
      }
      return null;
    } on dio.DioException catch (e) {
      appLog.info('❌ Error creating submission: $e');
      appLog.info('❌ Response data: ${e.response?.data}');
      rethrow;
    } catch (e) {
      appLog.info('❌ Error creating submission: $e');
      return null;
    }
  }

  /// Update an existing submission
  Future<Map<String, dynamic>?> updateSubmission({
    required int submissionId,
    required int assignmentId,
    int? groupId,
    List<Map<String, String>>? files,
  }) async {
    try {
      final response = await _apiClient.post(
        '/assignment/update-submission',
        data: {
          'submission_id': submissionId,
          'assignment_id': assignmentId,
          if (groupId != null) 'group_id': groupId,
          if (files != null && files.isNotEmpty) 'files': files,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      appLog.info('❌ Error updating submission: $e');
      return null;
    }
  }

  /// Get submission detail
  Future<Map<String, dynamic>?> getSubmission({
    required int submissionId,
  }) async {
    try {
      final response = await _apiClient.get(
        '/assignment/submission',
        queryParameters: {'submission_id': submissionId},
      );

      if (response.statusCode == 200) {
        return response.data['data'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      appLog.info('❌ Error fetching submission: $e');
      return null;
    }
  }

  /// Upload file to blob storage
  Future<Map<String, dynamic>?> uploadSubmissionFile({
    required String filePath,
    required String fileName,
  }) async {
    try {
      final formData = dio.FormData.fromMap({
        'files': await dio.MultipartFile.fromFile(filePath, filename: fileName),
      });

      final response = await _apiClient.post(
        '/file-storage/upload/submission/submission-attachment',
        data: formData,
        options: dio.Options(
          contentType: 'multipart/form-data',
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>?;
        if (data != null) {
          // Backend returns { success, files: [{ fileUrl, originalName, ... }] }
          final files = data['files'] as List<dynamic>?;
          if (files != null && files.isNotEmpty) {
            final firstFile = files[0] as Map<String, dynamic>;
            return {
              'file_url': firstFile['fileUrl'] ?? firstFile['file_url'],
              'original_name': firstFile['originalName'] ?? firstFile['original_name'],
              'file_type': firstFile['fileType'] ?? firstFile['file_type'],
            };
          }
        }
        return data;
      }
      return null;
    } catch (e) {
      appLog.info('❌ Error uploading submission file: $e');
      return null;
    }
  }

  /// Delete a blob file
  Future<bool> deleteBlob({required String fileUrl}) async {
    try {
      final response = await _apiClient.post(
        '/file-storage/delete',
        data: {'file_url': fileUrl},
      );

      return response.statusCode == 200;
    } catch (e) {
      appLog.info('❌ Error deleting blob: $e');
      return false;
    }
  }
}
