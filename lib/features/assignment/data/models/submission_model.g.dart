// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'submission_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubmissionModel _$SubmissionModelFromJson(Map<String, dynamic> json) =>
    SubmissionModel(
      submissionId: _intFromJson(json['submission_id']),
      assignmentId: _intFromJson(json['assignment_id']),
      groupId: _intFromJson(json['group_id']),
      groupName: json['group_name'] as String?,
      submittedAt: _dateTimeFromJson(json['submitted_at']),
      markedAt: _dateTimeFromJson(json['marked_at']),
      score: _intFromJson(json['score']),
      feedback: json['feedback'] as String?,
    );

Map<String, dynamic> _$SubmissionModelToJson(SubmissionModel instance) =>
    <String, dynamic>{
      'submission_id': instance.submissionId,
      'assignment_id': instance.assignmentId,
      'group_id': instance.groupId,
      'group_name': instance.groupName,
      'submitted_at': instance.submittedAt?.toIso8601String(),
      'marked_at': instance.markedAt?.toIso8601String(),
      'score': instance.score,
      'feedback': instance.feedback,
    };
