import 'package:json_annotation/json_annotation.dart';

part 'community_member_model.g.dart';

@JsonSerializable()
class CommunityMemberModel {
  @JsonKey(name: 'user_sys_id', fromJson: _intFromJson)
  final int userSysId;

  @JsonKey(name: 'first_name')
  final String firstName;

  @JsonKey(name: 'last_name')
  final String lastName;

  @JsonKey(name: 'profile_pic')
  final String? profilePic;

  @JsonKey(name: 'status')
  final String? status;

  bool get isApproved => status == 'active';

  const CommunityMemberModel({
    required this.userSysId,
    required this.firstName,
    required this.lastName,
    this.profilePic,
    this.status,
  });

  factory CommunityMemberModel.fromJson(Map<String, dynamic> json) =>
      _$CommunityMemberModelFromJson(json);

  Map<String, dynamic> toJson() => _$CommunityMemberModelToJson(this);

  static int _intFromJson(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
