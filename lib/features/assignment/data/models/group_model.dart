import 'package:json_annotation/json_annotation.dart';

part 'group_model.g.dart';

int? _intFromJson(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  return null;
}

String _stringFromJson(dynamic value) {
  if (value == null) return '';
  return value.toString();
}

@JsonSerializable()
class GroupModel {
  @JsonKey(name: 'group_id', fromJson: _intFromJson)
  final int? groupId;

  @JsonKey(name: 'group_name')
  final String groupName;

  final List<GroupMemberModel> members;

  const GroupModel({
    this.groupId,
    required this.groupName,
    required this.members,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) =>
      _$GroupModelFromJson(json);

  Map<String, dynamic> toJson() => _$GroupModelToJson(this);
}

@JsonSerializable()
class GroupMemberModel {
  @JsonKey(name: 'user_sys_id', fromJson: _intFromJson)
  final int? userSysId;

  @JsonKey(name: 'first_name', fromJson: _stringFromJson)
  final String firstName;

  @JsonKey(name: 'last_name', fromJson: _stringFromJson)
  final String lastName;

  @JsonKey(name: 'profile_pic')
  final String? profilePic;

  const GroupMemberModel({
    this.userSysId,
    required this.firstName,
    required this.lastName,
    this.profilePic,
  });

  factory GroupMemberModel.fromJson(Map<String, dynamic> json) =>
      _$GroupMemberModelFromJson(json);

  Map<String, dynamic> toJson() => _$GroupMemberModelToJson(this);

  bool get isUserDeleted => userSysId == null;

  String get fullName => '$firstName $lastName'.trim();

  String get displayName =>
      isUserDeleted ? 'ไม่มีบัญชีผู้ใช้งาน' : fullName;
}
