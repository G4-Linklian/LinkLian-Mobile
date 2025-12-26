import 'package:json_annotation/json_annotation.dart';

part 'role_model.g.dart';

@JsonSerializable()
class RoleModel {
  @JsonKey(
    name: 'role_id',
    fromJson: _roleIdFromJson,
  )
  final int roleId;

  @JsonKey(name: 'role_name')
  final String roleName;

  @JsonKey(name: 'role_type')
  final String roleType;

  final Map<String, dynamic> access;

  @JsonKey(name: 'flag_valid')
  final bool flagValid;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const RoleModel({
    required this.roleId,
    required this.roleName,
    required this.roleType,
    required this.access,
    required this.flagValid,
    required this.createdAt,
    required this.updatedAt,
  });

  static int _roleIdFromJson(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.parse(value);
    throw Exception('Invalid role_id type: $value');
  }

  factory RoleModel.fromJson(Map<String, dynamic> json) =>
      _$RoleModelFromJson(json);

  Map<String, dynamic> toJson() => _$RoleModelToJson(this);

  @override
  String toString() {
    return 'RoleModel(roleId: $roleId, roleName: $roleName)';
  }
}
