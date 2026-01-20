import 'package:json_annotation/json_annotation.dart';

part 'comment_model.g.dart';

@JsonSerializable(explicitToJson: true)
class CommentModel {
  @JsonKey(name: 'comment_id', fromJson: _intFromJson)
  final int commentId;

  @JsonKey(name: 'post_id', fromJson: _intFromJson)
  final int postId;

  @JsonKey(name: 'user_sys_id', fromJson: _intFromJson)
  final int userSysId;

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

  @JsonKey(
    name: 'children_count',
    fromJson: _intFromJson,
    defaultValue: 0,
  )
  final int childrenCount;

  @JsonKey(
    name: 'children',
    defaultValue: <CommentModel>[],
  )
  final List<CommentModel> children;

  const CommentModel({
    required this.commentId,
    required this.postId,
    required this.userSysId,
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

  //  FLATTEN ALL NESTED COMMENTS (recursive)
  List<CommentModel> flattenAllChildren() {
    final result = <CommentModel>[this];
    
    for (final child in children) {
      result.add(child);

      result.addAll(child.flattenAllChildren().skip(1));
    }
    
    return result;
  }

  // helper
  
  static int _intFromJson(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.parse(v.toString());
  }

  static int? _nullableIntFromJson(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.parse(v.toString());
  }

  factory CommentModel.fromJson(Map<String, dynamic> json) =>
      _$CommentModelFromJson(json);

  Map<String, dynamic> toJson() => _$CommentModelToJson(this);
}