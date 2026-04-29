// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'community_tag_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommunityTagModel _$CommunityTagModelFromJson(Map<String, dynamic> json) =>
    CommunityTagModel(
      tagId: (json['community_tag_id'] as num?)?.toInt(),
      tagName: json['tag_name'] as String,
    );

Map<String, dynamic> _$CommunityTagModelToJson(CommunityTagModel instance) =>
    <String, dynamic>{
      'community_tag_id': instance.tagId,
      'tag_name': instance.tagName,
    };
