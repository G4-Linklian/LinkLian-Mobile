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

      // ✅ ต้อง reset password (flag_valid = false)
      if (result['require_reset_password'] == true) {
        Get.back(); // 👈 ปิด login sheet

        // 🔥 แสดงข้อความแจ้งเตือนก่อนเปิด reset password
        DialogHelper.showNotification(
          title: 'ต้องตั้งรหัสผ่านใหม่',
          message: 'กรุณาตั้งรหัสผ่านใหม่เพื่อความปลอดภัย',
          type: NotificationType.info,
        );

        // เปิด reset password bottom sheet
        Get.bottomSheet(
          ResetPasswordBottomSheet(email: email.value.trim()),
          isScrollControlled: true,
          isDismissible: false, // ✅ ไม่ให้ปิดได้จนกว่าจะ reset password
          enableDrag: false,
        );
        return;
      }

      // ต้อง OTP (ตรวจสอบว่ามี otp_session_id)
      if (result['otp_session_id'] != null) {
        Get.back();
        final otpSessionId = result['otp_session_id'];

        Get.put(
          OtpController(otpSessionId: otpSessionId, email: email.value.trim()),
        );

        DialogHelper.showOtpDialog();
        return;
      }

      // ===== login สำเร็จแบบไม่ต้อง OTP (มี valid token) =====
      if (result['access_token'] != null) {
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
      // 🔥 แปลง error message ให้เป็นภาษาไทยที่เข้าใจง่าย
      String errorMessage = _parseErrorMessage(e.toString());
      
      DialogHelper.showNotification(
        title: "เข้าสู่ระบบไม่สำเร็จ",
        message: errorMessage,
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

  /// 🔥 แปล error message เป็นภาษาไทย
  String _parseErrorMessage(String error) {
    final lowerError = error.toLowerCase();
    
    if (lowerError.contains('invalid credentials')) {
      return 'อีเมลหรือรหัสผ่านไม่ถูกต้อง';
    }
    
    if (lowerError.contains('role mismatch')) {
      return 'บัญชีนี้ไม่ใช่ ${selectedUserGroup.value == "student" ? "นักเรียน" : "ครู"}\nกรุณาเลือกประเภทผู้ใช้ที่ถูกต้อง';
    }
    
    if (lowerError.contains('user not found')) {
      return 'ไม่พบบัญชีผู้ใช้นี้ในระบบ';
    }
    
    if (lowerError.contains('email not found')) {
      return 'ไม่พบอีเมลนี้ในระบบ';
    }
    
    if (lowerError.contains('network') || lowerError.contains('connection')) {
      return 'ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้';
    }
    
    // ถ้าไม่ match อะไรเลย ให้แสดง error ดิบ
    return error.replaceAll('Exception: ', '');
  }
}
