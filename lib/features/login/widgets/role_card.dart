import 'package:flutter/material.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/sizes.dart';
import '../../../core/constants/style.dart';

class RoleCard extends StatelessWidget {
  final Widget icon;
  final String title;
  final VoidCallback onTap;

  const RoleCard({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSizes.lg),
        decoration: BoxDecoration(
          color: AppColors.primaryPalette[100],
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(height: AppSizes.md),
            Text(
              title,
              style: AppTextStyles.headerBold.copyWith(
                color: AppColors.primaryPalette[800],
              ),
            ),
          ],
        ),
      ),
    );
  }
}