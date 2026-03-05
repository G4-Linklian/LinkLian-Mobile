import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/sizes.dart';
import '../controllers/class_detail_filter.dart';

class ClassFilterDropdown extends StatelessWidget {
  final Rx<ClassPostFilter> selected;
  final ValueChanged<ClassPostFilter> onChanged;

  const ClassFilterDropdown({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return GestureDetector(
        onTap: () => _openBottomSheet(context),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.sm,
            vertical: AppSizes.xs,
          ),
          decoration: BoxDecoration(
            color: AppColors.primaryPalette[500],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                selected.value.label,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.expand_more, size: 18),
            ],
          ),
        ),
      );
    });
  }

  void _openBottomSheet(BuildContext context) {
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: AppColors.primaryPalette[500],
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: ClassPostFilter.values.map((filter) {
            final isSelected = selected.value == filter;

            return ListTile(
              title: Text(
                filter.label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? AppColors.primaryPalette[600]
                      : AppColors.black,
                ),
              ),
              trailing: isSelected
                  ? Icon(Icons.check,
                      color: AppColors.primaryPalette[600])
                  : null,
              onTap: () {
                onChanged(filter);
                Get.back();
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}