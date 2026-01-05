import 'package:flutter/material.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/sizes.dart';
import '../../../core/constants/style.dart';

class LoginInfoPopup extends StatelessWidget {
  const LoginInfoPopup({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(AppSizes.lg),
        decoration: BoxDecoration(
          color: AppColors.primaryPalette[100],
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: _content(),
      ),
    );
  }

  Widget _content() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'คู่มือการเข้าสู่ระบบ',
          style: AppTextStyles.subheadingSemiBold.copyWith(
            color: AppColors.primaryPalette[800],
          ),
        ),
        const SizedBox(height: AppSizes.sm),
        Text(
          'อีเมลและรหัสผ่านถถูกส่งผ่านอีเมลที่ลงทะเบียนไว้ โปรดตรวจสอบอีเมลของคุณ',
          style: AppTextStyles.descriptionRegular.copyWith(
            color: AppColors.primaryPalette[700],
          ),
        ),
        const SizedBox(height: AppSizes.md),

        _infoCard(
          title: 'ชื่อผู้ใช้',
          leftLabel: 'นักเรียน',
          leftValue: 'รหัสนักศึกษา (11 หลัก)\ne.g.00000000000',
          rightLabel: 'อาจารย์',
          rightValue: 'อีเมลส่วนตัว\ne.g.ajan@gmail.com',
        ),

        const SizedBox(height: AppSizes.md),

        _infoCard(
          title: 'รหัสผ่าน',
          leftLabel: '',
          leftValue: 'รหัสผ่านชั่วคราวที่ได้จากอีเมล',
          rightLabel: '',
          rightValue: '',
        ),
      ],
    );
  }

  Widget _infoCard({
    required String title,
    required String leftLabel,
    required String leftValue,
    required String rightLabel,
    required String rightValue,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: AppColors.primaryPalette[300]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.descriptionSemiBold.copyWith(
              color: AppColors.primaryPalette[800],
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          if (leftLabel.isNotEmpty)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _roleInfo(leftLabel, leftValue)),
                const SizedBox(width: AppSizes.sm),
                Expanded(child: _roleInfo(rightLabel, rightValue)),
              ],
            )
          else
            Text(
              leftValue,
              style: AppTextStyles.descriptionRegular.copyWith(
                color: AppColors.primaryPalette[700],
              ),
            ),
        ],
      ),
    );
  }

  Widget _roleInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.descriptionSemiBold.copyWith(
            color: AppColors.primaryPalette[700],
          ),
        ),
        const SizedBox(height: AppSizes.xs),
        Text(
          value,
          style: AppTextStyles.descriptionRegular.copyWith(
            color: AppColors.primaryPalette[600],
          ),
        ),
      ],
    );
  }
}