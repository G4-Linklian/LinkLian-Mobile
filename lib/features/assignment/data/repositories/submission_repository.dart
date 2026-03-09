import 'package:LinkLian/core/services/api_client.dart';
import 'package:LinkLian/core/utils/logger.dart';
import 'package:dio/dio.dart' as dio;
import '../models/submission_model.dart';

class SubmissionRepository {
  final ApiClient apiClient;

  SubmissionRepository({required this.apiClient});

  Future<SubmissionModel?> createSubmission({
    required int assignmentId,
    int? groupId,
    required List<Map<String, dynamic>> files,
  }) async {
    try {
      final response = await apiClient.post(
        '/assignment/create-submission',
        data: {
          'assignment_id': assignmentId,
          if (groupId != null) 'group_id': groupId,
          'files': files,
        },
      );
      return _parseSubmissionResponse(response.data);
    } on dio.DioException catch (e) {
      appLog.error('[SubmissionRepo] createSubmission error: $e');
      return null;
    }
  }

  Future<SubmissionModel?> updateSubmission({
    required int submissionId,
    required int assignmentId,
    int? groupId,
    required List<Map<String, dynamic>> files,
  }) async {
    try {
      final response = await apiClient.post(
        '/assignment/update-submission',
        data: {
          'submission_id': submissionId,
          'assignment_id': assignmentId,
          if (groupId != null) 'group_id': groupId,
          'files': files,
        },
      );
      return _parseSubmissionResponse(response.data);
    } on dio.DioException catch (e) {
      appLog.error('[SubmissionRepo] updateSubmission error: $e');
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

      // Force assignment container + submission folder only.
      final response = await apiClient.post(
        '/file-storage/upload/assignment/submission',
        data: formData,
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) return null;
      final nestedData = data['data'];
      if (nestedData is Map<String, dynamic>) {
        return _normalizeUploadItem(nestedData);
      }
      if (nestedData is List &&
          nestedData.isNotEmpty &&
          nestedData.first is Map) {
        return _normalizeUploadItem(
          Map<String, dynamic>.from(nestedData.first as Map),
        );
      }

      final files = data['files'];
      if (files is List && files.isNotEmpty && files.first is Map) {
        return _normalizeUploadItem(
          Map<String, dynamic>.from(files.first as Map),
        );
      }
      if (data['file_url'] != null || data['fileUrl'] != null) {
        return _normalizeUploadItem(Map<String, dynamic>.from(data));
      }
      return null;
    } on dio.DioException catch (e) {
      appLog.error('[SubmissionRepo] uploadSubmissionFile error: $e');
    }
    return null;
  }

  Map<String, dynamic> _normalizeUploadItem(Map<String, dynamic> raw) {
    final fileUrl = raw['file_url'] ?? raw['fileUrl'] ?? '';
    final fileType = raw['file_type'] ?? raw['fileType'] ?? '';
    final originalName =
        raw['original_name'] ??
        raw['originalName'] ??
        raw['file_name'] ??
        raw['fileName'];

    return {
      'file_url': fileUrl.toString(),
      'file_type': fileType.toString(),
      if (originalName != null) 'original_name': originalName.toString(),
    };
  }

  Future<bool> deleteBlob({required String fileUrl}) async {
    try {
      await apiClient.delete(
        '/assignment/submission/blob',
        data: {'file_url': fileUrl},
      );
      return true;
    } on dio.DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 404) {
        // Endpoint/blob may not exist in some environments; treat as already removed.
        appLog.info(
          '[SubmissionRepo] deleteBlob ignored 404 for file_url=$fileUrl',
        );
        return true;
      }
      appLog.error('[SubmissionRepo] deleteBlob error: $e');
      return false;
    }
  }

  /// Grade a submission (Teacher)
  Future<bool> gradeSubmission({
    required int submissionId,
    required double score,
    required String feedback,
  }) async {
    try {
      final response = await apiClient.post(
        '/assignment/grade-submission',
        data: {
          'submission_id': submissionId,
          'score': score,
          'feedback': feedback,
        },
      );
      return response.data['success'] == true;
    } on dio.DioException catch (e) {
      appLog.error('[SubmissionRepo] gradeSubmission error: $e');
      return false;
    }
  }

  SubmissionModel? _parseSubmissionResponse(dynamic raw) {
    if (raw is! Map<String, dynamic>) return null;
    final data = raw['data'];
    if (data is Map<String, dynamic>) {
      return SubmissionModel.fromJson(data);
    }
    if (raw['submission'] is Map<String, dynamic>) {
      return SubmissionModel.fromJson(
        raw['submission'] as Map<String, dynamic>,
      );
    }
    if (raw['submission_id'] != null) {
      return SubmissionModel.fromJson(raw);
    }
    return null;
  }
}
