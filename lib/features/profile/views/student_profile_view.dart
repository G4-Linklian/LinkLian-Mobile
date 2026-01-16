import 'package:LinkLian/features/profile/pages/dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import '../../../data/model/profile_model.dart';
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
            Get.to(() => const DashboardPage());
          },
        ),

        const Divider(indent: 16, endIndent: 16),

        // Bookmark / Community switch
        const BookmarkSwitcher(),
      ],
    );
  }
}

class StudentProfileSection extends StatelessWidget {
  const StudentProfileSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DashboardCard(
          onTap: () => Get.to(() => const DashboardPage()),
        ),
        const SizedBox(height: 16),
        const BookmarkSwitcher(),
      ],
    );
  }
}