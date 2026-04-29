// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'community_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommunityModel _$CommunityModelFromJson(Map<String, dynamic> json) =>
    CommunityModel(
      communityId: CommunityModel._intFromJson(json['community_id']),
      communityName: json['community_name'] as String,
      description: json['description'] as String?,
      isPrivate: json['is_private'] as bool,
      imageBanner: json['image_banner'] as String,
      status: json['status'] as String,
      memberCount: CommunityModel._intFromJson(json['member_count']),
      tags: CommunityModel._tagsFromJson(json['tags']),
      isOwner: json['is_owner'] as bool?,
      membershipStatus: json['membership_status'] as String,
      rules: CommunityModel._ruleFromJson(json['rules']),
      currentUserId: CommunityModel._intFromJson(json['current_user_id']),
      createdAt: json['created_at'] as String?,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      profilePic: json['profile_pic'] as String?,
    );

Map<String, dynamic> _$CommunityModelToJson(CommunityModel instance) =>
    <String, dynamic>{
      'community_id': instance.communityId,
      'community_name': instance.communityName,
      'description': instance.description,
      'is_private': instance.isPrivate,
      'image_banner': instance.imageBanner,
      'status': instance.status,
      'member_count': instance.memberCount,
      'tags': instance.tags,
      'is_owner': instance.isOwner,
      'membership_status': instance.membershipStatus,
      'rules': instance.rules,
      'current_user_id': instance.currentUserId,
      'created_at': instance.createdAt,
      'first_name': instance.firstName,
      'last_name': instance.lastName,
      'profile_pic': instance.profilePic,
    };
