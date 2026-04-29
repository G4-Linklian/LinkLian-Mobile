import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/sizes.dart';
import '../../features/login/controllers/otp_controller.dart';
import '../../features/login/widgets/otp_popup.dart';
import '../../features/classes/presentation/widgets/image_source_sheet.dart';
import '../../features/classes/presentation/widgets/link_attach_dialog.dart';

enum NotificationType { success, error, warning, info }

class DialogHelper {

  static void showErrorDialog({
    String title = "แจ้งเตือน",
    String description = "เกิดข้อผิดพลาด",
  }) {
    Get.defaultDialog(
      title: title,
      middleText: description,
      textConfirm: "ตกลง",
      confirmTextColor: AppColors.white,
      onConfirm: () => Get.back(),
      buttonColor: AppColors.buttonPalette[500],
      radius: 16,
    );
  }

  static void showNotification({
    String title = "แจ้งเตือน",
    String? message,
    NotificationType type = NotificationType.success,
    double titleSize = 24.0,
    Duration duration = const Duration(seconds: 2),
    String? actionLabel,
    VoidCallback? onAction,
    VoidCallback? onTap,
    bool compact = false,
  }) {
    Color bgColor;
    IconData iconData;

    switch (type) {
      case NotificationType.success:
        bgColor = AppColors.successPalette[600]!;
        iconData = Icons.check_circle_outline;
        break;
      case NotificationType.error:
        bgColor = AppColors.dangerPalette[400]!;
        iconData = Icons.highlight_off;
        break;
      case NotificationType.warning:
        bgColor = AppColors.warningPalette[500]!;
        iconData = Icons.warning_amber_rounded;
        break;
      case NotificationType.info:
        bgColor = AppColors.primaryPalette[500]!;
        iconData = Icons.info_outline;
        break;
    }

    Get.snackbar(
      '',
      '', 
      titleText: const SizedBox.shrink(),

      messageText: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(iconData, color: AppColors.white, size: compact ? 30 : 40),
            SizedBox(height: compact ? 4 : 8),

            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.white,
                fontSize: titleSize,
                fontWeight: FontWeight.bold,
              ),
            ),

            if (message != null && message.isNotEmpty) ...[
              SizedBox(height: compact ? 2 : 4),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: compact ? 12 : 14,
                ),
              ),
            ],
          ],
        ),
      ),

      snackPosition: SnackPosition.TOP,
      backgroundColor: bgColor,
      borderRadius: compact ? 12 : 16,
      margin: const EdgeInsets.all(AppSizes.sm),
      isDismissible: true,
      duration: duration,
      maxWidth: Get.width * (compact ? 0.66 : 0.8),
      animationDuration: const Duration(milliseconds: 400),
      forwardAnimationCurve: Curves.fastLinearToSlowEaseIn,
      reverseAnimationCurve: Curves.linearToEaseOut,
      onTap: (_) => onTap?.call(),
      mainButton: (actionLabel != null && onAction != null)
          ? TextButton(
              onPressed: onAction,
              child: Text(
                actionLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
    );
  }

  static void showLoading([String? message]) {
    Get.dialog(
      Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(message ?? 'Loading...'),
            ],
          ),
        ),
      ),
    );
  }

  // ฟังก์ชันปิด Dialog (ใช้คู่กับ showLoading)
  static void hideLoading() {
    if (Get.isDialogOpen!) Get.back();
  }

  static void showOtpDialog() {
    Get.dialog(
      OtpPopup(controller: Get.find<OtpController>()),
      barrierDismissible: false,
    );
  }

  static void showSelectUserGroupWarning() {
    showNotification(
      title: "กรุณาเลือกประเภทผู้ใช้",
      message: "กรุณาเลือกนักเรียนหรือครูก่อนเข้าสู่ระบบ",
      type: NotificationType.warning,
    );
  }

  static void showImageSourceSheet({
  required VoidCallback onCamera,
  required VoidCallback onGallery,
}) {
  Get.bottomSheet(
    ImageSourceSheet(
      onCamera: onCamera,
      onGallery: onGallery,
    ),
  );
}

static void showLinkDialog({
  required ValueChanged<String> onSubmit,
}) {
  Get.dialog(LinkAttachDialog(onSubmit: onSubmit));
}

}
