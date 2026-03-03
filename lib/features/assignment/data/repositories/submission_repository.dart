import '../../../../core/services/api_client.dart';
import '../../../../core/utils/logger.dart';
import 'package:dio/dio.dart' as dio;

/// Handles all submission and file operations for assignments.
/// Separated from AssignmentRepository because file I/O
/// is a distinct responsibility from assignment domain logic.
class SubmissionRepository {
  final ApiClient _apiClient;

  SubmissionRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  Future<Map<String, dynamic>?> createSubmission({
    required int assignmentId,
    int? groupId,
    List<Map<String, String>>? files,
  }) async {
    try {
      appLog.info(
        '📤 createSubmission: assignmentId=$assignmentId, groupId=$groupId, files=${files?.length}',
      );

      final response = await _apiClient.post(
        '/assignment/create-submission',
        data: {
          'assignment_id': assignmentId,
          if (groupId != null) 'group_id': groupId,
          if (files != null && files.isNotEmpty) 'files': files,
        },
      );

      appLog.info(
        '📥 createSubmission response: ${response.statusCode} ${response.data}',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data as Map<String, dynamic>?;
      }
      return null;
    } on dio.DioException catch (e) {
      appLog.info('❌ Error creating submission: ${e.response?.data}');
      rethrow;
    } catch (e) {
      appLog.info('❌ Error creating submission: $e');
      return null;
    }
  }

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
        options: dio.Options(contentType: 'multipart/form-data'),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>?;
        if (data == null) return null;

        final files = data['files'] as List<dynamic>?;
        if (files != null && files.isNotEmpty) {
          final first = files[0] as Map<String, dynamic>;
          return {
            'file_url': first['fileUrl'] ?? first['file_url'],
            'original_name': first['originalName'] ?? first['original_name'],
            'file_type': first['fileType'] ?? first['file_type'],
          };
        }
        return data;
      }
      return null;
    } catch (e) {
      appLog.info('❌ Error uploading submission file: $e');
      return null;
    }
  }

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
