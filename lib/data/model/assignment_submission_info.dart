import 'package:json_annotation/json_annotation.dart';

part 'assignment_submission_info.g.dart';

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
class AssignmentSubmissionInfo {
  @JsonKey(name: 'assignment_id', fromJson: _intFromJson)
  final int assignmentId;

  @JsonKey(name: 'due_date', fromJson: _dateTimeFromJson)
  final DateTime? dueDate;

  @JsonKey(name: 'max_score', fromJson: _intFromJson)
  final int maxScore;

  @JsonKey(name: 'is_group')
  final bool isGroup;

  const AssignmentSubmissionInfo({
    required this.assignmentId,
    this.dueDate,
    required this.maxScore,
    required this.isGroup,
  });

  factory AssignmentSubmissionInfo.fromJson(Map<String, dynamic> json) =>
      _$AssignmentSubmissionInfoFromJson(json);

  Map<String, dynamic> toJson() =>
      _$AssignmentSubmissionInfoToJson(this);
}