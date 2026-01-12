import 'package:json_annotation/json_annotation.dart';

part 'profile_model.g.dart';

@JsonSerializable()
class ProfileModel {
  @JsonKey(name: 'user_id', fromJson: _intFromJson)
  final int userId;

  final String email;

  @JsonKey(name: 'display_name')
  final String displayName;

  @JsonKey(name: 'first_name')
  final String firstName;

  @JsonKey(name: 'middle_name')
  final String? middleName;

  @JsonKey(name: 'last_name')
  final String lastName;

  final String? phone;

  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;

  @JsonKey(name: 'role_name')
  final String roleName;

  final String? code;

  ProfileModel({
    required this.userId,
    required this.email,
    required this.displayName,
    required this.firstName,
    this.middleName,
    required this.lastName,
    this.phone,
    this.avatarUrl,
    required this.roleName,
    this.code,
  });

  static int _intFromJson(dynamic v) =>
      v is int ? v : int.parse(v.toString());

  factory ProfileModel.fromJson(Map<String, dynamic> json) =>
      _$ProfileModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProfileModelToJson(this);

  ProfileModel? copyWith({required String avatarUrl}) {}
}
