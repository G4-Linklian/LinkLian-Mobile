import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/linklian-icon.dart';
import '../../../core/constants/sizes.dart';
import '../controllers/class_detail_controller.dart';
import '../controllers/class_detail_filter.dart';


class ClassDetailFilterSection extends StatelessWidget {
  final ClassDetailController controller;
  final bool isTeacher;

  const ClassDetailFilterSection({
    super.key,
    required this.controller,
    required this.isTeacher,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48, // Fixed height for consistent layout
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
      color: AppColors.white,
      child: Row(
        children: [
          Obx(
            () => _FilterDropdown(
              selected: controller.selectedFilter.value,
              onChanged: (filter) => controller.changeFilter(filter),
            ),
          ),
          const Spacer(),
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
          child: Center(
            child: Text(
              filter.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryPalette[900],
                height: 1.0,
              ),
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              selected.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryPalette[900],
                height: 1.0,
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

class ClassDetailFilterSectionDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  ClassDetailFilterSectionDelegate({required this.child});

  @override
  double get minExtent => 48;

  @override
  double get maxExtent => 48;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(ClassDetailFilterSectionDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}