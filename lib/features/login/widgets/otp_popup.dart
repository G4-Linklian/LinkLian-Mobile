import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/sizes.dart';
import '../../../core/constants/style.dart';
import '../controllers/otp_controller.dart';

class OtpPopup extends StatelessWidget {
  const OtpPopup({super.key});

  @override
  Widget build(BuildContext context) {
final controller = Get.find<OtpController>();
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(AppSizes.lg),
          decoration: BoxDecoration(
            color: AppColors.primaryPalette[100],
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.sms_outlined, size: 56),

              const SizedBox(height: AppSizes.md),

              Text(
                'รหัสยืนยัน',
                style: AppTextStyles.subheadingSemiBold,
              ),

              const SizedBox(height: AppSizes.sm),

              Obx(
                () => Text(
                  controller.isExpired.value
                      ? 'รหัสหมดอายุ'
                      : 'หมดอายุใน ${controller.timeText}',
                  style: AppTextStyles.descriptionRegular.copyWith(
                    color: controller.isExpired.value
                        ? Colors.red
                        : AppColors.primaryPalette[700],
                  ),
                ),
              ),

              const SizedBox(height: AppSizes.lg),

              Obx(
                () => TextField(
                  enabled: !controller.isExpired.value,
                  maxLength: 6,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    letterSpacing: 12,
                  ),
                  decoration: const InputDecoration(
                    counterText: '',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: controller.onOtpChanged,
                ),
              ),

              const SizedBox(height: AppSizes.lg),

              Obx(
                () => ElevatedButton(
                  onPressed: controller.isExpired.value ||
                          controller.otp.value.length != 6
                      ? null
                      : controller.submitOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPalette[300],
                    minimumSize: const Size(double.infinity, 44),
                  ),
                  child: controller.isLoading.value
    ? const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.white,
        ),
      )
    : const Text('ยืนยัน'),
                ),
              ),

              const SizedBox(height: AppSizes.sm),

              Obx(
                () => TextButton(
                  onPressed:
                      controller.isExpired.value ? controller.resendOtp : null,
                  child: const Text('ส่งรหัสอีกครั้ง'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}