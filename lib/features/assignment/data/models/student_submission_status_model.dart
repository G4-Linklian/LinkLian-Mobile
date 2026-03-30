class StudentSubmissionStatusModel {
  final int? userSysId;
  final String firstName;
  final String lastName;
  final String? profilePic;
  final String? code;
  final int? submissionId;
  final DateTime? submittedAt;
  final double? score;
  final String? feedback;
  final DateTime? markedAt;
  final int? groupId;
  final String? groupName;
  final String submissionStatus; // 'submitted' | 'not_submitted'

  const StudentSubmissionStatusModel({
    this.userSysId,
    required this.firstName,
    required this.lastName,
    this.profilePic,
    this.code,
    this.submissionId,
    this.submittedAt,
    this.score,
    this.feedback,
    this.markedAt,
    this.groupId,
    this.groupName,
    required this.submissionStatus,
  });

  bool get isUserDeleted => userSysId == null;

  String get displayName =>
      isUserDeleted ? 'ไม่มีบัญชีผู้ใช้งาน' : '$firstName $lastName'.trim();

  bool get hasSubmitted {
    if (submissionId != null || submittedAt != null) return true;
    final normalized = submissionStatus.toLowerCase();
    return normalized == 'submitted' ||
        normalized == 'graded' ||
        normalized == 'marked';
  }

  bool get isGraded =>
      markedAt != null ||
      score != null ||
      (feedback?.trim().isNotEmpty ?? false);

  static int? _toNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final asInt = int.tryParse(value);
      if (asInt != null) return asInt;
      final asDouble = double.tryParse(value);
      if (asDouble != null) return asDouble.toInt();
    }
    return null;
  }

  static double? _toNullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  factory StudentSubmissionStatusModel.fromJson(Map<String, dynamic> json) {
    return StudentSubmissionStatusModel(
      userSysId: _toNullableInt(json['user_sys_id']),
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      profilePic: json['profile_pic'] as String?,
      code: json['code'] as String?,
      submissionId: _toNullableInt(json['submission_id']),
      submittedAt: json['submitted_at'] != null
          ? DateTime.tryParse(json['submitted_at'].toString())
          : null,
      score: _toNullableDouble(json['score']),
      feedback: json['feedback'] as String?,
      markedAt: json['marked_at'] != null
          ? DateTime.tryParse(json['marked_at'].toString())
          : null,
      groupId: _toNullableInt(json['group_id']),
      groupName: json['group_name'] as String?,
      submissionStatus:
          (json['submission_status']?.toString() ?? 'not_submitted'),
    );
  }
}
