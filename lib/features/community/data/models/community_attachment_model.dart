import 'package:json_annotation/json_annotation.dart';

part 'community_attachment_model.g.dart';

@JsonSerializable()
class CommunityAttachmentModel {
  @JsonKey(name: 'url')
  final String fileUrl;

  @JsonKey(name: 'type')
  final String fileType;

  @JsonKey(name: 'original_name')
  final String? originalName;

  const CommunityAttachmentModel({
    required this.fileUrl,
    required this.fileType,
    this.originalName,
  });

  factory CommunityAttachmentModel.fromJson(Map<String, dynamic> json) =>
      _$CommunityAttachmentModelFromJson(json);

  Map<String, dynamic> toJson() => _$CommunityAttachmentModelToJson(this);
}
