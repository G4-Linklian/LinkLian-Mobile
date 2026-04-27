import 'package:LinkLian/core/services/api_client.dart';
import 'package:LinkLian/features/shared/repositories/bookmark_repository.dart';
import 'package:LinkLian/features/shared/presentations/bookmark_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:LinkLian/features/profile/presentation/pages/dashboard_page.dart';
import 'package:LinkLian/features/profile/presentation/bindings/dashboard_binding.dart';
import '../../../shared/models/profile_model.dart';
import '../widgets/profile_header.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/bookmark_switcher.dart';

class StudentProfileView extends StatelessWidget {
  final ProfileModel profile;
  const StudentProfileView({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ProfileHeader(profile: profile),
        const SizedBox(height: 12),

        // Dashboard
        DashboardCard(
          onTap: () {
            Get.to(
              () => const DashboardPage(),
              binding: DashboardBinding(),
              transition: Transition.rightToLeft,
            );
          },
        ),
        const Divider(indent: 16, endIndent: 16),

        //Bookmark Switcher
        const BookmarkSwitcher(),
      ],
    );
  }
}

class StudentProfileSection extends StatelessWidget {
  const StudentProfileSection({super.key});

  @override
  Widget build(BuildContext context) {
    // Register BookmarkController ถ้ายังไม่มี
    if (!Get.isRegistered<BookmarkController>()) {
      Get.put(BookmarkController(BookmarkRepository(Get.find<ApiClient>())));
    }

    return Column(
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
        const SizedBox(height: 16),

        // BookmarkSwitcher แสดงบุ๊กมาร์ก
        const BookmarkSwitcher(),
      ],
    );
  }
}
