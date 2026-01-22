// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'role_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RoleModel _$RoleModelFromJson(Map<String, dynamic> json) => RoleModel(
      roleId: RoleModel._roleIdFromJson(json['role_id']),
      roleName: json['role_name'] as String,
      roleType: json['role_type'] as String,
      access: json['access'] as Map<String, dynamic>,
      flagValid: json['flag_valid'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$RoleModelToJson(RoleModel instance) => <String, dynamic>{
      'role_id': instance.roleId,
      'role_name': instance.roleName,
      'role_type': instance.roleType,
      'access': instance.access,
      'flag_valid': instance.flagValid,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
