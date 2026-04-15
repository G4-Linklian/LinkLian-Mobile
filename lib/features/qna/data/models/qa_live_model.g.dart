// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'qa_live_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QaLive _$QaLiveFromJson(Map<String, dynamic> json) => QaLive(
      qaLiveId: _intFromJson(json['qa_live_id']),
      liveTitle: json['live_title'] as String?,
      sectionId: _intFromJson(json['section_id']),
      liveBy: _intFromJson(json['live_by']),
      postId: _intFromJson(json['post_id']),
      createdAt: _dateTimeFromJson(json['started_at']),
      updatedAt: _dateTimeFromJson(json['ended_at']),
      currentSlide: json['current_slide'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$QaLiveToJson(QaLive instance) => <String, dynamic>{
      'qa_live_id': instance.qaLiveId,
      'live_title': instance.liveTitle,
      'section_id': instance.sectionId,
      'live_by': instance.liveBy,
      'post_id': instance.postId,
      'started_at': instance.createdAt.toIso8601String(),
      'ended_at': instance.updatedAt?.toIso8601String(),
      'current_slide': instance.currentSlide,
    };
