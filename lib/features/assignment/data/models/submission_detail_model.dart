class SubmissionDetailModel {
  final int submissionId;
  final int assignmentId;
  final DateTime? submittedAt;
  final double? score;
  final String? feedback;
  final DateTime? markedAt;
  final int? groupId;
  final String? groupName;
  final double? maxScore;
  final DateTime? dueDate;
  final bool isGroup;
  final List<SubmissionAttachmentDetail> attachments;

  const SubmissionDetailModel({
    required this.submissionId,
    required this.assignmentId,
    this.submittedAt,
    this.score,
    this.feedback,
    this.markedAt,
    this.groupId,
    this.groupName,
    this.maxScore,
    this.dueDate,
    required this.isGroup,
    required this.attachments,
  });

  factory SubmissionDetailModel.fromJson(Map<String, dynamic> json) {
    return SubmissionDetailModel(
      submissionId: _toInt(json['submission_id']),
      assignmentId: _toInt(json['assignment_id']),
      submittedAt: json['submitted_at'] != null
          ? DateTime.parse(json['submitted_at'].toString())
          : null,
      score: json['score'] != null ? _toDouble(json['score']) : null,
      feedback: json['feedback'] as String?,
      markedAt: json['marked_at'] != null
          ? DateTime.parse(json['marked_at'].toString())
          : null,
      groupId: json['group_id'] != null ? _toInt(json['group_id']) : null,
      groupName: json['group_name'] as String?,
      maxScore: json['max_score'] != null ? _toDouble(json['max_score']) : null,
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'].toString())
          : null,
      isGroup: json['is_group'] as bool? ?? false,
      attachments: (json['attachments'] as List<dynamic>? ?? [])
          .map((a) => SubmissionAttachmentDetail.fromJson(
              a as Map<String, dynamic>))
          .toList(),
    );
  }

  static int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.parse(v);
    return 0;
  }

  static double _toDouble(dynamic v) {
    if (v is double) return v;
    if (v is num) return v.toDouble();
    if (v is String) return double.parse(v);
    return 0.0;
  }
}

class SubmissionAttachmentDetail {
  final int attachmentId;
  final String fileUrl;
  final String? originalName;
  final String? fileType;
  final int? fileSize;

  const SubmissionAttachmentDetail({
    required this.attachmentId,
    required this.fileUrl,
    this.originalName,
    this.fileType,
    this.fileSize,
  });

  factory SubmissionAttachmentDetail.fromJson(Map<String, dynamic> json) {
    return SubmissionAttachmentDetail(
      attachmentId: _toInt(json['attachment_id']),
      fileUrl: json['file_url'] as String,
      originalName: json['original_name'] as String?,
      fileType: json['file_type'] as String?,
      fileSize: json['file_size'] != null ? _toInt(json['file_size']) : null,
    );
  }

  static int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.parse(v);
    return 0;
  }
}