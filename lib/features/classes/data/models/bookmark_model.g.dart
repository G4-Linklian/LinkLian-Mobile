// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bookmark_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BookmarkModel _$BookmarkModelFromJson(Map<String, dynamic> json) =>
    BookmarkModel(
      postId: _intFromJson(json['post_id']),
      postContentId: _intFromJson(json['post_content_id']),
      title: json['title'] as String,
      content: json['content'] as String,
      postType: json['post_type'] as String?,
      sectionName: json['section_name'] as String?,
      subjectName: json['subject_name'] as String?,
      creatorName: json['creator_name'] as String?,
      creatorId: _intFromJson(json['creator_id']),
      savedAt: DateTime.parse(json['saved_at'] as String),
      flagValid: json['flag_valid'] as bool? ?? true,
    );

Map<String, dynamic> _$BookmarkModelToJson(BookmarkModel instance) =>
    <String, dynamic>{
      'post_id': instance.postId,
      'post_content_id': instance.postContentId,
      'title': instance.title,
      'content': instance.content,
      'post_type': instance.postType,
      'section_name': instance.sectionName,
      'subject_name': instance.subjectName,
      'creator_name': instance.creatorName,
      'creator_id': instance.creatorId,
      'saved_at': instance.savedAt.toIso8601String(),
      'flag_valid': instance.flagValid,
    };
