// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'education_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EducationModel _$EducationModelFromJson(Map<String, dynamic> json) =>
    EducationModel(
      type: json['type'] as String,
      level: json['level'] as String?,
      classroom: json['classroom'] as String?,
      studyPlan: json['study_plan'] as String?,
      faculty: json['faculty'] as String?,
      program: json['program'] as String?,
      year: (json['year'] as num?)?.toInt(),
      display: json['display'] as String,
    );

Map<String, dynamic> _$EducationModelToJson(EducationModel instance) =>
    <String, dynamic>{
      'type': instance.type,
      'level': instance.level,
      'classroom': instance.classroom,
      'study_plan': instance.studyPlan,
      'faculty': instance.faculty,
      'program': instance.program,
      'year': instance.year,
      'display': instance.display,
    };
