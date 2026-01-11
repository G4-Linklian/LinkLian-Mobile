// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'class_schedule_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClassScheduleModel _$ClassScheduleModelFromJson(Map<String, dynamic> json) =>
    ClassScheduleModel(
      dayOfWeek: (json['day_of_week'] as num).toInt(),
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      room: json['room'] == null
          ? null
          : RoomModel.fromJson(json['room'] as Map<String, dynamic>),
      building: json['building'] == null
          ? null
          : BuildingModel.fromJson(json['building'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ClassScheduleModelToJson(ClassScheduleModel instance) =>
    <String, dynamic>{
      'day_of_week': instance.dayOfWeek,
      'start_time': instance.startTime,
      'end_time': instance.endTime,
      'room': instance.room,
      'building': instance.building,
    };
