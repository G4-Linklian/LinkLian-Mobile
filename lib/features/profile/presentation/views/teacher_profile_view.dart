import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:LinkLian/features/profile/presentation/pages/dashboard_page.dart';
import 'package:LinkLian/features/profile/presentation/bindings/dashboard_binding.dart';
import 'package:LinkLian/features/profile/presentation/widgets/dashboard_card.dart';
import 'package:LinkLian/features/profile/presentation/widgets/teaching_schedule_section.dart';
import '../controllers/profile_controller.dart';

class TeacherProfileView extends GetView<ProfileController> {
  const TeacherProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DashboardCard(
          onTap: () {
            Get.to(
              () => const DashboardPage(),
              binding: DashboardBinding(),
              transition: Transition.rightToLeft,
            );
          },
        ),

        const SizedBox(height: 12),

        Obx(() {
          if (controller.loadingSchedule.value) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          return TeachingScheduleSection(
            schedules: controller.teachingSchedules,
          );
        }),
      ],
    );
  }
}
