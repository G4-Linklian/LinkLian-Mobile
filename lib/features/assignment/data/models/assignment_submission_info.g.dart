// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'assignment_submission_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AssignmentSubmissionInfo _$AssignmentSubmissionInfoFromJson(
        Map<String, dynamic> json) =>
    AssignmentSubmissionInfo(
      assignmentId: _intFromJson(json['assignment_id']),
      dueDate: _dateTimeFromJson(json['due_date']),
      maxScore: _doubleFromJson(json['max_score']),
      isGroup: _boolFromJson(json['is_group']),
    );

Map<String, dynamic> _$AssignmentSubmissionInfoToJson(
        AssignmentSubmissionInfo instance) =>
    <String, dynamic>{
      'assignment_id': instance.assignmentId,
      'due_date': instance.dueDate?.toIso8601String(),
      'max_score': instance.maxScore,
      'is_group': instance.isGroup,
    };
