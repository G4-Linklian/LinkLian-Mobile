import 'package:json_annotation/json_annotation.dart';

part 'community_comment_model.g.dart';

@JsonSerializable(explicitToJson: true)
class CommunityCommentModel {
  @JsonKey(name: 'comment_id', fromJson: _intFromJson)
  final int commentId;

  @JsonKey(name: 'post_commu_id', fromJson: _intFromJson)
  final int postCommuId;

  @JsonKey(name: 'user_sys_id', fromJson: _intFromJson)
  final int userSysId;

  @JsonKey(name: 'comment_text')
  final String commentText;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @JsonKey(name: 'parent_id', fromJson: _nullableIntFromJson)
  final int? parentId;

  @JsonKey(name: 'children_count', fromJson: _intFromJson)
  final int childrenCount;

  @JsonKey(name: 'display_name')
  final String? displayName;

  @JsonKey(name: 'profile_pic')
  final String? profilePic;

  @JsonKey(name: 'children', defaultValue: [])
  final List<CommunityCommentModel> children;

  const CommunityCommentModel({
    required this.commentId,
    required this.postCommuId,
    required this.userSysId,
    required this.commentText,
    required this.createdAt,
    this.parentId,
    required this.childrenCount,
    this.displayName,
    this.profilePic,
    required this.children,
  });

  factory CommunityCommentModel.fromJson(Map<String, dynamic> json) =>
      _$CommunityCommentModelFromJson(json);

  Map<String, dynamic> toJson() => _$CommunityCommentModelToJson(this);

  static int _intFromJson(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static int? _nullableIntFromJson(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }
}
