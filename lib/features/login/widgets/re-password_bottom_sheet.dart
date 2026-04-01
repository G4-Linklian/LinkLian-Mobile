import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/sizes.dart';
import '../../../core/constants/style.dart';
import '../../../core/utils/dialog_helper.dart';
import '../../../data/repository/auth_repository.dart';
import '../../auth/controller/auth_controller.dart';

class ResetPasswordBottomSheet extends StatefulWidget {
  final String token;
  final String roleName;
  final int instId;
  final int userId;

  const ResetPasswordBottomSheet({
    super.key,
    required this.token,
    required this.roleName,
    required this.instId,
    required this.userId,
  });

  @override
  State<ResetPasswordBottomSheet> createState() =>
      _ResetPasswordBottomSheetState();
}

class _ResetPasswordBottomSheetState extends State<ResetPasswordBottomSheet> {
  final _authRepository = AuthRepository();

  final newPassword = TextEditingController();
  final confirmPassword = TextEditingController();

  bool obscureNew = true;
  bool obscureConfirm = true;
  bool isLoading = false;

  InputDecoration _inputDecoration({
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: AppTextStyles.descriptionRegular.copyWith(
        color: AppColors.primaryPalette[700],
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primaryPalette[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppColors.primaryPalette[500]!,
          width: 1.5,
        ),
      ),
      suffixIcon: IconButton(
        icon: Icon(
          obscure ? Icons.visibility_off : Icons.visibility,
          size: 20,
          color: AppColors.primaryPalette[700],
        ),
        onPressed: onToggle,
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
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Future<void> _submitResetPassword() async {
    try {
      setState(() => isLoading = true);

      await _authRepository.resetPassword(
        newPassword: newPassword.text.trim(),
        confirmPassword: confirmPassword.text.trim(),
      );

      Get.back(); // ปิด bottom sheet

      // establish session → AuthGate จะ navigate ไป MainPage เอง
      final authController = Get.find<AuthController>();
      await authController.establishSession(
        token: widget.token,
        roleName: widget.roleName,
        instId: widget.instId,
        userId: widget.userId,
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
      initialChildSize: 0.65,
      minChildSize: 0.5,
      maxChildSize: 0.9,
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

              // Drag handle
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

              // Title
              Text(
                'ตั้งค่ารหัสผ่านใหม่',
                textAlign: TextAlign.center,
                style: AppTextStyles.titleSemiBold.copyWith(
                  color: const Color(0xFF9A3B1C),
                ),
              ),

              const SizedBox(height: 32),

              _shadowField(
                TextField(
                  controller: newPassword,
                  obscureText: obscureNew,
                  decoration: _inputDecoration(
                    label: 'รหัสผ่านใหม่',
                    obscure: obscureNew,
                    onToggle: () => setState(() => obscureNew = !obscureNew),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              _shadowField(
                TextField(
                  controller: confirmPassword,
                  obscureText: obscureConfirm,
                  decoration: _inputDecoration(
                    label: 'ยืนยันรหัสผ่านใหม่',
                    obscure: obscureConfirm,
                    onToggle: () =>
                        setState(() => obscureConfirm = !obscureConfirm),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPalette[300],
                  elevation: 4,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: isLoading ? null : _submitResetPassword,
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
                        'ยืนยัน',
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
