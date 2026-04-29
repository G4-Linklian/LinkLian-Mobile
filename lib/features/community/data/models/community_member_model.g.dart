// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'community_member_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommunityMemberModel _$CommunityMemberModelFromJson(
        Map<String, dynamic> json) =>
    CommunityMemberModel(
      userSysId: CommunityMemberModel._intFromJson(json['user_sys_id']),
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      profilePic: json['profile_pic'] as String?,
      status: json['status'] as String?,
    );

Map<String, dynamic> _$CommunityMemberModelToJson(
        CommunityMemberModel instance) =>
    <String, dynamic>{
      'user_sys_id': instance.userSysId,
      'first_name': instance.firstName,
      'last_name': instance.lastName,
      'profile_pic': instance.profilePic,
      'status': instance.status,
    };
