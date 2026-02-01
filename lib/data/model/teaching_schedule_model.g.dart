// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'teaching_schedule_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TeachingScheduleModel _$TeachingScheduleModelFromJson(
        Map<String, dynamic> json) =>
    TeachingScheduleModel(
      scheduleId: _intFromJson(json['scheduleId']),
      dayOfWeek: _intFromJson(json['dayOfWeek']),
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      className: json['className'] as String?,
      subjectName: json['subjectName'] as String,
      subjectCode: json['subjectCode'] as String?,
      building: json['building'] as String?,
    );

Map<String, dynamic> _$TeachingScheduleModelToJson(
        TeachingScheduleModel instance) =>
    <String, dynamic>{
      'scheduleId': instance.scheduleId,
      'dayOfWeek': instance.dayOfWeek,
      'startTime': instance.startTime,
      'endTime': instance.endTime,
      'className': instance.className,
      'subjectName': instance.subjectName,
      'subjectCode': instance.subjectCode,
      'building': instance.building,
    };
