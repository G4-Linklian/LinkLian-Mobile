import 'package:json_annotation/json_annotation.dart';

part 'teaching_schedule_model.g.dart';

@JsonSerializable()
class TeachingScheduleModel {
  @JsonKey(name: 'subject_name')
  final String subjectName;

  @JsonKey(name: 'class_name')
  final String? className; 

  @JsonKey(name: 'day_of_week')
  final int dayOfWeek; 

  @JsonKey(name: 'start_time')
  final String startTime; 

  @JsonKey(name: 'end_time')
  final String endTime; 

  final String? room;
  final String? building;

  TeachingScheduleModel({
    required this.subjectName,
    required this.className,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.room,
    this.building,
  });

  String get locationText {
    if (building != null && building!.isNotEmpty) {
      return building!;
    }
    return '-';
  }

  factory TeachingScheduleModel.fromJson(Map<String, dynamic> json) =>
      _$TeachingScheduleModelFromJson(json);

  Map<String, dynamic> toJson() => _$TeachingScheduleModelToJson(this);
}
