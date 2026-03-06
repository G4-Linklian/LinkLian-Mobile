// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'community_attachment_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommunityAttachmentModel _$CommunityAttachmentModelFromJson(
        Map<String, dynamic> json) =>
    CommunityAttachmentModel(
      fileUrl: json['url'] as String,
      fileType: json['type'] as String,
      originalName: json['original_name'] as String?,
    );

Map<String, dynamic> _$CommunityAttachmentModelToJson(
        CommunityAttachmentModel instance) =>
    <String, dynamic>{
      'url': instance.fileUrl,
      'type': instance.fileType,
      'original_name': instance.originalName,
    };
