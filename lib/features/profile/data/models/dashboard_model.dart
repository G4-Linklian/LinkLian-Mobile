import 'package:LinkLian/core/utils/logger.dart';
import 'package:flutter/foundation.dart';

// Helper function to format seconds to "X ชม. Y นาที" (matching web formatSecondsToHourMinute)
String formatSecondsToHourMinute(dynamic value) {
  if (value == null || (value is num && (value.isNaN || value < 0))) {
    return "-";
  }

  final seconds = (value is num) ? value.toInt() : 0;
  final totalMinutes = seconds ~/ 60;
  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;

  if (hours == 0) {
    return '$minutes นาที';
  }

  if (minutes == 0) {
    return '$hours ชม.';
  }

  return '$hours ชม. $minutes นาที';
}

// Helper function to format minutes to "X ชม. Y นาที" or "Live" if 0
String formatMinutesToHourMinute(dynamic value) {
  if (value == null || (value is num && (value.isNaN || value < 0))) {
    return "-";
  }

  final minutes = (value is num) ? value.toInt() : 0;

  // If 0 minutes, it's likely an ongoing/active live session
  if (minutes == 0) {
    return "Live"; // ongoing live
  }

  final hours = minutes ~/ 60;
  final mins = minutes % 60;

  if (hours == 0) {
    return '$mins นาที';
  }

  if (mins == 0) {
    return '$hours ชม.';
  }

  return '$hours ชม. $mins นาที';
}

class DashboardResponse {
  final DashboardOverview overview;
  final List<SectionDetail> sections;

  DashboardResponse({required this.overview, required this.sections});

