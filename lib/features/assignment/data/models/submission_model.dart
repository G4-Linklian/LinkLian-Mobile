import 'package:json_annotation/json_annotation.dart';

part 'submission_model.g.dart';

int _intFromJson(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

DateTime? _dateTimeFromJson(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

@JsonSerializable()
class SubmissionModel {
  @JsonKey(name: 'submission_id', fromJson: _intFromJson)
  final int submissionId;

  @JsonKey(name: 'assignment_id', fromJson: _intFromJson)
  final int? assignmentId;

  @JsonKey(name: 'group_id', fromJson: _intFromJson)
  final int groupId;

  @JsonKey(name: 'group_name')
  final String? groupName;

  @JsonKey(name: 'submitted_at', fromJson: _dateTimeFromJson)
  final DateTime? submittedAt;

  @JsonKey(name: 'marked_at', fromJson: _dateTimeFromJson)
  final DateTime? markedAt;

  @JsonKey(name: 'score', fromJson: _intFromJson)
  final int? score;

  final String? feedback;

  @JsonKey(name: 'attachments')
  final List<Map<String, dynamic>> attachments;

  const SubmissionModel({
    required this.submissionId,
    this.assignmentId,
    required this.groupId,
    this.groupName,
    this.submittedAt,
    this.markedAt,
    this.score,
    this.feedback,
    this.attachments = const [],
  });

  factory SubmissionModel.fromJson(Map<String, dynamic> json) =>
      _$SubmissionModelFromJson(json);

  Map<String, dynamic> toJson() => _$SubmissionModelToJson(this);

  // =========================
  // Helpers สำหรับ UI
  // =========================

  /// ส่งงานแล้วหรือยัง
  bool get isSubmitted => submittedAt != null;

  /// ครูตรวจแล้วหรือยัง
  bool get isMarked => markedAt != null;

  /// มีคะแนนหรือยัง
  bool get hasScore => score != null;

  /// แสดงสถานะ submission (ใช้ใน tab ส่งงาน)
  String get submissionStatus {
    if (!isSubmitted) return 'ยังไม่ส่ง';
    if (isSubmitted && !isMarked) return 'รอตรวจ';
    return 'ตรวจแล้ว';
  }
}
