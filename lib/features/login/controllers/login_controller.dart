import 'package:get/get.dart';
import '../../../core/utils/dialog_helper.dart';
import '../../../data/repository/auth_repository.dart';
import '../../../core/services/local_storage.dart';
import '../widgets/re-password_bottom_sheet.dart';
import 'otp_controller.dart';

class LoginController extends GetxController {
  final AuthRepository _authRepository = AuthRepository();
  final selectedUserGroup = RxnString(); // 'student' | 'teacher'

  final showEmailInfo = false.obs;
  final obscurePassword = true.obs;
  final rememberMe = false.obs;

  final email = ''.obs;
  final password = ''.obs;
  final isLoading = false.obs;

  Future<void> submit() async {
    // 1️⃣ guard: ต้องเลือก role
    if (selectedUserGroup.value == null) {
      DialogHelper.showSelectUserGroupWarning();
      return;
    }

    try {
      isLoading.value = true;

      // ==============================
      // STEP 1: auto login ด้วย token
      // ==============================
      final token = await LocalStorage.getToken();
      final lastUserId = await LocalStorage.getLastLoginUserId();

      if (token != null && lastUserId != null) {
        try {
          final res = await _authRepository.verifyAuthContext();
          final int currentUserId =
              int.parse(res['data']['user_id'].toString());

          if (currentUserId == lastUserId) {
            Get.offAllNamed('/home');
            return;
          }
        } catch (_) {
          // token หมดอายุ → ไป login ปกติ
        }
      }

      // ==============================
      // STEP 2: login ด้วย email/password
      // ==============================
      final result = await _authRepository.login(
        email: email.value.trim(),
        password: password.value,
        userGroup: selectedUserGroup.value,
      );

      // ต้อง reset password
      if (result['require_reset_password'] == true) {
        Get.bottomSheet(
          ResetPasswordBottomSheet(email: email.value.trim()),
          isScrollControlled: true,
        );
        return;
      }

      // ต้อง OTP
      if (result['require_otp'] == true) {
        final otpSessionId = result['otp_session_id'];

        Get.put(
          OtpController(
            otpSessionId: otpSessionId,
            email: email.value.trim(),
          ),
        );

        DialogHelper.showOtpDialog();
        return;
      }

    } catch (e) {
      DialogHelper.showNotification(
        title: "เข้าสู่ระบบไม่สำเร็จ",
        message: e.toString(),
        type: NotificationType.error,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// 🔐 Forgot password
  Future<void> forgotPassword() async {
    try {
      isLoading.value = true;

      await _authRepository.forgotPassword(
        email: email.value.trim(),
      );

      // 🔥 ล้าง session เดิม (ถูกต้อง)
      await LocalStorage.clearAuthSession();

      DialogHelper.showNotification(
        title: 'ส่งรหัสผ่านชั่วคราวแล้ว',
        message: 'กรุณาตรวจสอบอีเมลของคุณ',
        type: NotificationType.success,
      );

      Get.bottomSheet(
        ResetPasswordBottomSheet(email: email.value.trim()),
        isScrollControlled: true,
      );
    } catch (e) {
      DialogHelper.showNotification(
        title: 'ไม่สำเร็จ',
        message: e.toString(),
        type: NotificationType.error,
      );
    } finally {
      isLoading.value = false;
    }
  }
}