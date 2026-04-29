import 'package:json_annotation/json_annotation.dart';

part 'assignment_submission_info.g.dart';

int _intFromJson(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

double _doubleFromJson(dynamic value) {
  if (value == null) return 0;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

bool _boolFromJson(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    return normalized == 'true' || normalized == '1';
  }
  return false;
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

  @JsonKey(name: 'max_score', fromJson: _doubleFromJson)
  final double maxScore;

  @JsonKey(name: 'is_group', fromJson: _boolFromJson)
  final bool isGroup;

  const AssignmentSubmissionInfo({
    required this.assignmentId,
    this.dueDate,
    required this.maxScore,
    required this.isGroup,
  });

  factory AssignmentSubmissionInfo.fromJson(Map<String, dynamic> json) =>
      _$AssignmentSubmissionInfoFromJson(json);

  Map<String, dynamic> toJson() => _$AssignmentSubmissionInfoToJson(this);
}
