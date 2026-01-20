import 'package:json_annotation/json_annotation.dart';

part 'bookmark_model.g.dart';

int _intFromJson(dynamic value) => int.parse(value.toString());

@JsonSerializable()
class BookmarkModel {
  @JsonKey(name: 'post_id', fromJson: _intFromJson)
  final int postId;

  final String title;
  final String content;

  @JsonKey(name: 'section_name')
  final String? sectionName;      

  @JsonKey(name: 'subject_name')
  final String? subjectName;      

  @JsonKey(name: 'educator_name')
  final String? educatorName;    

  @JsonKey(name: 'saved_at')
  final DateTime savedAt;

  BookmarkModel({
    required this.postId,
    required this.title,
    required this.content,
    this.sectionName,
    this.subjectName,
    this.educatorName,
    required this.savedAt,
  });

  factory BookmarkModel.fromJson(Map<String, dynamic> json) =>
      _$BookmarkModelFromJson(json);

  Map<String, dynamic> toJson() => _$BookmarkModelToJson(this);
}
