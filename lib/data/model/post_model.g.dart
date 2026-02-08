// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PostModel _$PostModelFromJson(Map<String, dynamic> json) => PostModel(
      postId: PostModel._intFromJson(json['post_id']),
      postContentId: PostModel._intFromJson(json['post_content_id']),
      title: json['title'] as String,
      content: json['content'] as String,
      postType: PostModel._stringFromJson(json['post_type']),
      isAnonymous: json['is_anonymous'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      userSysId: PostModel._intFromJson(json['user_sys_id']),
      displayName: json['display_name'] as String?,
      email: json['email'] as String?,
      roleName: json['role_name'] as String?,
      profilePic: json['profile_pic'] as String?,
      attachments: (json['attachments'] as List<dynamic>?)
          ?.map((e) => PostAttachmentModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      dueDate: json['dueDate'] == null
          ? null
          : DateTime.parse(json['dueDate'] as String),
      maxScore: (json['maxScore'] as num?)?.toInt(),
      isGroup: json['isGroup'] as bool?,
    );

Map<String, dynamic> _$PostModelToJson(PostModel instance) => <String, dynamic>{
      'post_id': instance.postId,
      'post_content_id': instance.postContentId,
      'title': instance.title,
      'content': instance.content,
      'post_type': instance.postType,
      'is_anonymous': instance.isAnonymous,
      'created_at': instance.createdAt.toIso8601String(),
      'user_sys_id': instance.userSysId,
      'display_name': instance.displayName,
      'email': instance.email,
      'profile_pic': instance.profilePic,
      'role_name': instance.roleName,
      'attachments': instance.attachments,
      'dueDate': instance.dueDate?.toIso8601String(),
      'maxScore': instance.maxScore,
      'isGroup': instance.isGroup,
    };

PostAttachmentModel _$PostAttachmentModelFromJson(Map<String, dynamic> json) =>
    PostAttachmentModel(
      fileUrl: json['file_url'] as String,
      fileType: json['file_type'] as String,
      originalName: json['original_name'] as String?,
      fileName: json['file_name'] as String?,
      fileBlobName: json['file_blob_name'] as String?,
      fileSize: (json['file_size'] as num?)?.toInt(),
    );

Map<String, dynamic> _$PostAttachmentModelToJson(
        PostAttachmentModel instance) =>
    <String, dynamic>{
      'file_url': instance.fileUrl,
      'file_type': instance.fileType,
      'original_name': instance.originalName,
      'file_name': instance.fileName,
      'file_blob_name': instance.fileBlobName,
      'file_size': instance.fileSize,
    };
