import 'package:LinkLian/core/constants/colors.dart';
import 'package:LinkLian/core/constants/linklian-icon.dart';
import 'package:LinkLian/features/community/widgets/app_avatar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/community_pending_controller.dart';

class CommunityPendingPage extends StatelessWidget {
  const CommunityPendingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CommunityPendingController>();

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
          'คำขอเข้าร่วม',
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

        if (controller.errorMessage.value != null) {
          return Center(child: Text(controller.errorMessage.value!));
        }

        if (controller.pendingMembers.isEmpty) {
          return const Center(child: Text("ไม่มีคำขอเข้าร่วม"));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.pendingMembers.length,
          itemBuilder: (context, index) {
            final member = controller.pendingMembers[index];

            return Card(
              color: const Color.fromARGB(255, 236, 236, 236),
              elevation: 4,
              shadowColor: Colors.black.withOpacity(0.08),
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    AppAvatar(
                      firstName: member.firstName,
                      lastName: member.lastName,
                      profilePic: member.profilePic,
                      radius: 30, 
                    ),

                    const SizedBox(width: 16),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${member.firstName} ${member.lastName}",
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (member.isApproved)
                            Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Text(
                                "เข้าร่วมแล้ว",
                                style: TextStyle(
                                  color: AppColors.successPalette[700],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    if (!member.isApproved) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: 30,
                            child: OutlinedButton(
                              onPressed: () async {
                                await controller
                                    .approve(member.userSysId);
                              },
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 30),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10),
                                side: BorderSide(
                                    color: AppColors.successPalette[700]!),
                                foregroundColor: AppColors.successPalette[700],
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(18),
                                ),
                              ),
                              child: const Text(
                                "Approve",
                                style: TextStyle(
                                  fontSize: 11, 
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),

                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints:
                                const BoxConstraints(),
                            icon: Icon(
                              Icons.close,
                              color: AppColors.dangerPalette[500],
                              size: 20,
                            ),
                            onPressed: () {
                              _showRejectDialog(
                                  context, member.userSysId);
                            },
                          ),
                        ],
                      ),
                    ] else ...[
                      IconButton(
                        icon: Icon(
                          Icons.edit,
                          color: AppColors.primaryPalette[600],
                        ),
                        onPressed: () {
                          _showRejectDialog(
                              context, member.userSysId);
                        },
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

void _showRejectDialog(BuildContext context, int userId) {
  final controller = Get.find<CommunityPendingController>();

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: const Text("ยืนยันการลบ"),
      content: const Text("ต้องการลบสมาชิกคนนี้หรือไม่?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("ยกเลิก"),
        ),
        TextButton(
          onPressed: () async {
            await controller.reject(userId);
            Navigator.pop(context);
          },
          child: const Text(
            "ลบ",
            style: TextStyle(color: Colors.red),
          ),
        ),
      ],
    ),
  );
}

