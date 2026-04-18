import 'package:LinkLian/core/services/api_client.dart';
import 'package:flutter/material.dart';
import '../models/dashboard_model.dart';

class DashboardRemoteDataSource {
  final ApiClient apiClient;

  DashboardRemoteDataSource({required this.apiClient});

  Future<DashboardResponse> getStudentDashboard({
    required int userId,
    required String reportMonth,
    required String roleType,
  }) async {
    final response = await apiClient.get(
      '/dashboard',
      queryParameters: {
        'user_sys_id': userId,
        'role_type': roleType,
        'report_month': reportMonth,
        'flag_valid': true,
      },
    );

    debugPrint('[DashboardRemoteDS] Response status: ${response.statusCode}');
    debugPrint(
      '[DashboardRemoteDS] Response success: ${response.data['success']}',
    );

    if (response.statusCode == 200 && response.data['success'] == true) {
      final dashboardData = response.data['data'] as List?;
      debugPrint(
        '[DashboardRemoteDS] Dashboard data length: ${dashboardData?.length}',
      );

      if (dashboardData != null && dashboardData.isNotEmpty) {
        final payload = dashboardData[0]['payload'] as Map<String, dynamic>?;
        debugPrint(
          '[DashboardRemoteDS] Payload keys: ${payload?.keys.toList()}',
        );

        if (payload != null) {
          final overview = payload['overview'] as Map<String, dynamic>?;
          debugPrint(
            '[DashboardRemoteDS] Overview keys: ${overview?.keys.toList()}',
          );
          debugPrint(
            '[DashboardRemoteDS] bookmarks_added value: ${overview?['bookmarks_added']}',
          );

          _cleanPayload(payload);

          final sections = payload['section'] as List?;
          debugPrint(
            '[DashboardRemoteDS] After clean - section count: ${sections?.length}',
          );
          if (sections != null && sections.isNotEmpty) {
            debugPrint('[DashboardRemoteDS] First section: ${sections[0]}');
          }

          return DashboardResponse.fromJson(payload);
        }
      }
    } else {
      debugPrint(
        '[DashboardRemoteDS] ERROR: Status code ${response.statusCode} or success false',
      );
      debugPrint('[DashboardRemoteDS] Full response: ${response.data}');
    }

    return DashboardResponse(
      overview: DashboardOverview(
        totalAssignments: 0,
        onTimeTotal: 0,
        lateTotal: 0,
        missingTotal: 0,
        onTimeRate: 0.0,
        bookmarksAdded: 0,
        totalFiles: 0,
        totalLives: 0,
        totalStudents: 0,
        popularPosts: [],
        filesChange: 0,
        livesChange: 0,
        assignmentsChange: 0,
      ),
      sections: [],
    );
  }

  Future<List<String>> getAvailableReportMonths({required int userId}) async {
    final response = await apiClient.get(
      '/dashboard/report-month',
      queryParameters: {'user_sys_id': userId},
    );

    if (response.statusCode == 200 && response.data['success'] == true) {
      final months = response.data['data'] as List?;
      return months?.cast<String>() ?? [];
    }

    return [];
  }

  void _cleanPayload(Map<String, dynamic> payload) {
    if (payload['overview'] == null) {
      // Build overview from assets if it exists
      final assets = payload['assets'] as Map<String, dynamic>?;
      if (assets != null) {
        payload['overview'] = {
          'total_assignments': assets['total_assignments'] ?? 0,
          'on_time_total': assets['on_time_total'] ?? 0,
          'late_total': assets['late_total'] ?? 0,
          'missing_total': assets['missing_total'] ?? 0,
          'on_time_rate': assets['on_time_rate'] ?? 0.0,
          'bookmarks_added': assets['bookmarks_added'] ?? 0,
          'total_files': 0,
          'total_lives': 0,
          'total_students': 0,
          'popular_posts': assets['popular_posts'] ?? [],
          'files_change': 0,
          'lives_change': 0,
          'assignments_change': 0,
        };
      } else {
        payload['overview'] = {
          'total_assignments': 0,
          'on_time_total': 0,
          'late_total': 0,
          'missing_total': 0,
          'on_time_rate': 0.0,
          'bookmarks_added': 0,
          'total_files': 0,
          'total_lives': 0,
          'total_students': 0,
          'popular_posts': [],
          'files_change': 0,
          'lives_change': 0,
          'assignments_change': 0,
        };
      }
    }

    final overview = payload['overview'] as Map<String, dynamic>?;
    if (overview != null) {
      overview['total_assignments'] ??= 0;
      overview['on_time_total'] ??= 0;
      overview['late_total'] ??= 0;
      overview['missing_total'] ??= 0;
      overview['on_time_rate'] ??= 0.0;
      overview['bookmarks_added'] ??= 0;
      overview['total_files'] ??= 0;
      overview['total_lives'] ??= 0;
      overview['total_students'] ??= 0;
      overview['popular_posts'] ??= [];
      overview['files_change'] ??= 0;
      overview['lives_change'] ??= 0;
      overview['assignments_change'] ??= 0;
    }

    final sections = payload['section'] as List?;
    if (sections != null && sections.isNotEmpty) {
      for (var i = 0; i < sections.length; i++) {
        final section = sections[i];
        if (section is Map<String, dynamic>) {
          section['section_id'] ??= 0;
          section['section_name'] ??= '';
          section['subject_name'] ??= '';

          // API uses 'assignment_stat' for student assignments
          var assignmentStats = section['assignment_stat'] as List?;

          // If no assignment_stat but has 'assignment', use that
          if ((assignmentStats == null || assignmentStats.isEmpty) &&
              section['assignment'] != null) {
            assignmentStats = section['assignment'] as List?;
          }

          if (assignmentStats != null && assignmentStats.isNotEmpty) {
            section['assignment_stat'] = assignmentStats;

            // Clean each assignment
            for (var assignment in assignmentStats) {
              if (assignment is Map<String, dynamic>) {
                assignment['assignment_id'] ??= 0;
                assignment['title'] ??= '';
                assignment['due_date'] ??= DateTime.now().toIso8601String();
                assignment['status'] ??= 'pending';
                assignment['score'] ??= 0;
              }
            }
          } else {
            section['assignment_stat'] = [];
          }
        }
      }
    } else {
      payload['section'] ??= [];
    }
  }
}