  factory DashboardResponse.fromJson(Map<String, dynamic> json) {
    // Teacher dashboard structure: { assets: {...}, top_bookmarked_posts: [...], section: [...] }
    // Student dashboard structure: { overview: {...}, section: [...] }

    final assets = json['assets'] as Map<String, dynamic>?;
    final topBookmarkedPosts = json['top_bookmarked_posts'] as List?;
    final sectionsData = json['section'] as List? ?? json['sections'] as List?;

    // If assets exists, it's teacher dashboard
    if (assets != null) {
      return DashboardResponse(
        overview: DashboardOverview(
          totalAssignments: _toInt(assets['total_assignment']) ?? 0,
          onTimeTotal: 0, // Not provided in teacher dashboard
          lateTotal: 0, // Not provided in teacher dashboard
          missingTotal: 0, // Not provided in teacher dashboard
          onTimeRate: 0.0, // Not provided in teacher dashboard
          bookmarksAdded: 0, // Will be calculated from top_bookmarked_posts
          totalFiles: _toInt(assets['total_file']) ?? 0,
          totalLives: _toInt(assets['total_qa_live']) ?? 0,
          totalStudents: 0, // Will get from sections if needed
          popularPosts: (topBookmarkedPosts ?? [])
              .map((e) => PopularPost.fromJson(e as Map<String, dynamic>))
              .toList(),
          filesChange: _toInt(assets['file_this_month']) ?? 0,
          livesChange: _toInt(assets['qa_live_this_month']) ?? 0,
          assignmentsChange: _toInt(assets['assignment_this_month']) ?? 0,
        ),
        sections: (sectionsData ?? [])
            .map((e) => SectionDetail.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    }

    // Otherwise it's student dashboard
    final overview = json['overview'] as Map<String, dynamic>?;
    return DashboardResponse(
      overview: overview != null
          ? DashboardOverview.fromJson(overview)
          : DashboardOverview(
              totalAssignments: 0,
              onTimeTotal: 0,
              lateTotal: 0,
              missingTotal: 0,
              onTimeRate: 0.0,
              bookmarksAdded: 0,
            ),
      sections: (sectionsData ?? [])
          .map((e) => SectionDetail.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class DashboardOverview {
  final int totalAssignments;
  final int onTimeTotal;
  final int lateTotal;
  final int missingTotal;
  final double onTimeRate;
  final int bookmarksAdded;
  // Teacher specific fields
  final int totalFiles;
  final int totalLives;
  final int totalStudents;
  final List<PopularPost> popularPosts;
  // Change tracking - mutable for calculation
  int filesChange;
  int livesChange;
  int assignmentsChange;

  DashboardOverview({
    required this.totalAssignments,
    required this.onTimeTotal,
    required this.lateTotal,
    required this.missingTotal,
    required this.onTimeRate,
    required this.bookmarksAdded,
    this.totalFiles = 0,
    this.totalLives = 0,
    this.totalStudents = 0,
    this.popularPosts = const [],
    this.filesChange = 0,
    this.livesChange = 0,
    this.assignmentsChange = 0,
  });

  factory DashboardOverview.fromJson(Map<String, dynamic> json) {
    final bookmarksValue = _toInt(
      json['bookmarks_added'] ?? json['bookmarksAdded'],
    );

    return DashboardOverview(
      totalAssignments:
          _toInt(json['total_assignments'] ?? json['totalAssignments']) ?? 0,
      onTimeTotal: _toInt(json['on_time_total'] ?? json['onTimeTotal']) ?? 0,
      lateTotal: _toInt(json['late_total'] ?? json['lateTotal']) ?? 0,
      missingTotal: _toInt(json['missing_total'] ?? json['missingTotal']) ?? 0,
      onTimeRate:
          (json['on_time_rate'] as num? ?? json['onTimeRate'] as num?)
              ?.toDouble() ??
          0.0,
      bookmarksAdded: bookmarksValue ?? 0,
      totalFiles: _toInt(json['total_files'] ?? json['totalFiles']) ?? 0,
      totalLives: _toInt(json['total_lives'] ?? json['totalLives']) ?? 0,
      totalStudents:
          _toInt(json['total_students'] ?? json['totalStudents']) ?? 0,
      popularPosts:
          ((json['popular_posts'] as List?) ??
                  (json['popularPosts'] as List?) ??
                  [])
              .map((e) => PopularPost.fromJson(e as Map<String, dynamic>))
              .toList(),
      filesChange: _toInt(json['files_change'] ?? json['filesChange']) ?? 0,
      livesChange: _toInt(json['lives_change'] ?? json['livesChange']) ?? 0,
      assignmentsChange:
          _toInt(json['assignments_change'] ?? json['assignmentsChange']) ?? 0,
    );
  }
}

/// Helper function to convert dynamic to int (handles both int and double from API)
int? _toInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

class PopularPost {
  final String postId;
  final String title;
  final int bookmarkCount;
  final String sectionName;
  final List<Map<String, dynamic>> sections;

  PopularPost({
    required this.postId,
    required this.title,
    required this.bookmarkCount,
    required this.sectionName,
    this.sections = const [],
  });

  factory PopularPost.fromJson(Map<String, dynamic> json) {
    // Backend sends: { post_id, post_content_id, title, bookmark_count, section_instances: [...] }
    final sectionInstances = json['section_instances'] as List?;
    String sectionName = '';
    List<Map<String, dynamic>> sections = [];

    if (sectionInstances != null && sectionInstances.isNotEmpty) {
      sections = List<Map<String, dynamic>>.from(sectionInstances);
      final firstSection = sectionInstances[0] as Map<String, dynamic>?;
      sectionName = firstSection?['section_name'] ?? '';

      // Debug: show what's in first section_instance
      appLog.debug(
        '[PopularPost] First section_instance keys: ${firstSection?.keys.toList()}',
      );
      if (firstSection != null) {
        appLog.debug('[PopularPost]   post_id: ${firstSection['post_id']}');
        appLog.debug('[PopularPost]   section_id: ${firstSection['section_id']}');
        appLog.debug(
          '[PopularPost]   section_name: ${firstSection['section_name']}',
        );
        appLog.debug(
          '[PopularPost]   subject_name: ${firstSection['subject_name']}',
        );
      }
    }

    // Use post_id if available (it's the actual post ID), fallback to post_content_id
    final postId =
        json['post_id']?.toString() ??
        json['post_content_id']?.toString() ??
        '';

    return PopularPost(
      postId: postId,
      title: json['title'] ?? '',
      bookmarkCount:
          _toInt(json['bookmark_count'] ?? json['bookmarkCount']) ?? 0,
      sectionName: sectionName,
      sections: sections,
    );
  }
}

class SectionDetail {
  final int sectionId;
  final String sectionName;
  final String subjectName;
  final List<AssignmentData> assignments;
  final List<LiveData> lives;

  SectionDetail({
    required this.sectionId,
    this.sectionName = '',
    required this.subjectName,
    this.assignments = const [],
    this.lives = const [],
  });

  factory SectionDetail.fromJson(Map<String, dynamic> json) {
    
    final assignmentStat = json['assignment_stat'] as List?;
    final assignments = json['assignment'] as List?;

  List<LiveData> lives = [];

   final qaLiveInsight = json['qa_live_insight'] as Map<String, dynamic>?;
    if (qaLiveInsight != null && qaLiveInsight.isNotEmpty) {
      final livesList = qaLiveInsight['lives'] as List? ?? [];
      if (livesList.isNotEmpty) {
        lives = livesList
            .map((e) => LiveData.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } else {
      // Student dashboard structure
      final livesData = json['live'] as List? ?? json['lives'] as List? ?? [];
      if (livesData.isNotEmpty) {
        lives = livesData
            .map((e) => LiveData.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }

    return SectionDetail(
      sectionId: _toInt(json['section_id']) ?? 0,
      sectionName: json['section_name'] as String? ?? '',
      subjectName: json['subject_name'] as String? ?? '',
      assignments: (assignmentStat ?? assignments ?? [])
          .map((e) => AssignmentData.fromJson(e as Map<String, dynamic>))
          .toList(),
      lives: lives,
    );
  }

  int get onTimeCount => assignments.where((a) => a.status == 'on_time').length;
  int get lateCount => assignments.where((a) => a.status == 'late').length;
  int get missingCount =>
      assignments.where((a) => a.status == 'missing').length;
  int get pendingCount =>
      assignments.where((a) => a.status == 'pending').length;
}

class AssignmentData {
  final int assignmentId;
  final String title;
  final DateTime dueDate;
  final String status; 
  final int score;
  // For teacher dashboard - aggregate counts
  final int onTimeCount;
  final int lateCount;
  final int missingCount;

  AssignmentData({
    required this.assignmentId,
    required this.title,
    required this.dueDate,
    this.status = 'pending',
    this.score = 0,
    this.onTimeCount = 0,
    this.lateCount = 0,
    this.missingCount = 0,
  });

  factory AssignmentData.fromJson(Map<String, dynamic> json) {
 
    return AssignmentData(
      assignmentId: _toInt(json['assignment_id']) ?? 0,
      title: json['title'] as String? ?? '',
      dueDate:
          DateTime.tryParse(json['due_date'] as String? ?? '')?.toLocal() ??
          DateTime.now().toLocal(),
      status: json['status'] as String? ?? 'pending',
      score: _toInt(json['score']) ?? 0,
      onTimeCount: _toInt(json['on_time_count']) ?? 0,
      lateCount: _toInt(json['late_count']) ?? 0,
      missingCount: _toInt(json['missing_count']) ?? 0,
    );
  }
}

class LiveData {
  final int liveId;
  final String title;
  final DateTime liveDate;
  final int duration; // in minutes
  final String recordingUrl;
  final int totalQuestions; 
  final List<QAData> qas;
  final List<TopQuestionedFile> topQuestionedFiles;

  LiveData({
    required this.liveId,
    required this.title,
    required this.liveDate,
    this.duration = 0,
    this.recordingUrl = '',
    this.totalQuestions = 0,
    this.qas = const [],
    this.topQuestionedFiles = const [],
  });

  factory LiveData.fromJson(Map<String, dynamic> json) {
  
    final totalQuestions =
        _toInt(json['total_question']) ?? (json['qas'] as List?)?.length ?? 0;

    final durationValue = json['duration_second'] ?? json['duration'];
    final minutes = _convertDurationToMinutes(durationValue);

    // DEBUG: Print received duration values
    appLog.debug(
      '[LiveData] Raw duration_second: ${json['duration_second']} (type: ${json['duration_second'].runtimeType})',
    );
    appLog.debug(
      '[LiveData] duration fallback: ${json['duration']} (type: ${json['duration'].runtimeType})',
    );
    appLog.debug('[LiveData] Converted to minutes: $minutes');
    appLog.debug('[LiveData] Title: ${json['title']} | Duration: ${minutes}m');

    return LiveData(
      liveId:
          _toInt(json['qa_live_id'] ?? json['live_id'] ?? json['liveId']) ?? 0,
      title: json['title'] as String? ?? '',
      liveDate:
          DateTime.tryParse(
            json['started_at'] as String? ?? json['live_date'] as String? ?? '',
          )?.toLocal() ??
          DateTime.now().toLocal(),
      duration: minutes,
      recordingUrl: json['recording_url'] as String? ?? '',
      totalQuestions: totalQuestions,
      qas: _parseQAs(json),
      topQuestionedFiles: _parseTopQuestionedFiles(json),
    );
  }

  static int _convertDurationToMinutes(dynamic duration) {
    if (duration == null) {
      appLog.debug('[_convertDurationToMinutes] Duration is null');
      return 0;
    }
    if (duration is int) {
      // If duration_second, convert to minutes
      final minutes = (duration ~/ 60);
      appLog.debug(
        '[_convertDurationToMinutes] Int value: $duration seconds → $minutes minutes',
      );
      return minutes;
    }
    if (duration is double) {
      final minutes = (duration ~/ 60).toInt();
      appLog.debug(
        '[_convertDurationToMinutes] Double value: $duration seconds → $minutes minutes',
      );
      return minutes;
    }
    if (duration is String) {
      final parsed = int.tryParse(duration) ?? 0;
      final minutes = (parsed ~/ 60);
      appLog.debug(
        '[_convertDurationToMinutes] String value: $duration → parsed $parsed seconds → $minutes minutes',
      );
      return minutes;
    }
    appLog.debug(
      '[_convertDurationToMinutes] Unknown type: ${duration.runtimeType}',
    );
    return 0;
  }

  static List<QAData> _parseQAs(Map<String, dynamic> json) {
    // Backend sends: top_questioned_file, qa_data, or qas
    final qaList =
        (json['top_questioned_file'] ??
                json['qa_data'] ??
                json['qas'] ??
                <dynamic>[])
            as List;
    return qaList
        .map((e) => QAData.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static List<TopQuestionedFile> _parseTopQuestionedFiles(
    Map<String, dynamic> json,
  ) {
    // Parse top_questioned_file array
    final filesList = (json['top_questioned_file'] as List?) ?? [];
    return filesList
        .map((e) => TopQuestionedFile.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

class QAData {
  final int qaId;
  final String question;
  final String answer;
  final String askedBy;

  // For top_questioned_file structure
  final String? attachmentName;
  final int? attachmentId;
  final List<dynamic>? topPage;

  QAData({
    required this.qaId,
    required this.question,
    this.answer = '',
    this.askedBy = '',
    this.attachmentName,
    this.attachmentId,
    this.topPage,
  });

  factory QAData.fromJson(Map<String, dynamic> json) {
    // Supports both qa_data and top_questioned_file structures
    return QAData(
      qaId: _toInt(json['qa_id'] ?? json['qaId'] ?? json['attachment_id']) ?? 0,
      question:
          json['question'] as String? ??
          json['attachment_name'] as String? ??
          '',
      answer: json['answer'] as String? ?? '',
      askedBy: json['asked_by'] as String? ?? json['askedBy'] as String? ?? '',
      attachmentName: json['attachment_name'] as String?,
      attachmentId: _toInt(json['attachment_id']),
      topPage: json['top_page'] as List?,
    );
  }
}

class TopQuestionedFile {
  final int attachmentId;
  final String attachmentName;
  final List<int> topPages; 

  TopQuestionedFile({
    required this.attachmentId,
    required this.attachmentName,
    this.topPages = const [],
  });

  /// Count total questions from top_page array
  int get totalQuestionCount {
    final topPage = topPages;
    return topPage.length;
  }

  factory TopQuestionedFile.fromJson(Map<String, dynamic> json) {
    final topPageList = json['top_page'] as List? ?? [];
    final pageNumbers = <int>[];

    for (final page in topPageList) {
      if (page is Map<String, dynamic>) {
        final pageNum = _toInt(page['page_number']) ?? 0;
        if (pageNum > 0) {
          pageNumbers.add(pageNum);
        }
      }
    }

    return TopQuestionedFile(
      attachmentId: _toInt(json['attachment_id']) ?? 0,
      attachmentName: json['attachment_name'] as String? ?? 'ไฟล์ไม่ระบุ',
      topPages: pageNumbers,
    );
  }
}

class ReportMonth {
  final String month; // YYYY-MM format

  ReportMonth({required this.month});

  factory ReportMonth.fromJson(String json) {
    return ReportMonth(month: json);
  }
}
