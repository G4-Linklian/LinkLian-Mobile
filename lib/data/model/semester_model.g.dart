// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'semester_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SemesterModel _$SemesterModelFromJson(Map<String, dynamic> json) =>
    SemesterModel(
      semesterId: SemesterModel._intFromJson(json['semester_id']),
      semester: json['semester'] as String,
      status: json['status'] as String,
      flagValid: json['flag_valid'] as bool,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
    );

Map<String, dynamic> _$SemesterModelToJson(SemesterModel instance) =>
    <String, dynamic>{
      'semester_id': instance.semesterId,
      'semester': instance.semester,
      'status': instance.status,
      'flag_valid': instance.flagValid,
      'start_date': instance.startDate.toIso8601String(),
      'end_date': instance.endDate.toIso8601String(),
    };
