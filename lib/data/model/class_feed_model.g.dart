// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'class_feed_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClassFeedModel _$ClassFeedModelFromJson(Map<String, dynamic> json) =>
    ClassFeedModel(
      sectionId: ClassFeedModel._intFromJson(json['section_id']),
      sectionName: json['section_name'] as String,
      subjectCode: json['subject_code'] as String,
      subjectNameTh: json['subject_name_th'] as String,
      subjectNameEn: json['subject_name_en'] as String,
      learningAreaName: json['learning_area_name'] as String,
      semester: json['semester'] as String,
      schedules: (json['schedules'] as List<dynamic>)
          .map((e) => ClassScheduleModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      displayClassName: json['display_class_name'] as String?,
      position: json['position'] as String?,
      eduType: json['edu_type'] as String?,
      levelNum: (json['level_num'] as num?)?.toInt(),
      levelName: json['level_name'] as String?,
      className: json['class_name'] as String?,
      programType: json['program_type'] as String?,
      studyPlanName: json['study_plan_name'] as String?,
    );

Map<String, dynamic> _$ClassFeedModelToJson(ClassFeedModel instance) =>
    <String, dynamic>{
      'section_id': instance.sectionId,
      'section_name': instance.sectionName,
      'subject_code': instance.subjectCode,
      'subject_name_th': instance.subjectNameTh,
      'subject_name_en': instance.subjectNameEn,
      'learning_area_name': instance.learningAreaName,
      'semester': instance.semester,
      'schedules': instance.schedules,
      'position': instance.position,
      'edu_type': instance.eduType,
      'level_num': instance.levelNum,
      'level_name': instance.levelName,
      'class_name': instance.className,
      'program_type': instance.programType,
      'study_plan_name': instance.studyPlanName,
      'display_class_name': instance.displayClassName,
    };
