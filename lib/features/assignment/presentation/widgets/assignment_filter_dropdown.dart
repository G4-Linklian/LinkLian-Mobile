import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/linklian-icon.dart';

class AssignmentFilterDropdown extends StatelessWidget {
  final List<String> options;
  final String currentFilter;
  final ValueChanged<String> onFilterChanged;

  const AssignmentFilterDropdown({
    super.key,
    required this.options,
    required this.currentFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onFilterChanged,
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: AppColors.white,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primaryPalette[300],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
             Text(
              'กรองโพสต์',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.primaryPalette[700],
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 4),
            Icon(LinkLianIcon.filterpost, color: AppColors.primaryPalette[700], size: 18),
          ],
        ),
      ),
      itemBuilder: (context) => options.map((option) {
        final isSelected = option == currentFilter;
        return PopupMenuItem<String>(
          value: option,
          child: Text(
            option,
            style: TextStyle(
              fontSize: 14,
              color: isSelected ? AppColors.primaryPalette[500] : AppColors.black,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        );
      }).toList(),
    );
  }
}
