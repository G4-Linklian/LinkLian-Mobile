// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProfileModel _$ProfileModelFromJson(Map<String, dynamic> json) => ProfileModel(
  userId: ProfileModel._intFromJson(json['user_id']),
  email: json['email'] as String,
  displayName: json['display_name'] as String,
  firstName: json['first_name'] as String,
  middleName: json['middle_name'] as String?,
  lastName: json['last_name'] as String,
  phone: json['phone'] as String?,
  avatarUrl: json['avatar_url'] as String?,
  roleName: json['role_name'] as String,
  code: json['code'] as String?,
);

Map<String, dynamic> _$ProfileModelToJson(ProfileModel instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'email': instance.email,
      'display_name': instance.displayName,
      'first_name': instance.firstName,
      'middle_name': instance.middleName,
      'last_name': instance.lastName,
      'phone': instance.phone,
      'avatar_url': instance.avatarUrl,
      'role_name': instance.roleName,
      'code': instance.code,
    };
