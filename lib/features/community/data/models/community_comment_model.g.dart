// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'community_comment_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommunityCommentModel _$CommunityCommentModelFromJson(
        Map<String, dynamic> json) =>
    CommunityCommentModel(
      commentId: CommunityCommentModel._intFromJson(json['comment_id']),
      postCommuId: CommunityCommentModel._intFromJson(json['post_commu_id']),
      userSysId: CommunityCommentModel._intFromJson(json['user_sys_id']),
      commentText: json['comment_text'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      parentId: CommunityCommentModel._nullableIntFromJson(json['parent_id']),
      childrenCount: CommunityCommentModel._intFromJson(json['children_count']),
      displayName: json['display_name'] as String?,
      profilePic: json['profile_pic'] as String?,
      children: (json['children'] as List<dynamic>?)
              ?.map((e) =>
                  CommunityCommentModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$CommunityCommentModelToJson(
        CommunityCommentModel instance) =>
    <String, dynamic>{
      'comment_id': instance.commentId,
      'post_commu_id': instance.postCommuId,
      'user_sys_id': instance.userSysId,
      'comment_text': instance.commentText,
      'created_at': instance.createdAt.toIso8601String(),
      'parent_id': instance.parentId,
      'children_count': instance.childrenCount,
      'display_name': instance.displayName,
      'profile_pic': instance.profilePic,
      'children': instance.children.map((e) => e.toJson()).toList(),
    };
