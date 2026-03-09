import '../../../../core/services/api_client.dart';
import '../../../../core/utils/api_response_parser.dart';
import '../../../../core/utils/logger.dart';
import '../models/assignment_model.dart';
import '../models/group_model.dart';
import '../models/assignment_post_detail_model.dart';
import '../../../shared/models/profile_model.dart';
import '../models/student_submission_status_model.dart';
import '../models/submission_detail_model.dart';

class AssignmentRepository {
  final ApiClient _apiClient;

  AssignmentRepository({required ApiClient apiClient}) : _apiClient = apiClient;
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
        return ApiResponseParser.parseList(
          response.data,
          AssignmentModel.fromJson,
        );
      }
      return [];
    } catch (e) {
      appLog.error('❌ Error fetching class assignments: $e');
      return [];
    }
  }

  Future<AssignmentPostDetailModel?> getPostAssignment({
    required int postId,
    String? role,
  }) async {
    try {
      final response = await _apiClient.get(
        '/assignment/post',
        queryParameters: {'post_id': postId, if (role != null) 'role': role},
      );

      if (response.statusCode == 200) {
        // Also extract subject_name_th from post
        return ApiResponseParser.parseObject(
          response.data,
          AssignmentPostDetailModel.fromJson,
        );
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
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/assignment/search',
        queryParameters: {
          'section_id': sectionId,
          'keyword': keyword,
          'role': role,
          'limit': limit,
        },
      );

      appLog.info('🔍 searchAssignments response: $response.data');
      if (response.statusCode == 200) {
        return ApiResponseParser.parseList(
          response.data,
          AssignmentModel.fromJson,
        );
      }
      return [];
    } catch (e) {
      appLog.info('❌ Error searching assignments: $e');
      return [];
    }
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
        return ApiResponseParser.parseObject(
          response.data,
          GroupModel.fromJson,
        );
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
        return ApiResponseParser.parseList(response.data, GroupModel.fromJson);
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
      appLog.info(
        '📡 updateGroup: assignmentId=$assignmentId, groupId=$groupId',
      );

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

Future<List<ProfileModel>> getStudentsInSection({
  required int sectionId,
}) async {
  try {
    final response = await _apiClient.get(
      '/section/enrollment',
      queryParameters: {
        'section_id': sectionId,
        'flag_valid': true,
        'user_status': 'Active',  
      },
    );

    if (response.statusCode == 200) {
      return ApiResponseParser.parseList(
        response.data,
        ProfileModel.fromJson,
      );
    }
    return [];
  } catch (e) {
    appLog.info('❌ Error fetching students: $e');
    return [];
  }
}
  /// Get all students with submission status for a given assignment (Teacher view)
  Future<List<StudentSubmissionStatusModel>> getStudentsSubmissionStatus({
    required int assignmentId,
  }) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/assignment/submission/students/$assignmentId',
      );
      return ApiResponseParser.parseList(
        response.data,
        StudentSubmissionStatusModel.fromJson,
      );
    } catch (e) {
      appLog.error('[AssignmentRepo] getStudentsSubmissionStatus error: $e');
      return [];
    }
  }

  /// Get submission detail by submission_id (Teacher view)
  Future<SubmissionDetailModel?> getSubmissionDetail({
    required int submissionId,
  }) async {
    try {
      final response = await _apiClient.get(
        '/assignment/submission/detail/$submissionId',
      );
      final detail = ApiResponseParser.parseObject(
        response.data,
        SubmissionDetailModel.fromJson,
      );
      appLog.info(
        '[AssignmentRepo] getSubmissionDetail: submissionId=$submissionId, '
        'attachments=${detail?.attachments.length ?? 0}',
      );
      return detail;
    } catch (e) {
      appLog.error('[AssignmentRepo] getSubmissionDetail error: $e');
      return null;
    }
  }
}
