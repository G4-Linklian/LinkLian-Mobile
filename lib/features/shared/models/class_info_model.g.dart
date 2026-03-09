// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'class_info_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClassInfoModel _$ClassInfoModelFromJson(Map<String, dynamic> json) =>
    ClassInfoModel(
      sectionId: _intFromJson(json['section_id']),
      sectionName: json['section_name'] as String?,
      subjectName: json['subject_name'] as String?,
      semester: json['semester'] as String?,
      studentCount: json['student_count'] == null
          ? 0
          : _intFromJson(json['student_count']),
    );

Map<String, dynamic> _$ClassInfoModelToJson(ClassInfoModel instance) =>
    <String, dynamic>{
      'section_id': instance.sectionId,
      'section_name': instance.sectionName,
      'subject_name': instance.subjectName,
      'semester': instance.semester,
      'student_count': instance.studentCount,
    };
