import 'package:json_annotation/json_annotation.dart';

part 'community_tag_model.g.dart';

@JsonSerializable()
class CommunityTagModel {
  @JsonKey(name: 'community_tag_id')
  final int? tagId;

  @JsonKey(name: 'tag_name')
  final String tagName;

  const CommunityTagModel({this.tagId, required this.tagName});

  factory CommunityTagModel.fromJson(Map<String, dynamic> json) =>
      _$CommunityTagModelFromJson(json);

  Map<String, dynamic> toJson() => _$CommunityTagModelToJson(this);
}
