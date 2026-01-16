import 'package:LinkLian/features/profile/pages/dashboard_page.dart';
import 'package:LinkLian/features/profile/widgets/dashboard_card.dart';
import 'package:LinkLian/features/profile/widgets/teaching_schedule_section.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import '../../../data/model/profile_model.dart';

class TeacherProfileView extends StatelessWidget {
  final ProfileModel profile;
  const TeacherProfileView({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DashboardCard(
          onTap: () {
            Get.to(() => const DashboardPage());
          },
        ),

        TeachingScheduleSection(
          schedules: profile.teachingSchedule ?? [],
        ),
      ],
    );
  }
}
