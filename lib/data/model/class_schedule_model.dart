import 'package:json_annotation/json_annotation.dart';
import 'room_model.dart';
import 'building_model.dart';

part 'class_schedule_model.g.dart';

@JsonSerializable()
class ClassScheduleModel {
  @JsonKey(name: 'day_of_week')
  final int dayOfWeek;

  @JsonKey(name: 'start_time')
  final String startTime;

  @JsonKey(name: 'end_time')
  final String endTime;

  final RoomModel? room;
  final BuildingModel? building;

  const ClassScheduleModel({
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.room,
    this.building,
  });

  factory ClassScheduleModel.fromJson(Map<String, dynamic> json) =>
      _$ClassScheduleModelFromJson(json);

  Map<String, dynamic> toJson() => _$ClassScheduleModelToJson(this);

  @override
  String toString() {
    return 'ClassSchedule(day: $dayOfWeek, $startTime-$endTime)';
  }
}