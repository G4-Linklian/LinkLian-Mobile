// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'section_educator_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SectionEducatorModel _$SectionEducatorModelFromJson(
        Map<String, dynamic> json) =>
    SectionEducatorModel(
      userSysId: _intFromJson(json['user_sys_id']),
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      profilePic: json['profile_pic'] as String?,
      position: json['position'] as String?,
    );

Map<String, dynamic> _$SectionEducatorModelToJson(
        SectionEducatorModel instance) =>
    <String, dynamic>{
      'user_sys_id': instance.userSysId,
      'first_name': instance.firstName,
      'last_name': instance.lastName,
      'profile_pic': instance.profilePic,
      'position': instance.position,
    };
