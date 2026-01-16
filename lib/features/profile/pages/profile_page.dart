import 'package:LinkLian/core/constants/linklian-icon.dart';
import 'package:LinkLian/features/profile/widgets/profile_body.dart';
import 'package:LinkLian/features/profile/widgets/profile_header.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/profile_controller.dart';
import '../widgets/profile_settings_sheet.dart';

class ProfilePage extends GetView<ProfileController> {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'โปรไฟล์',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(LinkLianIcon.settings, color: Colors.black),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (_) => const SettingsBottomSheetWithIcon(), 
              );
            },
          ),
        ],
      ),
      body: Obx(() {
        if (controller.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final profile = controller.profile.value;
        if (profile == null) {
          return const Center(child: Text('ไม่พบข้อมูลโปรไฟล์'));
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ProfileHeader(profile: profile),
            const Divider(indent: 16, endIndent: 16),

            // เปลี่ยนตาม role
            ProfileBody(profile: profile),
          ],
        );
      }),
    );
  }
}
