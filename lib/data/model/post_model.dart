import 'package:json_annotation/json_annotation.dart';

part 'post_model.g.dart';

@JsonSerializable()
class PostModel {
  @JsonKey(name: 'post_id', fromJson: _intFromJson)
  final int postId;

  @JsonKey(name: 'post_content_id', fromJson: _intFromJson)
  final int postContentId;

  final String title;
  final String content;

  @JsonKey(
    name: 'post_type',
    fromJson: _stringFromJson,
  )
  final String postType;

  @JsonKey(name: 'is_anonymous')
  final bool isAnonymous;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  // ===== user info =====
  @JsonKey(name: 'user_sys_id', fromJson: _intFromJson)
  final int userSysId;

  @JsonKey(name: 'display_name')
  final String? displayName;

  final String? email;

  @JsonKey(name: 'profile_pic')
  final String? profilePic;

  @JsonKey(name: 'role_name')
  final String? roleName;

  final List<PostAttachmentModel>? attachments;

  const PostModel({
    required this.postId,
    required this.postContentId,
    required this.title,
    required this.content,
    required this.postType,
    required this.isAnonymous,
    required this.createdAt,
    required this.userSysId,
    this.displayName,
    this.email,
    this.profilePic,
    this.roleName,
    this.attachments,
  });

  // ===== Json helpers =====
  static int _intFromJson(dynamic v) {
    if (v is int) return v;
    if (v is String) return int.parse(v);
    throw Exception('Invalid int value: $v');
  }

  static String _stringFromJson(dynamic value) {
    if (value is String) return value;
    if (value is int) return value.toString();
    throw Exception('Invalid post_type: $value');
  }

  factory PostModel.fromJson(Map<String, dynamic> json) =>
      _$PostModelFromJson(json);

  Map<String, dynamic> toJson() => _$PostModelToJson(this);

  PostModel copyWith({
    String? title,
    String? content,
    String? postType,
    List<PostAttachmentModel>? attachments,
  }) {
    return PostModel(
      postId: postId,
      postContentId: postContentId,
      title: title ?? this.title,
      content: content ?? this.content,
      postType: postType ?? this.postType,
      isAnonymous: isAnonymous,
      createdAt: createdAt,
      userSysId: userSysId,
      displayName: displayName,
      email: email,
      profilePic: profilePic,
      roleName: roleName,
      attachments: attachments ?? this.attachments,
    );
  }
}

@JsonSerializable()
class PostAttachmentModel {
  @JsonKey(name: 'file_url')
  final String fileUrl;

  @JsonKey(name: 'file_type')
  final String fileType;

  @JsonKey(name: 'file_name')
  final String? fileName;

  @JsonKey(name: 'file_blob_name')
  final String? fileBlobName;

  @JsonKey(name: 'file_size')
  final int? fileSize;

  const PostAttachmentModel({
    required this.fileUrl,
    required this.fileType,
    this.fileName,
    this.fileBlobName,
    this.fileSize,
  });

  factory PostAttachmentModel.fromJson(Map<String, dynamic> json) =>
      _$PostAttachmentModelFromJson(json);

  Map<String, dynamic> toJson() => _$PostAttachmentModelToJson(this);
}