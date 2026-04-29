// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'community_post_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommunityPostModel _$CommunityPostModelFromJson(Map<String, dynamic> json) =>
    CommunityPostModel(
      postId: CommunityPostModel._intFromJson(json['post_commu_id']),
      communityId: CommunityPostModel._intFromJson(json['community_id']),
      userId: CommunityPostModel._intFromJson(json['user_sys_id']),
      content: json['content'] as String,
      createdAt: CommunityPostModel._dateFromJson(json['created_at']),
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      profilePic: json['profile_pic'] as String?,
      attachments: CommunityPostModel._attachmentsFromJson(json['attachments']),
    );

Map<String, dynamic> _$CommunityPostModelToJson(CommunityPostModel instance) =>
    <String, dynamic>{
      'post_commu_id': instance.postId,
      'user_sys_id': instance.userId,
      'content': instance.content,
      'created_at': instance.createdAt.toIso8601String(),
      'first_name': instance.firstName,
      'last_name': instance.lastName,
      'profile_pic': instance.profilePic,
      'attachments': instance.attachments.map((e) => e.toJson()).toList(),
      'community_id': instance.communityId,
    };
