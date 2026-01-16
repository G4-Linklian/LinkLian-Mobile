import 'package:json_annotation/json_annotation.dart';
import 'education_model.dart';
import 'teaching_schedule_model.dart';


part 'profile_model.g.dart';

int _intFromJson(dynamic value) => int.parse(value.toString());
String _intToJson(int value) => value.toString();

@JsonSerializable()
class ProfileModel {
  @JsonKey(
    name: 'user_sys_id',
    fromJson: _intFromJson,
    toJson: _intToJson,
  )
  final int userSysId;

  final String email;

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

  @JsonKey(name: 'teaching_schedule')
  final List<TeachingScheduleModel>? teachingSchedule;


  ProfileModel({
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
    this.teachingSchedule,
  });

  ProfileModel copyWith({
  String? firstName,
  String? middleName,
  String? lastName,
  String? phone,
  String? profilePic,
  EducationModel? education,
  List<TeachingScheduleModel>? teachingSchedule,
}) {
  return ProfileModel(
    userSysId: userSysId,
    email: email,
    firstName: firstName ?? this.firstName,
    middleName: middleName ?? this.middleName,
    lastName: lastName ?? this.lastName,
    roleName: roleName,
    roleGroup: roleGroup,
    profilePic: profilePic ?? this.profilePic,
    education: education ?? this.education,
    teachingSchedule: teachingSchedule ?? this.teachingSchedule,
  );
}


  String get fullName =>
      middleName != null && middleName!.isNotEmpty
          ? '$firstName $middleName $lastName'
          : '$firstName $lastName';

  bool get isStudent =>
      roleGroup == 'student' || roleName.contains('student');

  bool get isTeacher =>
      roleGroup == 'teacher' ||
      roleName.contains('teacher') ||
      roleName.contains('instuctor');

  factory ProfileModel.fromJson(Map<String, dynamic> json) =>
      _$ProfileModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProfileModelToJson(this);
}
