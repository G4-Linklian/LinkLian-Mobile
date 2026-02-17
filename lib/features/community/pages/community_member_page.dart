import 'package:LinkLian/core/constants/linklian-icon.dart';
import 'package:LinkLian/features/community/widgets/app_avatar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/community_member_controller.dart';

class CommunityMemberPage extends StatelessWidget {
  const CommunityMemberPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CommunityMemberController>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LinkLianIcon.chevronleft, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'สมาชิกชุมชน',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.members.isEmpty) {
          return const Center(child: Text("ไม่มีสมาชิก"));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: controller.members.length,
          itemBuilder: (context, index) {
            final member = controller.members[index];

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  AppAvatar(
                    firstName: member.firstName,
                    lastName: member.lastName,
                    profilePic: member.profilePic,
                    radius: 28,
                  ),

                  const SizedBox(width: 16),

                  Expanded(
                    child: Text(
                      "${member.firstName} ${member.lastName}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }),
    );
  }
}
