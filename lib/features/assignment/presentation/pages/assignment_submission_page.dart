import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/sizes.dart';
import '../../../../core/constants/linklian-icon.dart';

import '../controllers/assignment_submission_controller.dart';
import '../../../classes/presentation/widgets/card_post.dart';
import '../widgets/submission_bottomsheet.dart';


class AssignmentSubmissionPage extends StatelessWidget {
  const AssignmentSubmissionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AssignmentSubmissionController>();

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: const Text(
          'การบ้าน',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.black,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LinkLianIcon.back, color: AppColors.black),
          onPressed: () => Get.back(),
        ),
      ),

      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final post = controller.post.value;
        if (post == null) {
          return const Center(child: Text('ไม่พบข้อมูลการบ้าน'));
        }

        return Stack(
          children: [
            // ===== MAIN CONTENT =====
            ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.md,
                16,
                AppSizes.md,
                200,
              ),
              children: [
                CardPost(post: post, onSelectForAI: null),
              ],
            ),

            // ===== DRAGGABLE BOTTOM SHEET =====
            SubmissionBottomSheet(controller: controller),
          ],
        );
      }),
    );
  }
}