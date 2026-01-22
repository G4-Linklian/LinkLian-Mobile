// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'teaching_schedule_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TeachingScheduleModel _$TeachingScheduleModelFromJson(
        Map<String, dynamic> json) =>
    TeachingScheduleModel(
      subjectName: json['subject_name'] as String,
      className: json['class_name'] as String?,
      dayOfWeek: (json['day_of_week'] as num).toInt(),
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      room: json['room'] as String?,
      building: json['building'] as String?,
    );

Map<String, dynamic> _$TeachingScheduleModelToJson(
        TeachingScheduleModel instance) =>
    <String, dynamic>{
      'subject_name': instance.subjectName,
      'class_name': instance.className,
      'day_of_week': instance.dayOfWeek,
      'start_time': instance.startTime,
      'end_time': instance.endTime,
      'room': instance.room,
      'building': instance.building,
    };
