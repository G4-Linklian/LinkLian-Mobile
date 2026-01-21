// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommentModel _$CommentModelFromJson(Map<String, dynamic> json) => CommentModel(
      commentId: CommentModel._intFromJson(json['comment_id']),
      postId: CommentModel._intFromJson(json['post_id']),
      userSysId: CommentModel._intFromJson(json['user_sys_id']),
      isAnonymous: json['is_anonymous'] as bool,
      commentText: json['comment_text'] as String,
      flagValid: json['flag_valid'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      parentId: CommentModel._nullableIntFromJson(json['parent_id']),
      childrenCount: json['children_count'] == null
          ? 0
          : CommentModel._intFromJson(json['children_count']),
      children: (json['children'] as List<dynamic>?)
              ?.map((e) => CommentModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      displayName: json['display_name'] as String?,
      profilePic: json['profile_pic'] as String?,
    );

Map<String, dynamic> _$CommentModelToJson(CommentModel instance) =>
    <String, dynamic>{
      'comment_id': instance.commentId,
      'post_id': instance.postId,
      'user_sys_id': instance.userSysId,
      'is_anonymous': instance.isAnonymous,
      'display_name': instance.displayName,
      'profile_pic': instance.profilePic,
      'comment_text': instance.commentText,
      'flag_valid': instance.flagValid,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'parent_id': instance.parentId,
      'children_count': instance.childrenCount,
      'children': instance.children.map((e) => e.toJson()).toList(),
    };
