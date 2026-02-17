import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/sizes.dart';
import '../controllers/class_assignment_controller.dart';
import 'assignment_filter_dropdown.dart';

/// Filter section widget for assignment page
/// 
/// This widget is extracted as a separate component for:
/// - Better reusability across different pages
/// - Easier maintenance and updates
/// - Scalability for future features
class AssignmentFilterSection extends StatelessWidget {
  final ClassAssignmentController controller;

  const AssignmentFilterSection({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48, // Fixed height for consistent layout
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
      color: AppColors.white,
      child: Row(
        children: [
          Obx(() => AssignmentFilterDropdown(
                options: controller.filterOptions,
                currentFilter: controller.currentFilter.value,
                onFilterChanged: controller.applyFilter,
              )),
        ],
      ),
    );
  }
}

/// SliverPersistentHeaderDelegate for AssignmentFilterSection
class AssignmentFilterSectionDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  AssignmentFilterSectionDelegate({required this.child});

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
  bool shouldRebuild(AssignmentFilterSectionDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}