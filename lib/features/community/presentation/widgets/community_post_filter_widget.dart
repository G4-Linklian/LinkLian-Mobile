import 'package:LinkLian/core/constants/colors.dart';
import 'package:LinkLian/core/constants/linklian-icon.dart';
import 'package:LinkLian/features/community/presentation/controllers/community_detail_controller.dart';
import 'package:flutter/material.dart';

class CommunityFilterDropdown extends StatelessWidget {
  final CommunityPostFilter selected;
  final ValueChanged<CommunityPostFilter> onChanged;

  const CommunityFilterDropdown({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<CommunityPostFilter>(
      onSelected: onChanged,

      itemBuilder: (context) => CommunityPostFilter.values.map((filter) {
        return PopupMenuItem<CommunityPostFilter>(
          value: filter,
          child: SizedBox(
            width: 85,
            child: Center(
              child: Text(
                filter.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primaryPalette[900],
                ),
              ),
            ),
          ),
        );
      }).toList(),

      offset: const Offset(0, 45),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: AppColors.primaryPalette[300],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
            const SizedBox(width: 6),
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
