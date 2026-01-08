import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/sizes.dart';
import '../../features/login/widgets/otp_popup.dart';

enum NotificationType { success, error, warning }

class DialogHelper {
  // ฟังก์ชันแสดง Error
  // static void showErrorDialog({String title = "Error", String description = "Something went wrong"}) {
  //   Get.defaultDialog(
  //     title: title,
  //     middleText: description,
  //     textConfirm: "OK",
  //     onConfirm: () => Get.back(),
  //   );
  // }

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
    }

    Get.snackbar(
      '', // title ว่างไว้
      '', // message ว่างไว้
      titleText: const SizedBox.shrink(),

      messageText: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(iconData, color: AppColors.white, size: 40),
            const SizedBox(height: 8),

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
              const SizedBox(height: 4),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.white, fontSize: 14),
              ),
            ],
          ],
        ),
      ),

      snackPosition: SnackPosition.TOP,
      backgroundColor: bgColor,
      borderRadius: 16,
      margin: const EdgeInsets.all(AppSizes.sm),
      // padding: const EdgeInsets.symmetric(
      //   vertical: AppSizes.lg,
      //   horizontal: AppSizes.xs,
      // ),
      isDismissible: true,
      duration: const Duration(seconds: 3),
      maxWidth: Get.width * 0.8,
      animationDuration: const Duration(milliseconds: 400),
      forwardAnimationCurve: Curves.fastLinearToSlowEaseIn,
      reverseAnimationCurve: Curves.linearToEaseOut,
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
      const OtpPopup(),
      barrierDismissible: false, // ❌ ห้ามกดปิดเอง
    );
  }

  static void showSelectUserGroupWarning() {
    showNotification(
      title: "กรุณาเลือกประเภทผู้ใช้",
      message: "กรุณาเลือกนักเรียนหรือครูก่อนเข้าสู่ระบบ",
      type: NotificationType.warning,
    );
  }
}
