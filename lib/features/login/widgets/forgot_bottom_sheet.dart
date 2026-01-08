import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/sizes.dart';
import '../../../core/constants/style.dart';
import '../../../core/utils/dialog_helper.dart';
import '../../../data/repository/auth_repository.dart';

class ForgotPasswordBottomSheet extends StatefulWidget {
  const ForgotPasswordBottomSheet({super.key});

  @override
  State<ForgotPasswordBottomSheet> createState() =>
      _ForgotPasswordBottomSheetState();
}

class _ForgotPasswordBottomSheetState
    extends State<ForgotPasswordBottomSheet> {
  final _authRepository = AuthRepository();
  final emailController = TextEditingController();

  bool isLoading = false;

  // === reuse style จาก ResetPassword ===
  InputDecoration _inputDecoration({
    required String label,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: AppTextStyles.descriptionRegular.copyWith(
        color: AppColors.primaryPalette[700],
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppColors.primaryPalette[300]!,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppColors.primaryPalette[500]!,
          width: 1.5,
        ),
      ),
      filled: true,
      fillColor: AppColors.white,
    );
  }

  Widget _shadowField(Widget child) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Future<void> _submitForgotPassword() async {
    try {
      setState(() => isLoading = true);

      await _authRepository.forgotPassword(
        email: emailController.text.trim(),
      );

      Get.back(); // ✅ ปิด bottom sheet ก่อน

      DialogHelper.showNotification(
        title: 'สำเร็จ',
        message: 'ส่งรหัสผ่านชั่วคราวไปที่อีเมลแล้ว',
        type: NotificationType.success,
      );
    } catch (e) {
      DialogHelper.showNotification(
        title: 'ไม่สำเร็จ',
        message: e.toString(),
        type: NotificationType.error,
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.45,
      maxChildSize: 0.8,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppSizes.radiusXl),
            ),
          ),
          child: ListView(
            controller: scrollController,
            children: [
              const SizedBox(height: 16),

              // ===== Drag Handle =====
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.black,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ===== Title =====
              Text(
                'ลืมรหัสผ่าน',
                textAlign: TextAlign.center,
                style: AppTextStyles.titleSemiBold.copyWith(
                  color: const Color(0xFF9A3B1C),
                ),
              ),

              const SizedBox(height: 12),

              Text(
                'กรุณากรอกอีเมลที่ใช้ลงทะเบียน\nระบบจะส่งรหัสผ่านชั่วคราวให้',
                textAlign: TextAlign.center,
                style: AppTextStyles.descriptionRegular.copyWith(
                  color: AppColors.primaryPalette[600],
                ),
              ),

              const SizedBox(height: 32),

              // ===== Email =====
              _shadowField(
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration(
                    label: 'อีเมลที่ลงทะเบียน',
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ===== Submit =====
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPalette[300],
                  elevation: 4,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: isLoading ? null : _submitForgotPassword,
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : Text(
                        'ส่งรหัสผ่านใหม่',
                        style: AppTextStyles.subheadingSemiBold.copyWith(
                          color: const Color(0xFF9A3B1C),
                        ),
                      ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }
}