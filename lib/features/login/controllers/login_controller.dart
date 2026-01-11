import 'package:get/get.dart';
import '../../../core/utils/dialog_helper.dart';
import '../../../data/repository/auth_repository.dart';
import '../../../core/services/local_storage.dart';
import '../widgets/re-password_bottom_sheet.dart';
import 'otp_controller.dart';
import '../../auth/controller/auth_controller.dart';

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
    final auth = Get.find<AuthController>();
    if (auth.isLoggedIn) {
      Get.back();
      return;
    }
    // 1️⃣ guard: ต้องเลือก role
    if (selectedUserGroup.value == null) {
      DialogHelper.showSelectUserGroupWarning();
      return;
    }

    try {
      isLoading.value = true;

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
        Get.back(); // 👈 ปิด login sheet

        Get.bottomSheet(
          ResetPasswordBottomSheet(email: email.value.trim()),
          isScrollControlled: true,
        );
        return;
      }
      // 2️⃣ role ไม่ตรง
      if (result['require_role_reselect'] == true) {
        DialogHelper.showNotification(
          title: 'เลือกประเภทผู้ใช้ไม่ตรง',
          message: 'กรุณาเลือกประเภทผู้ใช้ใหม่',
          type: NotificationType.warning,
        );
        selectedUserGroup.value = null;
        return;
      }

      // ต้อง OTP
      if (result['require_otp'] == true) {
        Get.back();
        final otpSessionId = result['otp_session_id'];

        Get.put(
          OtpController(otpSessionId: otpSessionId, email: email.value.trim()),
        );

        DialogHelper.showOtpDialog();
        return;
      }

      // ===== login สำเร็จแบบไม่ต้อง OTP =====
if (result['skip_otp'] == true) {
  Get.back();
  
  final token = result['access_token'] as String;
  
  // 🔥 รองรับทั้ง int และ String
  final userId = result['user_id'] is int 
      ? result['user_id'] as int
      : int.parse(result['user_id'].toString());
      
  final roleName = result['role_name'] as String;
  
  final instId = result['inst_id'] is int
      ? result['inst_id'] as int
      : int.parse(result['inst_id'].toString());

  await auth.establishSession(
    token: token,
    roleName: roleName,
    instId: instId,
    userId: userId,
  );

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

      await _authRepository.forgotPassword(email: email.value.trim());

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
