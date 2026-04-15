// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'qa_question_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QaQuestion _$QaQuestionFromJson(Map<String, dynamic> json) => QaQuestion(
      qaQuestionId: json['qa_question_id'],
      qaLiveId: _intFromJson(json['qa_live_id']),
      question: json['question'] as String,
      askerId: _intFromJson(json['asker_id']),
      asker: json['asker'] == null
          ? null
          : QaAsker.fromJson(json['asker'] as Map<String, dynamic>),
      upvoteCount:
          json['upvote_count'] == null ? 0 : _intFromJson(json['upvote_count']),
      isUpvoted: json['is_upvoted'] == null
          ? false
          : _boolFromJson(json['is_upvoted']),
      isAnonymous: json['is_anonymous'] == null
          ? false
          : _boolFromJson(json['is_anonymous']),
      slideNumber:
          json['slide_number'] == null ? 0 : _intFromJson(json['slide_number']),
      createdAt: _dateTimeFromJson(json['created_at']),
      postId: _intFromJson(json['post_id']),
      attachmentId: _intFromJson(json['attachment_id']),
      status: json['status'] as String?,
      isLocalPending: json['is_local_pending'] == null
          ? false
          : _boolFromJson(json['is_local_pending']),
    );

Map<String, dynamic> _$QaQuestionToJson(QaQuestion instance) =>
    <String, dynamic>{
      'qa_question_id': instance.qaQuestionId,
      'qa_live_id': instance.qaLiveId,
      'question': instance.question,
      'asker_id': instance.askerId,
      'asker': instance.asker,
      'upvote_count': instance.upvoteCount,
      'is_upvoted': instance.isUpvoted,
      'is_anonymous': instance.isAnonymous,
      'slide_number': instance.slideNumber,
      'created_at': instance.createdAt.toIso8601String(),
      'post_id': instance.postId,
      'attachment_id': instance.attachmentId,
      'status': instance.status,
      'is_local_pending': instance.isLocalPending,
    };
