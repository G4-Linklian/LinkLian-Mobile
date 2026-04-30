import 'package:json_annotation/json_annotation.dart';

part 'comment_model.g.dart';

@JsonSerializable(explicitToJson: true)
class CommentModel {
  @JsonKey(name: 'comment_id', fromJson: _intFromJson)
  final int commentId;

  @JsonKey(name: 'post_id', fromJson: _intFromJson)
  final int postId;

  @JsonKey(name: 'user_sys_id', fromJson: _nullableIntFromJson)
  final int? userSysId;

  @JsonKey(name: 'is_anonymous')
  final bool isAnonymous;

  @JsonKey(name: 'display_name')
  final String? displayName;

  @JsonKey(name: 'profile_pic')
  final String? profilePic;

  @JsonKey(name: 'comment_text')
  final String commentText;

  @JsonKey(name: 'flag_valid')
  final bool flagValid;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  @JsonKey(name: 'parent_id', fromJson: _nullableIntFromJson)
  final int? parentId;

  @JsonKey(name: 'children_count', fromJson: _intFromJson, defaultValue: 0)
  final int childrenCount;

  @JsonKey(name: 'children', defaultValue: <CommentModel>[])
  final List<CommentModel> children;

  const CommentModel({
    required this.commentId,
    required this.postId,
    this.userSysId,
    required this.isAnonymous,
    required this.commentText,
    required this.flagValid,
    required this.createdAt,
    required this.updatedAt,
    required this.parentId,
    required this.childrenCount,
    required this.children,
    this.displayName,
    this.profilePic,
  });

  bool get hasReplies => children.isNotEmpty;
  bool get isReply => parentId != null;
  bool get isUserDeleted => userSysId == null && !isAnonymous;
  String get effectiveDisplayName {
    if (isUserDeleted) return 'ไม่มีบัญชีผู้ใช้งาน';
    if (displayName != null && displayName!.trim().isNotEmpty) {
      return displayName!.trim();
    }
    return isAnonymous ? 'นิรนาม' : 'ผู้ใช้';
  }

  List<CommentModel> flattenAllChildren() {
    final result = <CommentModel>[this];

    for (final child in children) {
      result.add(child);
      result.addAll(child.flattenAllChildren().skip(1));
    }

    return result;
  }

  static int _intFromJson(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }

  static int? _nullableIntFromJson(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    final childrenJson = json['children'] as List? ?? [];
    final childrenList = childrenJson
        .map((e) => CommentModel.fromJson(e as Map<String, dynamic>))
        .toList();

    final actualChildrenCount = childrenList.isNotEmpty
        ? childrenList.length
        : _parseChildrenCount(json['children_count']);

    return CommentModel(
      commentId: _parseInt(json['comment_id']),
      postId: _parseInt(json['post_id']),
      userSysId: _nullableIntFromJson(json['user_sys_id']),
      isAnonymous: json['is_anonymous'] as bool? ?? false,
      commentText: json['comment_text'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      flagValid: json['flag_valid'] as bool? ?? true,
      parentId: _nullableIntFromJson(json['parent_id']),
      childrenCount: actualChildrenCount,
      displayName: json['display_name'] as String?,
      profilePic: json['profile_pic'] as String?,
      children: childrenList,
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static int _parseChildrenCount(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'comment_id': commentId,
      'post_id': postId,
      'user_sys_id': userSysId,
      'is_anonymous': isAnonymous,
      'comment_text': commentText,
      'created_at': createdAt.toLocal().toIso8601String(),
      'updated_at': updatedAt.toLocal().toIso8601String(),
      'flag_valid': flagValid,
      'parent_id': parentId,
      'children_count': childrenCount,
      'display_name': displayName,
      'profile_pic': profilePic,
      'children': children.map((c) => c.toJson()).toList(),
    };
  }
}
