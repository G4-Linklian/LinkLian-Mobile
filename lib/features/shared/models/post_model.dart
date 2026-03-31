import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';

part 'post_model.g.dart';

@JsonSerializable()
class PostModel {
  @JsonKey(name: 'post_id', fromJson: _intFromJson)
  final int postId;

  @JsonKey(name: 'post_content_id', fromJson: _intFromJson)
  final int postContentId;

  final String title;
  final String content;

  @JsonKey(name: 'post_type', fromJson: _stringFromJson)
  final String postType;

  @JsonKey(name: 'is_anonymous')
  final bool isAnonymous;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @JsonKey(name: 'user_sys_id', fromJson: _intFromJson)
  final int? userSysId;

  @JsonKey(name: 'display_name')
  final String? displayName;

  final String? email;

  @JsonKey(name: 'profile_pic')
  final String? profilePic;

  @JsonKey(name: 'role_name')
  final String? roleName;

  @JsonKey(name: 'section_id')
  final int? sectionId;

  final List<PostAttachmentModel>? attachments;
  final DateTime? dueDate;
  final double? maxScore;
  final bool? isGroup;

  const PostModel({
    required this.postId,
    required this.postContentId,
    required this.title,
    required this.content,
    required this.postType,
    required this.isAnonymous,
    required this.createdAt,
    this.userSysId,
    this.displayName,
    this.email,
    this.roleName,
    this.profilePic,
    this.attachments,
    this.dueDate,
    this.maxScore,
    this.isGroup,
    this.sectionId,
  });

  /// true เมื่อ user ที่โพสต์ถูกลบออกจากระบบแล้ว (user_sys_id = null และไม่ใช่โพสต์익名)
  bool get isUserDeleted => userSysId == null && !isAnonymous;

  static int _intFromJson(dynamic v) {
    if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  static String _stringFromJson(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is int) return value.toString();
    return '';
  }

  factory PostModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    return PostModel(
      postId: _parseInt(json['post_id']),
      postContentId: _parseInt(json['post_content_id']),
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      postType: _stringFromJson(json['post_type']),
      isAnonymous: _parseBool(json['is_anonymous']),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      userSysId: user != null
          ? _parseIntNullable(user['user_sys_id'])
          : _parseIntNullable(json['user_sys_id']),
      displayName: user?['display_name'] ?? json['display_name'],
      email: user?['email'] ?? json['email'],
      profilePic: user?['profile_pic'] ?? json['profile_pic'],
      roleName: user?['role_name'] ?? json['role_name'],
      attachments: _parseAttachments(json['attachments']),
      dueDate: json['due_date'] != null
          ? DateTime.tryParse(json['due_date'].toString())
          : null,
      maxScore: json['max_score'] != null
          ? (json['max_score'] is double
              ? json['max_score']
              : double.tryParse(json['max_score'].toString()))
          : null,
      isGroup: _parseBoolNullable(json['is_group']),
      sectionId: _parseIntNullable(json['section_id']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static int? _parseIntNullable(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static bool _parseBool(dynamic value, {bool fallback = false}) {
    if (value == null) return fallback;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1') return true;
      if (normalized == 'false' || normalized == '0') return false;
    }
    return fallback;
  }

  static bool? _parseBoolNullable(dynamic value) {
    if (value == null) return null;
    return _parseBool(value);
  }

  static List<PostAttachmentModel>? _parseAttachments(dynamic attachments) {
    if (attachments == null) return null;
    dynamic normalized = attachments;
    if (normalized is String) {
      try {
        normalized = jsonDecode(normalized);
      } catch (_) {
        return null;
      }
    }
    if (normalized is Map<String, dynamic>) {
      normalized = [normalized];
    }
    if (normalized is! List) return null;
    if (normalized.isEmpty) return [];
    return normalized
        .where((a) => a != null && a is Map<String, dynamic>)
        .map((a) => PostAttachmentModel.fromJson(a as Map<String, dynamic>))
        .toList();
  }

  Map<String, dynamic> toJson() => _$PostModelToJson(this);

  PostModel copyWith({
    String? title,
    String? content,
    String? postType,
    List<PostAttachmentModel>? attachments,
    DateTime? dueDate,
    double? maxScore,
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
      dueDate: dueDate ?? this.dueDate,
      maxScore: maxScore ?? this.maxScore,
    );
  }
}

@JsonSerializable()
class PostAttachmentModel {
  @JsonKey(name: 'file_url')
  final String fileUrl;

  @JsonKey(name: 'file_type')
  final String fileType;

  @JsonKey(name: 'original_name')
  final String? originalName;

  @JsonKey(name: 'file_name')
  final String? fileName;

  @JsonKey(name: 'file_blob_name')
  final String? fileBlobName;

  @JsonKey(name: 'file_size')
  final int? fileSize;

  const PostAttachmentModel({
    required this.fileUrl,
    required this.fileType,
    this.originalName,
    this.fileName,
    this.fileBlobName,
    this.fileSize,
  });

  factory PostAttachmentModel.fromJson(Map<String, dynamic> json) =>
      _$PostAttachmentModelFromJson(json);

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'file_url': fileUrl, 'file_type': fileType};
    if (originalName != null) map['original_name'] = originalName;
    return map;
  }
}
