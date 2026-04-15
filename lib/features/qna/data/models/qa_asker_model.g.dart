// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'qa_asker_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QaAsker _$QaAskerFromJson(Map<String, dynamic> json) => QaAsker(
      userId: _intFromJson(json['user_id']),
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      profilePic: json['profile_pic'] as String?,
      isAnonymous: json['is_anonymous'] == null
          ? false
          : _boolFromJson(json['is_anonymous']),
    );

Map<String, dynamic> _$QaAskerToJson(QaAsker instance) => <String, dynamic>{
      'user_id': instance.userId,
      'first_name': instance.firstName,
      'last_name': instance.lastName,
      'profile_pic': instance.profilePic,
      'is_anonymous': instance.isAnonymous,
    };
