// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bookmark_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BookmarkModel _$BookmarkModelFromJson(Map<String, dynamic> json) =>
    BookmarkModel(
      postId: _intFromJson(json['post_id']),
      title: json['title'] as String,
      content: json['content'] as String,
      sectionName: json['section_name'] as String?,
      subjectName: json['subject_name'] as String?,
      educatorName: json['educator_name'] as String?,
      savedAt: DateTime.parse(json['saved_at'] as String),
    );

Map<String, dynamic> _$BookmarkModelToJson(BookmarkModel instance) =>
    <String, dynamic>{
      'post_id': instance.postId,
      'title': instance.title,
      'content': instance.content,
      'section_name': instance.sectionName,
      'subject_name': instance.subjectName,
      'educator_name': instance.educatorName,
      'saved_at': instance.savedAt.toIso8601String(),
    };
