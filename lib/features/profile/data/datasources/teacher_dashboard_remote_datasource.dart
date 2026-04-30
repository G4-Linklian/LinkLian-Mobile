import 'package:LinkLian/features/profile/data/models/teacher_dashboard_model.dart';
import 'package:dio/dio.dart';
import '../../../../core/services/api_client.dart';
// import '../model/teacher_dashboard_model.dart';

class TeacherDashboardRemoteDataSource {
  final ApiClient apiClient;

  TeacherDashboardRemoteDataSource({required this.apiClient});

  Future<TeacherDashboardResponse> getTeacherDashboard({
    required String userId,
  }) async {
    try {
      final response = await apiClient.get(
        '/dashboard/teacher',
        queryParameters: {'userId': userId},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        
        // Clean data before parsing
        _cleanTeacherPayload(data);
        
        return TeacherDashboardResponse.fromJson(data);
      }
      throw Exception('Failed to load teacher dashboard');
    } on DioException catch (e) {
      throw Exception('API Error: ${e.message}');
    }
  }

  Future<List<String>> getAvailableReportMonths({
    required String userId,
  }) async {
    try {
      final response = await apiClient.get(
        '/dashboard/report-month',
        queryParameters: {'userId': userId},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data['months'] is List) {
          return List<String>.from(data['months']);
        }
        return [];
      }
      throw Exception('Failed to load available months');
    } on DioException catch (e) {
      throw Exception('API Error: ${e.message}');
    }
  }

  /// Clean teacher payload - ensure all fields have proper values
  void _cleanTeacherPayload(Map<String, dynamic> payload) {
    // Ensure assets exists (teacher doesn't have 'overview')
    payload['assets'] ??= {};
    
    final assets = payload['assets'];
    if (assets is Map<String, dynamic>) {
      assets['total_qa_live'] ??= 0;
      assets['qa_live_this_month'] ??= 0;
      assets['total_file'] ??= 0;
      assets['file_this_month'] ??= 0;
      assets['total_assignment'] ??= 0;
      assets['assignment_this_month'] ??= 0;
    }

    // Ensure top_bookmarked_posts exists
    payload['top_bookmarked_posts'] ??= [];
    final posts = payload['top_bookmarked_posts'];
    if (posts is List) {
      for (var post in posts) {
        if (post is Map<String, dynamic>) {
          post['post_content_id'] ??= '';
          post['title'] ??= '';
          post['bookmark_count'] ??= 0;
          post['section_instances'] ??= [];
        }
      }
    }

    // Ensure sections exists
    payload['section'] ??= [];
    final sections = payload['section'];
    if (sections is List && sections.isNotEmpty) {
      for (var section in sections) {
        if (section is Map<String, dynamic>) {
          section['section_id'] ??= '';
          section['section_name'] ??= '';
          section['class_level'] ??= '';
          section['subject_name'] ??= '';
          section['total_lives'] ??= 0;
          section['total_assignments'] ??= 0;

          // API uses 'assignment_stat' for teacher assignments
          final assignmentStats = section['assignment_stat'];
          if (assignmentStats is List) {
            for (var assignment in assignmentStats) {
              if (assignment is Map<String, dynamic>) {
                assignment['assignment_id'] ??= '';
                assignment['assignment_name'] ??= '';
                assignment['title'] ??= ''; // Some payloads use 'title'
                assignment['submitted'] ??= 0;
                assignment['not_submitted'] ??= 0;
                assignment['late'] ??= 0;
                assignment['total_students'] ??= 0;
                assignment['due_date'] ??=
                  DateTime.now().toLocal().toIso8601String();
              }
            }
          } else {
            section['assignment_stat'] = [];
          }

          section['lives'] = [];
          section['files'] = [];

          // Clean lives
          final lives = section['lives'];
          if (lives is List) {
            for (var live in lives) {
              if (live is Map<String, dynamic>) {
                live['live_id'] ??= '';
                live['title'] ??= '';
                live['question_count'] ??= 0;
                live['duration'] ??= 0;
                live['live_date'] ??=
                  DateTime.now().toLocal().toIso8601String();
                live['recording_url'] ??= '';
              }
            }
          }

          // Clean files
          final files = section['files'];
          if (files is List) {
            for (var file in files) {
              if (file is Map<String, dynamic>) {
                file['file_id'] ??= '';
                file['file_name'] ??= '';
                file['questions'] ??= [];
                file['upload_date'] ??=
                  DateTime.now().toLocal().toIso8601String();
              }
            }
          }
        }
      }
    } else {
      payload['section'] = [];
    }
  }
}
