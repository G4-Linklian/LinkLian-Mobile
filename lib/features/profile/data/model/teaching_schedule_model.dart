import 'package:json_annotation/json_annotation.dart';

part 'teaching_schedule_model.g.dart';

// Custom JSON converters for flexible type handling
int _intFromJson(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  if (value is double) return value.toInt();
  return 0;
}

@JsonSerializable()
class TeachingScheduleModel {
  @JsonKey(name: 'scheduleId', fromJson: _intFromJson)
  final int scheduleId;

  @JsonKey(name: 'dayOfWeek', fromJson: _intFromJson)
  final int dayOfWeek;

  @JsonKey(name: 'startTime')
  final String startTime;

  @JsonKey(name: 'endTime')
  final String endTime;

  @JsonKey(name: 'className')
  final String? className;

  @JsonKey(name: 'subjectName')
  final String subjectName;

  @JsonKey(name: 'subjectCode')
  final String? subjectCode;

  @JsonKey(name: 'building')
  final String? building;

  TeachingScheduleModel({
    required this.scheduleId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.className,
    required this.subjectName,
    this.subjectCode,
    this.building,
  });

  factory TeachingScheduleModel.fromJson(Map<String, dynamic> json) =>
      _$TeachingScheduleModelFromJson(json);

  Map<String, dynamic> toJson() => _$TeachingScheduleModelToJson(this);
}
