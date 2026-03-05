import 'package:LinkLian/features/profile/views/student_profile_view.dart';
import 'package:LinkLian/features/profile/views/teacher_profile_view.dart';
import 'package:flutter/material.dart';
import '../../shared/models/profile_model.dart';

class ProfileBody extends StatelessWidget {
  final ProfileModel profile;
  const ProfileBody({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    if (profile.isStudent) {
      return const StudentProfileSection();
    }
    if (profile.isTeacher) {
      return const TeacherProfileView();
    }
    return const SizedBox();
  }
}