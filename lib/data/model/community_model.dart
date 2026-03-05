import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'community_model.g.dart';

@JsonSerializable()
class CommunityModel {
  @JsonKey(name: 'community_id', fromJson: _intFromJson)
  final int communityId;

  @JsonKey(name: 'community_name')
  final String communityName;

  final String? description;

  @JsonKey(name: 'is_private')
  final bool isPrivate;

  @JsonKey(name: 'image_banner')
  final String imageBanner;

  final String status;

  @JsonKey(name: 'member_count', fromJson: _intFromJson)
  final int memberCount;

  @JsonKey(fromJson: _tagsFromJson)
  final List<String> tags;
  
  @JsonKey(name: 'is_owner')
  final bool? isOwner;

  @JsonKey(name: 'membership_status')
  final String membershipStatus;

  @JsonKey(fromJson: _ruleFromJson)
  final List<String> rules;

  @JsonKey(name: 'current_user_id', fromJson: _intFromJson)
  final int? currentUserId;

  @JsonKey(name: 'created_at')
  final String? createdAt;

  @JsonKey(name: 'first_name')
  final String? firstName;

  @JsonKey(name: 'last_name')
  final String? lastName;

  @JsonKey(name: 'profile_pic')
  final String? profilePic;

  const CommunityModel({
    required this.communityId,
    required this.communityName,
    this.description,
    required this.isPrivate,
    required this.imageBanner,
    required this.status,
    required this.memberCount,
    required this.tags,
    this.isOwner,
    required this.membershipStatus,
    required this.rules,
    this.currentUserId,
    this.createdAt,
    this.firstName,
    this.lastName,
    this.profilePic,
  });

  CommunityModel copyWith({
  int? memberCount,
  String? membershipStatus,
  bool? isOwner,
  String? status,
}) {
  return CommunityModel(
    communityId: communityId,
    communityName: communityName,
    description: description,
    isPrivate: isPrivate,
    imageBanner: imageBanner,
    status: status ?? this.status,
    memberCount: memberCount ?? this.memberCount,
    tags: tags,
    isOwner: isOwner ?? this.isOwner,
    membershipStatus: membershipStatus ?? this.membershipStatus,
    rules: rules,
    currentUserId: currentUserId,
  );
}
  bool get isMember => membershipStatus == 'active';
  bool get isPending => membershipStatus == 'pending';
  bool get isNone => membershipStatus == 'none';

  factory CommunityModel.fromJson(Map<String, dynamic> json) =>
      _$CommunityModelFromJson(json);

  Map<String, dynamic> toJson() => _$CommunityModelToJson(this);

  static int _intFromJson(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

 static List<String> _ruleFromJson(dynamic value) {
  if (value == null) return [];

  if (value is List) {
    return value.map((e) => e.toString()).toList();
  }

  if (value is String) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
    } catch (_) {}
  }

  return [];
}

  static List<String> _tagsFromJson(dynamic value) {
    if (value == null) return [];

    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }

    if (value is String) {
      return value
          .replaceAll('{', '')
          .replaceAll('}', '')
          .split(',')
          .where((e) => e.isNotEmpty)
          .toList();
    }

    return [];
  }

  bool get isInactive => status == 'inactive';

  bool get canInteract {
    if (isInactive) return false;

    if (isPrivate && !isMember) return false;

    return true;
  }

  bool get canViewContent {
    if (isInactive && isPrivate && !isMember) {
      return false;
    }

    if (isPrivate && !isMember) {
      return false;
    }

    return true;
  }
}
