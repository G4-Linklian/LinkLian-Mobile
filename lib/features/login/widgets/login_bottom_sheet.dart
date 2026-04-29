import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/sizes.dart';
import '../../../core/constants/style.dart';
import '../../../core/constants/strings.dart';
import '../controllers/login_controller.dart';
import '../../../core/constants/linklian-icon.dart';
import '../widgets/login_info.dart';
import '../widgets/forgot_bottom_sheet.dart';

class LoginBottomSheet extends StatefulWidget {
  final LoginController controller;

  const LoginBottomSheet({super.key, required this.controller});

  @override
  State<LoginBottomSheet> createState() => _LoginBottomSheetState();
}

class _LoginBottomSheetState extends State<LoginBottomSheet> {
  final DraggableScrollableController _sheetController = DraggableScrollableController();
  bool _wasKeyboardOpen = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    if (isKeyboardOpen && !_wasKeyboardOpen) {
      _wasKeyboardOpen = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_sheetController.isAttached && mounted && _sheetController.size < 0.65) {
          _sheetController.animateTo(
            0.85,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } else if (!isKeyboardOpen && _wasKeyboardOpen) {
      _wasKeyboardOpen = false;
    }
  }

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: 0.45,
      minChildSize: 0.35,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        scrollController.addListener(() {
          if (widget.controller.showEmailInfo.value && scrollController.offset > 0) {
            widget.controller.showEmailInfo.value = false;
          }
        });

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppSizes.radiusXl),
            ),
          ),

          child: Obx(
            () => GestureDetector(
              behavior: HitTestBehavior.translucent,

              // ✅ เพิ่ม: กดตรงไหนก็ได้เพื่อปิด popup
              onTap: () {
                if (widget.controller.showEmailInfo.value) {
                  widget.controller.showEmailInfo.value = false;
                }
              },

              child: Stack(
                children: [
                  // ===== Main Form =====
                  ListView(
                    controller: scrollController,
                    padding: EdgeInsets.zero,
                    children: [
                      const SizedBox(height: 16),

                      // ===== Drag Handle =====
                      Padding(
                        padding: const EdgeInsets.only(top: 16, bottom: 16),
                        child: Center(
                          child: Container(
                            width: 48,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.black,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ===== Title =====
                      Text(
                        AppStrings.login,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.titleSemiBold.copyWith(
                          color: AppColors.primaryPalette[800],
                        ),
                      ),

                      const SizedBox(height: AppSizes.lg),

                      // ===== Email =====
                      TextField(
                        onChanged: (value) => widget.controller.email.value = value,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: AppStrings.email,
                          suffixIcon: IconButton(
                            icon: Icon(
                              LinkLianIcon.info,
                              size: 20,
                              color: AppColors.black,
                            ),
                            onPressed: () {
                              widget.controller.showEmailInfo.toggle();
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSizes.md),

                      // ===== Password =====
                      Obx(
                        () => TextField(
                          onChanged: (value) =>
                              widget.controller.password.value = value,
                          obscureText: widget.controller.obscurePassword.value,
                          decoration: InputDecoration(
                            labelText: AppStrings.password,
                            suffixIcon: IconButton(
                              icon: Icon(
                                widget.controller.obscurePassword.value
                                    ? LinkLianIcon.eyeOff
                                    : LinkLianIcon.eye,
                                color: AppColors.black,
                              ),
                              onPressed: () {
                                widget.controller.obscurePassword.value =
                                    !widget.controller.obscurePassword.value;
                              },
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSizes.sm),

                      // ===== Remember / Forgot =====
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Obx(
                                () => Checkbox(
                                  value: widget.controller.rememberMe.value,
                                  onChanged: (value) {
                                    widget.controller.rememberMe.value =
                                        value ?? false;
                                  },
                                  activeColor: AppColors.primaryPalette[600],
                                ),
                              ),
                              const SizedBox(width: AppSizes.xs),
                              Text(
                                AppStrings.rememberMe,
                                style: AppTextStyles.descriptionRegular,
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () {
                              Get.bottomSheet(
                                const ForgotPasswordBottomSheet(),
                                isScrollControlled: true,
                              );
                            },
                            child: Text(
                              AppStrings.forgotPassword,
                              style: AppTextStyles.descriptionSemiBold.copyWith(
                                color: AppColors.primaryPalette[800],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSizes.lg),

                      // ===== Submit =====
                      Obx(
                        () => ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryPalette[300],
                          ),
                          onPressed: widget.controller.isLoading.value
                              ? null
                              : widget.controller.submit,
                          child: widget.controller.isLoading.value
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.white,
                                  ),
                                )
                              : Text(
                                  AppStrings.login,
                                  style: AppTextStyles.subheadingSemiBold
                                      .copyWith(
                                        color: AppColors.primaryPalette[800],
                                      ),
                                ),
                        ),
                      ),

                      const SizedBox(height: AppSizes.xl),

                      // ===== OR Divider =====
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: AppColors.primaryPalette[300],
                              thickness: 1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            AppStrings.or,
                            style: AppTextStyles.descriptionRegular.copyWith(
                              color: AppColors.primaryPalette[600],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Divider(
                              color: AppColors.primaryPalette[300],
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSizes.lg),

                      // ===== Register =====
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            AppStrings.noAccount,
                            style: AppTextStyles.descriptionRegular,
                          ),
                          const SizedBox(width: AppSizes.xs),
                          Text(
                            AppStrings.registerHere,
                            style: AppTextStyles.descriptionSemiBold.copyWith(
                              color: AppColors.primaryPalette[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // ===== Info Popup (Stick กับ BottomSheet) =====
                  if (widget.controller.showEmailInfo.value)
                    Positioned(
                      top: 170,
                      right: 24,
                      child: const LoginInfoPopup(),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
