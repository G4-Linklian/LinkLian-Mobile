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

  final oldPassword = TextEditingController();
  final newPassword = TextEditingController();
  final confirmPassword = TextEditingController();
  final FocusNode passwordFocus = FocusNode();
  bool isFocused = false;
  @override
  void initState() {
    super.initState();

    passwordFocus.addListener(() {
      setState(() {
        isFocused = passwordFocus.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    passwordFocus.dispose();
    super.dispose();
  }

  bool obscureOld = true;
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
    final oldPass = oldPassword.text.trim();
    final newPass = newPassword.text.trim();
    final confirmPass = confirmPassword.text.trim();

    // Validate
    if (oldPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
      DialogHelper.showNotification(
        title: 'ไม่สำเร็จ',
        message: 'กรุณากรอกข้อมูลให้ครบถ้วน',
        type: NotificationType.error,
      );
      return;
    }

    if (newPass.length < 8) {
      DialogHelper.showNotification(
        title: 'ไม่สำเร็จ',
        message: 'รหัสผ่านใหม่ต้องมีความยาวอย่างน้อย 8 ตัวอักษร',
        type: NotificationType.error,
      );
      return;
    }

    if (!RegExp(r'[a-z]').hasMatch(newPass) ||
        !RegExp(r'[A-Z]').hasMatch(newPass)) {
      DialogHelper.showNotification(
        title: 'ไม่สำเร็จ',
        message: 'รหัสผ่านใหม่ควรมีตัวพิมพ์เล็กและตัวพิมพ์ใหญ่',
        type: NotificationType.error,
      );
      return;
    }

    if (newPass != confirmPass) {
      DialogHelper.showNotification(
        title: 'ไม่สำเร็จ',
        message: 'รหัสผ่านใหม่และยืนยันรหัสผ่านไม่ตรงกัน',
        type: NotificationType.error,
      );
      return;
    }

    if (oldPass == newPass) {
      DialogHelper.showNotification(
        title: 'ไม่สำเร็จ',
        message: 'รหัสผ่านใหม่ต้องไม่ซ้ำกับรหัสผ่านเดิม',
        type: NotificationType.error,
      );
      return;
    }

    try {
      setState(() => isLoading = true);

      await _authRepository.resetPassword(
        oldPassword: oldPass,
        newPassword: newPass,
        confirmPassword: confirmPass,
      );

      Get.back();

      DialogHelper.showNotification(
        title: 'สำเร็จ',
        message: 'เปลี่ยนรหัสผ่านเรียบร้อยแล้ว',
        type: NotificationType.success,
      );

      final authController = Get.find<AuthController>();
      await authController.establishSession(
        token: widget.token,
        roleName: widget.roleName,
        instId: widget.instId,
        userId: widget.userId,
      );
    } catch (e) {
      String extractErrorMessage(dynamic error) {
        try {
          // กรณีใช้ Dio
          if (error is Exception && error.toString().contains('DioError')) {
            final dioErr = error as dynamic;
            if (dioErr.response?.data != null) {
              final data = dioErr.response?.data;
              if (data is Map && data['message'] != null) {
                if (data['message'] is String) return data['message'];
                if (data['message'] is List && data['message'].isNotEmpty) {
                  return data['message'][0].toString();
                }
              }
            }
          }
        } catch (_) {}
        // fallback: ใช้ toString
        return error.toString();
      }

      String errorMsg = extractErrorMessage(e).toLowerCase();
      String displayMsg = 'ไม่สามารถเปลี่ยนรหัสผ่านได้ กรุณาตรวจสอบข้อมูลอีกครั้ง';
      if (
        errorMsg.contains('old password is incorrect') ||
        errorMsg.contains('old password') ||
        errorMsg.contains('รหัสผ่านเดิม') ||
        errorMsg.contains('401') ||
        errorMsg.contains('unauthorized')
      ) {
        displayMsg = 'รหัสผ่านเดิมไม่ถูกต้อง';
      } else if (errorMsg.contains('new password and confirm password do not match')) {
        displayMsg = 'รหัสผ่านใหม่และยืนยันรหัสผ่านไม่ตรงกัน';
      } else if (errorMsg.contains('new password must be at least')) {
        displayMsg = 'รหัสผ่านใหม่ต้องมีความยาวอย่างน้อย 8 ตัวอักษร';
      } else if (errorMsg.contains('user not found')) {
        displayMsg = 'ไม่พบบัญชีผู้ใช้';
      }
      DialogHelper.showNotification(
        title: 'ไม่สำเร็จ',
        message: displayMsg,
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
                  controller: oldPassword,
                  obscureText: obscureOld,
                  decoration: _inputDecoration(
                    label: 'รหัสผ่านเดิม',
                    obscure: obscureOld,
                    onToggle: () => setState(() => obscureOld = !obscureOld),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _shadowField(
                    TextField(
                      controller: newPassword,
                      focusNode: passwordFocus,
                      obscureText: obscureNew,
                      decoration: _inputDecoration(
                        label: 'รหัสผ่านใหม่',
                        obscure: obscureNew,
                        onToggle: () =>
                            setState(() => obscureNew = !obscureNew),
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  SizedBox(
                    height: 20,
                    child: Visibility(
                      visible: isFocused,
                      maintainSize: true,
                      maintainAnimation: true,
                      maintainState: true,
                      child: Text(
                        '*ควรมีอย่างน้อย 8 ตัวอักษร โดยมีทั้งตัวพิมพ์ใหญ่และตัวพิมพ์เล็ก',
                        style: AppTextStyles.descriptionRegular.copyWith(
                          fontSize: 11,
                          color: AppColors.primaryPalette[600],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Confirm password
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
