import 'package:json_annotation/json_annotation.dart';
import 'education_model.dart';

part 'profile_model.g.dart';

int _intFromJson(dynamic value) => int.parse(value.toString());
String _intToJson(int value) => value.toString();

@JsonSerializable()
class ProfileModel {
  @JsonKey(name: 'user_sys_id', fromJson: _intFromJson, toJson: _intToJson)
  final int userSysId;

  final String email;
  @JsonKey(name: 'code')
  final String? code;

  @JsonKey(name: 'first_name')
  final String firstName;

  @JsonKey(name: 'middle_name')
  final String? middleName;

  @JsonKey(name: 'last_name')
  final String lastName;

  final String? phone;

  @JsonKey(name: 'role_name')
  final String roleName;

  @JsonKey(name: 'role_group')
  final String? roleGroup;

  @JsonKey(name: 'profile_pic')
  final String? profilePic;

  @JsonKey(name: 'education')
  final EducationModel? education;

  // @JsonKey(name: 'teaching_schedule')
  // final List<TeachingScheduleModel>? teachingSchedule;

  ProfileModel({
    this.code,
    required this.userSysId,
    required this.email,
    required this.firstName,
    this.middleName,
    required this.lastName,
    this.phone,
    required this.roleName,
    this.roleGroup,
    this.profilePic,
    this.education,
    // this.teachingSchedule,
  });

  ProfileModel copyWith({
    String? firstName,
    String? middleName,
    String? lastName,
    String? phone,
    String? profilePic,
    bool clearProfilePic = false,
    EducationModel? education,
    String? code,
    // List<TeachingScheduleModel>? teachingSchedule,
  }) {
    final profile = ProfileModel(
      userSysId: userSysId,
      email: email,
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      lastName: lastName ?? this.lastName,
      roleName: roleName,
      roleGroup: roleGroup,
      profilePic: clearProfilePic ? null : (profilePic ?? this.profilePic),
      education: education ?? this.education,
      code: code ?? this.code,
      // teachingSchedule: teachingSchedule ?? this.teachingSchedule,
    );
    return profile;
  }

  String get displayName {
    if (isStudent && code != null && code!.isNotEmpty) {
      return code!;
    }
    return fullName;
  }

  String get fullName {
    if (firstName.isEmpty) return lastName;
    if (lastName.isEmpty) return firstName;
    return '$firstName $lastName';
  }

  bool get isStudent => roleGroup == 'student' || roleName.contains('student');

  bool get isTeacher =>
      roleGroup == 'teacher' ||
      roleName.contains('teacher') ||
      roleName.contains('instuctor');

  factory ProfileModel.fromJson(Map<String, dynamic> json) =>
      _$ProfileModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProfileModelToJson(this);
}
