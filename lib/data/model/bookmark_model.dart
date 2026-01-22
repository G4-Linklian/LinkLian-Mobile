import 'package:json_annotation/json_annotation.dart';

part 'bookmark_model.g.dart';

int _intFromJson(dynamic value) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

@JsonSerializable()
class BookmarkModel {
  /// Post ID
  @JsonKey(name: 'post_id', fromJson: _intFromJson)
  final int postId;

  /// Post Content ID 
  @JsonKey(name: 'post_content_id', fromJson: _intFromJson)
  final int postContentId;

  /// Post title
  final String title;

  /// Post content
  final String content;

  /// Post type (announcement, assignment, question)
  @JsonKey(name: 'post_type')
  final String? postType;

  /// Section/Class name
  @JsonKey(name: 'section_name')
  final String? sectionName;

  /// Subject name (วิชา)
  @JsonKey(name: 'subject_name')
  final String? subjectName;

  /// Creator name (ชื่อผู้สร้าง)
  @JsonKey(name: 'creator_name')
  final String? creatorName;

  /// Creator ID (ดัชนีผู้สร้าง)
  @JsonKey(name: 'creator_id', fromJson: _intFromJson)
  final int? creatorId;

  /// Bookmark saved date
  @JsonKey(name: 'saved_at')
  final DateTime savedAt;

  /// Flag valid
  @JsonKey(name: 'flag_valid')
  final bool flagValid;

  BookmarkModel({
    required this.postId,
    required this.postContentId,
    required this.title,
    required this.content,
    this.postType,
    this.sectionName,
    this.subjectName,
    this.creatorName,
    this.creatorId,
    required this.savedAt,
    this.flagValid = true,
  });

  factory BookmarkModel.fromJson(Map<String, dynamic> json) =>
      _$BookmarkModelFromJson(json);

  Map<String, dynamic> toJson() => _$BookmarkModelToJson(this);

  ///  Copy with method สำหรับการอัปเดต
  BookmarkModel copyWith({
    int? postId,
    int? postContentId,
    String? title,
    String? content,
    String? postType,
    String? sectionName,
    String? subjectName,
    String? creatorName,
    int? creatorId,
    DateTime? savedAt,
    bool? flagValid,
  }) {
    return BookmarkModel(
      postId: postId ?? this.postId,
      postContentId: postContentId ?? this.postContentId,
      title: title ?? this.title,
      content: content ?? this.content,
      postType: postType ?? this.postType,
      sectionName: sectionName ?? this.sectionName,
      subjectName: subjectName ?? this.subjectName,
      creatorName: creatorName ?? this.creatorName,
      creatorId: creatorId ?? this.creatorId,
      savedAt: savedAt ?? this.savedAt,
      flagValid: flagValid ?? this.flagValid,
    );
  }

  /// ตรวจสอบว่าข้อมูลครบถ้วนหรือไม่
  bool get isValid => postId > 0 && postContentId > 0 && title.isNotEmpty;

  @override
  String toString() =>
      'BookmarkModel(postId: $postId, title: $title, creatorName: $creatorName)';
}