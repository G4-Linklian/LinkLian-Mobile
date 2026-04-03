import 'package:get/get.dart';
import '../../../core/utils/dialog_helper.dart';
import '../../../data/repository/auth_repository.dart';
import '../../../core/services/local_storage.dart';
import 'otp_controller.dart';
import '../../auth/controller/auth_controller.dart';
import '../../layout/controllers/navigation_controller.dart';

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
    //  guard: ต้องเลือก role
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

        // รองรับทั้ง int และ String
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

        final nav = Get.find<NavigationController>();

        nav.selectedIndex.value = 1; // เข้า class feed เสมอ
        nav.hideClassDetail();
        nav.hideCommunityDetail();
        nav.hideClassAssignment();

        return;
      }
    } catch (e) {
      // แปลง error message ให้เป็นภาษาไทยที่เข้าใจง่าย
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

  ///  Forgot password
  Future<void> forgotPassword() async {
    try {
      isLoading.value = true;

      await _authRepository.forgotPassword(email: email.value.trim());

      // ล้าง session เดิม (ถูกต้อง)
      await LocalStorage.clearAuthSession();

      DialogHelper.showNotification(
        title: 'ส่งรหัสผ่านชั่วคราวแล้ว',
        message: 'กรุณาตรวจสอบอีเมลและนำรหัสชั่วคราวมาเข้าสู่ระบบ',
        type: NotificationType.success,
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

  /// แปล error message เป็นภาษาไทยแบบสั้นกระชับ
  String _parseErrorMessage(String error) {
    final lowerError = error.toLowerCase();

    // ========== จัดการ DioException กับ HTTP Status Codes ==========

    // 401 Unauthorized - รหัสผ่านผิด หรือ credentials ไม่ถูกต้อง
    if (lowerError.contains('401')) {
      return 'อีเมลหรือรหัสผ่านไม่ถูกต้อง';
    }

    // 403 Forbidden - role mismatch
    if (lowerError.contains('403')) {
      return 'บัญชีนี้ไม่ใช่ ${selectedUserGroup.value == "student" ? "นักเรียน" : "ครู"}';
    }

    // 404 Not Found - user not found
    if (lowerError.contains('404')) {
      return 'ไม่พบบัญชีผู้ใช้นี้';
    }

    // 400 Bad Request
    if (lowerError.contains('400')) {
      return 'ข้อมูลไม่ถูกต้อง กรุณาตรวจสอบอีกครั้ง';
    }

    // 500 Internal Server Error
    if (lowerError.contains('500') ||
        lowerError.contains('502') ||
        lowerError.contains('503')) {
      return 'เซิร์ฟเวอร์ขัดข้อง กรุณาลองใหม่อีกครั้ง';
    }

    // ========== จัดการ Error Messages จาก Backend ==========

    if (lowerError.contains('invalid credentials')) {
      return 'อีเมลหรือรหัสผ่านไม่ถูกต้อง';
    }

    if (lowerError.contains('role mismatch')) {
      return 'บัญชีนี้ไม่ใช่ ${selectedUserGroup.value == "student" ? "นักเรียน" : "ครู"}';
    }

    if (lowerError.contains('user not found') ||
        lowerError.contains('email not found')) {
      return 'ไม่พบอีเมลนี้ในระบบ';
    }

    if (lowerError.contains('invalid password')) {
      return 'รหัสผ่านไม่ถูกต้อง';
    }

    if (lowerError.contains('account disabled') ||
        lowerError.contains('account locked')) {
      return 'บัญชีนี้ถูกระงับการใช้งาน';
    }

    // ========== จัดการ Network Errors ==========

    if (lowerError.contains('network') ||
        lowerError.contains('connection') ||
        lowerError.contains('timeout') ||
        lowerError.contains('failed host lookup')) {
      return 'ไม่สามารถเชื่อมต่ออินเทอร์เน็ตได้';
    }

    if (lowerError.contains('socket')) {
      return 'การเชื่อมต่อขัดข้อง กรุณาลองใหม่';
    }

    // ========== Default: แสดงข้อความสั้นๆ ==========

    // ถ้าไม่ match อะไรเลย แสดงข้อความทั่วไป
    return 'เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง';
  }
}
