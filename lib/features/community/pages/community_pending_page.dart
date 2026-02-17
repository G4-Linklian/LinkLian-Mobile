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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: controller.pendingMembers.length,
          itemBuilder: (context, index) {
            final member = controller.pendingMembers[index];

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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${member.firstName} ${member.lastName}",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        if (member.isApproved) const SizedBox(height: 4),

                        if (member.isApproved)
                          Text(
                            "เข้าร่วมแล้ว",
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.successPalette[800],
                            ),
                          ),
                      ],
                    ),
                  ),

                  if (!member.isApproved) ...[
                    Container(
                      height: 34,
                      decoration: BoxDecoration(
                        color:
                            AppColors.successPalette[100] ??
                            AppColors.successPalette[700],
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.successPalette[600] ?? Colors.green,
                          width: 1.2,
                        ),
                      ),
                      child: TextButton(
                        onPressed: () async {
                          await controller.approve(member.userSysId);
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          minimumSize: const Size(0, 34),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          "ยืนยัน",
                          style: TextStyle(
                            color: AppColors.successPalette[600],
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 2),

                    IconButton(
                      icon: Icon(
                        Icons.delete,
                        size: 20,
                        color: AppColors.dangerPalette[500],
                      ),
                      onPressed: () {
                        _showRejectDialog(context, member.userSysId);
                      },
                    ),
                  ] else ...[
                    IconButton(
                      icon: Icon(
                        Icons.delete,
                        size: 20,
                        color: AppColors.dangerPalette[500],
                      ),
                      onPressed: () {
                        _showRejectDialog(context, member.userSysId);
                      },
                    ),
                  ],
                ],
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
          child: const Text("ลบ", style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
}
