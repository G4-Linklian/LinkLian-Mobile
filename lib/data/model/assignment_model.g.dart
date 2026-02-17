// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'assignment_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AssignmentModel _$AssignmentModelFromJson(Map<String, dynamic> json) =>
    AssignmentModel(
      assignmentId: _intFromJson(json['assignment_id']),
      postId: _intFromJson(json['post_id']),
      title: json['title'] as String,
      subjectNameTh: json['subject_name_th'] as String,
      subjectNameEn: json['subject_name_en'] as String,
      assignmentType: json['assignment_type'] as String,
      isGroup: json['is_group'] as bool,
      dueDate: _dateTimeFromJson(json['due_date']),
      totalStudents: json['total_students'] == null
          ? 0
          : _intFromJson(json['total_students']),
      submittedCount: json['submitted_count'] == null
          ? 0
          : _intFromJson(json['submitted_count']),
      submittedAt: _dateTimeFromJson(json['submitted_at']),
      educators: _educatorsFromJson(json['educators']),
      totalGroups:
          json['total_groups'] == null ? 0 : _intFromJson(json['total_groups']),
      submittedGroups: json['submitted_groups'] == null
          ? 0
          : _intFromJson(json['submitted_groups']),
    );

Map<String, dynamic> _$AssignmentModelToJson(AssignmentModel instance) =>
    <String, dynamic>{
      'assignment_id': instance.assignmentId,
      'post_id': instance.postId,
      'title': instance.title,
      'subject_name_th': instance.subjectNameTh,
      'subject_name_en': instance.subjectNameEn,
      'assignment_type': instance.assignmentType,
      'due_date': instance.dueDate?.toIso8601String(),
      'total_students': instance.totalStudents,
      'submitted_count': instance.submittedCount,
      'is_group': instance.isGroup,
      'submitted_at': instance.submittedAt?.toIso8601String(),
      'total_groups': instance.totalGroups,
      'submitted_groups': instance.submittedGroups,
      'educators': instance.educators,
    };
