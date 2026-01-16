// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProfileModel _$ProfileModelFromJson(Map<String, dynamic> json) => ProfileModel(
  userSysId: _intFromJson(json['user_sys_id']),
  email: json['email'] as String,
  firstName: json['first_name'] as String,
  middleName: json['middle_name'] as String?,
  lastName: json['last_name'] as String,
  phone: json['phone'] as String?,
  roleName: json['role_name'] as String,
  roleGroup: json['role_group'] as String?,
  profilePic: json['profile_pic'] as String?,
  education: json['education'] == null
      ? null
      : EducationModel.fromJson(json['education'] as Map<String, dynamic>),
  teachingSchedule: (json['teaching_schedule'] as List<dynamic>?)
      ?.map((e) => TeachingScheduleModel.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$ProfileModelToJson(ProfileModel instance) =>
    <String, dynamic>{
      'user_sys_id': _intToJson(instance.userSysId),
      'email': instance.email,
      'first_name': instance.firstName,
      'middle_name': instance.middleName,
      'last_name': instance.lastName,
      'phone': instance.phone,
      'role_name': instance.roleName,
      'role_group': instance.roleGroup,
      'profile_pic': instance.profilePic,
      'education': instance.education,
      'teaching_schedule': instance.teachingSchedule,
    };
