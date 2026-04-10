import 'package:json_annotation/json_annotation.dart';
import 'community_attachment_model.dart';

part 'community_post_model.g.dart';

@JsonSerializable(explicitToJson: true)
class CommunityPostModel {
  @JsonKey(name: 'post_commu_id', fromJson: _intFromJson)
  final int postId;

  @JsonKey(name: 'user_sys_id', fromJson: _intFromJson)
  final int userId;

  final String content;

  @JsonKey(name: 'created_at', fromJson: _dateFromJson)
  final DateTime createdAt;

  @JsonKey(name: 'first_name')
  final String? firstName;

  @JsonKey(name: 'last_name')
  final String? lastName;

  @JsonKey(name: 'profile_pic')
  final String? profilePic;

  @JsonKey(fromJson: _attachmentsFromJson)
  final List<CommunityAttachmentModel> attachments;

  @JsonKey(name: 'community_id', fromJson: _intFromJson)
  final int communityId;

  const CommunityPostModel({
    required this.postId,
    required this.communityId,
    required this.userId,
    required this.content,
    required this.createdAt,
    this.firstName,
    this.lastName,
    this.profilePic,
    required this.attachments,
  });

  factory CommunityPostModel.fromJson(Map<String, dynamic> json) =>
      _$CommunityPostModelFromJson(json);

  Map<String, dynamic> toJson() => _$CommunityPostModelToJson(this);

  // SAFE CONVERTERS

  static int _intFromJson(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static DateTime _dateFromJson(dynamic value) {
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    if (value is DateTime) return value;
    return DateTime.now();
  }

  static List<CommunityAttachmentModel> _attachmentsFromJson(dynamic value) {
    if (value == null) return [];

    if (value is List) {
      return value
          .whereType<Map<String, dynamic>>()
          .map((e) => CommunityAttachmentModel.fromJson(e))
          .toList();
    }

    return [];
  }
}
