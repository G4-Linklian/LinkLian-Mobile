import 'package:json_annotation/json_annotation.dart';

part 'section_educator_model.g.dart';

int _intFromJson(dynamic value) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

@JsonSerializable()
class SectionEducatorModel {
  @JsonKey(name: 'user_sys_id', fromJson: _intFromJson)
  final int userSysId;

  @JsonKey(name: 'first_name')
  final String? firstName;

  @JsonKey(name: 'last_name')
  final String? lastName;

  @JsonKey(name: 'display_name')
  final String? rawDisplayName;

  @JsonKey(name: 'profile_pic')
  final String? profilePic;

  @JsonKey(name: 'position')
  final String? position;

  @JsonKey(name: 'is_main_teacher', defaultValue: false)
  final bool isMainTeacherFlag;

  const SectionEducatorModel({
    required this.userSysId,
    this.firstName,
    this.lastName,
    this.rawDisplayName,
    this.profilePic,
    this.position,
    this.isMainTeacherFlag = false,
  });

  String get fullName {
    final first = firstName ?? '';
    final last = lastName ?? '';
    final combinedName = '$first $last'.trim();
    if (combinedName.isNotEmpty) return combinedName;
    return rawDisplayName?.trim() ?? '';
  }

  String get displayName => fullName;

  bool get isMainTeacher {
    if (isMainTeacherFlag) return true;
    final pos = position?.toLowerCase() ?? '';
    return pos.contains('teacher') || pos.contains('instructor') || pos.contains('main');
  }

  factory SectionEducatorModel.fromJson(Map<String, dynamic> json) =>
      _$SectionEducatorModelFromJson(json);

  Map<String, dynamic> toJson() => _$SectionEducatorModelToJson(this);

  @override
  String toString() {
    return 'SectionEducatorModel(userSysId: $userSysId, name: $fullName)';
  }
}
