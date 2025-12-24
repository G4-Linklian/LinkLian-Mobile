import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/sizes.dart';

class ActiveNavIcon extends StatelessWidget {
  final IconData icon;

  const ActiveNavIcon({
    super.key,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.xs),
      decoration: BoxDecoration(
        color: AppColors.primaryPalette[400],
        borderRadius: BorderRadius.circular(AppSizes.buttonLg),
      ),
      child: Icon(
        icon,
        color: AppColors.primaryPalette[900],
        size: AppSizes.iconMd,
      ),
    );
  }
}