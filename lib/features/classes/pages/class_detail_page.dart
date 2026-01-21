import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/sizes.dart';
import '../../../core/constants/linklian-icon.dart';
import '../controllers/class_detail_controller.dart';
import '../controllers/class_detail_filter.dart';
import '../../../config/app_routes.dart';
import '../widgets/card_post.dart';
import '../controllers/create_post_controller.dart';
import '../../auth/controller/auth_controller.dart';

class ClassDetailPage extends StatelessWidget {
  const ClassDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ClassDetailController>();
    final auth = Get.find<AuthController>();
    final isTeacher =
        auth.roleName.value == 'teacher' || auth.roleName.value == 'instructor';

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.white,
        leading: IconButton(
          icon: const Icon(LinkLianIcon.back, color: AppColors.black),
          onPressed: () => Get.back(),
        ),
        centerTitle: true,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Obx(
              () => Text(
                controller.subjectNameTh.value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Obx(
              () => Text(
                controller.effectiveClassName.value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.black.withOpacity(0.6),
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              LinkLianIcon.add,
              color: AppColors.primaryPalette[500],
              size: 28,
            ),
            onPressed: () async {
              final result = await Get.toNamed(
                AppRoutes.createPost,
                arguments: {
                  'mode': CreatePostMode.create,
                  'source': CreatePostSource.classDetail,
                  'sectionId': controller.sectionId.value,
                  'presetSectionIds': [controller.sectionId.value],
                  'lockSection': true,
                },
              );

              if (result?['success'] == true) {
                controller.fetchPosts();
                controller.scrollToTop();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _FilterSection(controller: controller, isTeacher: isTeacher),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.posts.isEmpty) {
                return const Center(
                  child: Text(
                    'ยังไม่มีโพสต์ในห้องนี้',
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
                itemCount: controller.posts.length,
                itemBuilder: (context, index) {
                  final post = controller.posts[index];
                  return CardPost(
                    post: post,
                    onSelectForAI: isTeacher
                        ? null
                        : (postId) {
                            controller.togglePostSelection(postId);
                          },
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  final ClassDetailController controller;
  final bool isTeacher;
  const _FilterSection({required this.controller, required this.isTeacher});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.md),
      child: Row(
        children: [
          // Filter Dropdown
          Obx(
            () => _FilterDropdown(
              selected: controller.selectedFilter.value,
              onChanged: (filter) => controller.changeFilter(filter),
            ),
          ),

          const Spacer(),

          // AI Summary Button
if (!isTeacher)
  Obx(() {
    final count = controller.selectedPostIdsForAI.length;
    return TextButton.icon(
      onPressed: count > 0 ? controller.generateAISummary : null,
      icon: Icon(
        Icons.auto_awesome,
        color: count > 0
            ? AppColors.primaryPalette[500]
            : Colors.grey,
        size: 18,
      ),
      label: Text(
        count > 0
            ? 'AI สรุปเนื้อหา ($count)'
            : 'AI สรุปเนื้อหา',
        style: TextStyle(
          color: count > 0
              ? AppColors.primaryPalette[500]
              : Colors.grey,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }),
        ],
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final ClassPostFilter selected;
  final ValueChanged<ClassPostFilter> onChanged;

  const _FilterDropdown({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<ClassPostFilter>(
      onSelected: (value) => onChanged(value),
      itemBuilder: (context) => ClassPostFilter.values.map((filter) {
        return PopupMenuItem<ClassPostFilter>(
          value: filter,
          child: Text(
            filter.label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.primaryPalette[900],
            ),
          ),
        );
      }).toList(),
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: AppColors.primaryPalette[300],
      child: Container(
        width: 115,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primaryPalette[300],
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              selected.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryPalette[900],
              ),
            ),
            Icon(
              LinkLianIcon.filterpost,
              size: 18,
              color: AppColors.primaryPalette[700],
            ),
          ],
        ),
      ),
    );
  }
}
