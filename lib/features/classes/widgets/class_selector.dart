import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../../../core/constants/colors.dart';
import '../controllers/class_feed_controller.dart';
import '../controllers/create_post_controller.dart';

/// Widget สำหรับเลือก Class ในหน้าสร้างโพสต์
/// - แสดงเป็น Dropdown แบบ fit กับ text
/// - เลื่อนมาจากปุ่มแทนที่จะเป็น Bottom Sheet
/// - แสดงรูปแบบ "ชื่อวิชา • Section"
class ClassSelector extends StatelessWidget {
  final CreatePostController controller;
  final ClassFeedController classFeedController;

  const ClassSelector({
    super.key,
    required this.controller,
    required this.classFeedController,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      String displayText = 'ทั้งหมด';

      // กรณีเลือก 1 คลาส แสดง ชื่อวิชา Section"
      if (controller.selectedSectionIds.length == 1) {
        final sectionId = controller.selectedSectionIds.first;
        final selectedClass = classFeedController.classList.firstWhereOrNull(
          (c) => c.sectionId == sectionId,
        );

        if (selectedClass != null) {
          displayText =
              '${selectedClass.subjectNameTh} • ${selectedClass.sectionName}';
        }
      }
      // กรณีเลือกหลายคลาส แสดงจำนวน
      else if (controller.selectedSectionIds.length > 1) {
        displayText = '${controller.selectedSectionIds.length} คลาส';
      }

      return GestureDetector(
        onTap: controller.isSectionLocked.value
            ? null
            : () => _showClassDropdownMenu(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: controller.isSectionLocked.value
                ? AppColors.primaryPalette[100] 
                : AppColors.primaryPalette[200], 
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primaryPalette[700]!,
              width: 1.5,
            ),
          ),

          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.5 - 8,
          ),
          child: Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    Flexible( 
      child: Tooltip(
        message: displayText,
        waitDuration: const Duration(milliseconds: 400),
        showDuration: const Duration(seconds: 2),
        child: Text(
          displayText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.primaryPalette[900],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    ),
    const SizedBox(width: 6),
    Icon(
      controller.isSectionLocked.value
          ? TablerIcons.lock
          : TablerIcons.chevron_down,
      size: 16,
      color: AppColors.primaryPalette[900],
    ),
  ],
),
        ),
      );
    });
  }

  /// แสดง Dropdown Menu 
  void _showClassDropdownMenu(BuildContext context) {
    if (controller.isSectionLocked.value) return;

    final RenderBox button = context.findRenderObject() as RenderBox;
    // ใช้ screen coordinates โดยตรง
    final buttonPosition = button.localToGlobal(Offset.zero);
    final buttonSize = button.size;

    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: true,
      useSafeArea: false, // ไม่ใช้ safe area เพื่อให้ position ถูกต้อง
      builder: (dialogContext) {
        return Stack(
          children: [
            Positioned(
              left: buttonPosition.dx,
              top: buttonPosition.dy + buttonSize.height + 4,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: Get.height * 0.5,
                    minWidth: 250,
                    maxWidth: Get.width * 0.8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primaryPalette[700]!,
                      width: 1.5,
                    ),
                  ),
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      // ==================== ตัวเลือก "ทั้งหมด" ====================
                      InkWell(
                        onTap: () {
                          controller.selectedSectionIds.clear();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Obx(() {
                                final isAllSelected = controller.selectedSectionIds.isEmpty;
                                return Icon(
                                  isAllSelected
                                      ? TablerIcons.circle_check_filled
                                      : TablerIcons.circle,
                                  size: 20,
                                  color: isAllSelected
                                      ? AppColors.primaryPalette[500]
                                      : AppColors.gray,
                                );
                              }),
                              const SizedBox(width: 12),
                              const Text(
                                'ทั้งหมด',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const Divider(height: 1),

                      // ==================== Class อื่นๆ ====================
                      ...List.generate(classFeedController.classList.length, (index) {
                        final classItem = classFeedController.classList[index];

                        return InkWell(
                          onTap: () {
                            if (controller.selectedSectionIds.contains(classItem.sectionId)) {
                              controller.selectedSectionIds.remove(classItem.sectionId);
                            } else {
                              controller.selectedSectionIds.add(classItem.sectionId);
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Obx(() {
                              final isSelected = controller.selectedSectionIds.contains(
                                classItem.sectionId,
                              );

                              return Row(
                                children: [
                                  // Checkbox Icon
                                  Icon(
                                    isSelected
                                        ? TablerIcons.circle_check_filled
                                        : TablerIcons.circle,
                                    size: 20,
                                    color: isSelected
                                        ? AppColors.primaryPalette[500]
                                        : AppColors.gray,
                                  ),

                                  const SizedBox(width: 12),

                                  // ชื่อวิชา + Section
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${classItem.subjectCode} ${classItem.subjectNameTh}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          classItem.sectionName,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.primaryPalette[700]!,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}