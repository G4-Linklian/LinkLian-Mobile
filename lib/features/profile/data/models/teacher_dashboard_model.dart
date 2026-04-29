class TeacherDashboardResponse {
  final TeacherDashboardOverview overview;
  final List<TeacherSectionDetail> sections;

  TeacherDashboardResponse({required this.overview, required this.sections});

  factory TeacherDashboardResponse.fromJson(Map<String, dynamic> json) {
    return TeacherDashboardResponse(
      overview: TeacherDashboardOverview.fromJson(json['overview'] ?? {}),
      sections: ((json['sections'] as List?) ?? [])
          .map((e) => TeacherSectionDetail.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class TeacherDashboardOverview {
  final int totalFiles;
  final int totalLives;
  final int totalAssignments;
  final List<PopularPost> popularPosts;
  final int totalStudents;
  int filesChange;
  int livesChange;
  int assignmentsChange;

  TeacherDashboardOverview({
    required this.totalFiles,
    required this.totalLives,
    required this.totalAssignments,
    required this.popularPosts,
    required this.totalStudents,
    this.filesChange = 0,
    this.livesChange = 0,
    this.assignmentsChange = 0,
  });

  factory TeacherDashboardOverview.fromJson(Map<String, dynamic> json) {
    return TeacherDashboardOverview(
      totalFiles: json['totalFiles'] ?? 0,
      totalLives: json['totalLives'] ?? 0,
      totalAssignments: json['totalAssignments'] ?? 0,
      popularPosts: ((json['popularPosts'] as List?) ?? [])
          .map((e) => PopularPost.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalStudents: json['totalStudents'] ?? 0,
      filesChange:
          json['files_change'] as int? ?? json['filesChange'] as int? ?? 0,
      livesChange:
          json['lives_change'] as int? ?? json['livesChange'] as int? ?? 0,
      assignmentsChange:
          json['assignments_change'] as int? ??
          json['assignmentsChange'] as int? ??
          0,
    );
  }
}

class PopularPost {
  final String postId;
  final String title;
  final int bookmarkCount;
  final String sectionName;

  PopularPost({
    required this.postId,
    required this.title,
    required this.bookmarkCount,
    required this.sectionName,
  });

  factory PopularPost.fromJson(Map<String, dynamic> json) {
    return PopularPost(
      postId: json['postId'] ?? '',
      title: json['title'] ?? '',
      bookmarkCount: json['bookmarkCount'] ?? 0,
      sectionName: json['sectionName'] ?? '',
    );
  }
}

class TeacherSectionDetail {
  final String sectionId;
  final String sectionName;
  final String classLevel;
  final String subjectName;
  final int totalLives;
  final int totalAssignments;
  final List<AssignmentInfo> assignments;
  final List<LiveInfo> lives;
  final List<FileInfo> files;

  TeacherSectionDetail({
    required this.sectionId,
    required this.sectionName,
    required this.classLevel,
    required this.subjectName,
    required this.totalLives,
    required this.totalAssignments,
    required this.assignments,
    required this.lives,
    required this.files,
  });

  factory TeacherSectionDetail.fromJson(Map<String, dynamic> json) {
    return TeacherSectionDetail(
      sectionId: json['sectionId'] ?? '',
      sectionName: json['sectionName'] ?? '',
      classLevel: json['classLevel'] ?? '',
      subjectName: json['subjectName'] ?? '',
      totalLives: json['totalLives'] ?? 0,
      totalAssignments: json['totalAssignments'] ?? 0,
      assignments: ((json['assignments'] as List?) ?? [])
          .map((e) => AssignmentInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      lives: ((json['lives'] as List?) ?? [])
          .map((e) => LiveInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      files: ((json['files'] as List?) ?? [])
          .map((e) => FileInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class AssignmentInfo {
  final String assignmentId;
  final String assignmentName;
  final int submitted;
  final int notSubmitted;
  final int late;
  final int totalStudents;
  final DateTime? dueDate;

  AssignmentInfo({
    required this.assignmentId,
    required this.assignmentName,
    required this.submitted,
    required this.notSubmitted,
    required this.late,
    required this.totalStudents,
    this.dueDate,
  });

  factory AssignmentInfo.fromJson(Map<String, dynamic> json) {
    return AssignmentInfo(
      assignmentId: json['assignmentId'] ?? '',
      assignmentName: json['assignmentName'] ?? '',
      submitted: json['submitted'] ?? 0,
      notSubmitted: json['notSubmitted'] ?? 0,
      late: json['late'] ?? 0,
      totalStudents: json['totalStudents'] ?? 0,
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
    );
  }
}

class LiveInfo {
  final String liveId;
  final String title;
  final int questionCount;
  final int duration; // in minutes
  final DateTime liveDate;
  final String recordingUrl;

  LiveInfo({
    required this.liveId,
    required this.title,
    required this.questionCount,
    required this.duration,
    required this.liveDate,
    required this.recordingUrl,
  });

  factory LiveInfo.fromJson(Map<String, dynamic> json) {
    return LiveInfo(
      liveId: json['liveId'] ?? '',
      title: json['title'] ?? '',
      questionCount: json['questionCount'] ?? 0,
      duration: json['duration'] ?? 0,
      liveDate: json['liveDate'] != null
          ? DateTime.parse(json['liveDate'])
          : DateTime.now(),
      recordingUrl: json['recordingUrl'] ?? '',
    );
  }
}

class FileInfo {
  final String fileId;
  final String fileName;
  final List<String> questions;
  final String uploadDate;

  FileInfo({
    required this.fileId,
    required this.fileName,
    required this.questions,
    required this.uploadDate,
  });

  factory FileInfo.fromJson(Map<String, dynamic> json) {
    return FileInfo(
      fileId: json['fileId'] ?? '',
      fileName: json['fileName'] ?? '',
      questions: List<String>.from(json['questions'] ?? []),
      uploadDate: json['uploadDate'] ?? '',
    );
  }
}
