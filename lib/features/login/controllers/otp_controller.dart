import 'dart:async';
import 'package:get/get.dart';
import '../../../data/repository/auth_repository.dart';
import '../../../core/services/local_storage.dart';
import '../../../core/utils/dialog_helper.dart';
import '../../../core/utils/logger.dart';
import '../../auth/controller/auth_controller.dart';
import '../controllers/login_controller.dart';

class OtpController extends GetxController {
  final AuthRepository _authRepository = AuthRepository();

  final RxString otpSessionId;
  final String email;

  OtpController({required String otpSessionId, required this.email})
    : otpSessionId = otpSessionId.obs;

  static const int maxSeconds = 120;

  final otp = ''.obs;
  final secondsLeft = maxSeconds.obs;
  final isExpired = false.obs;
  final isLoading = false.obs;

  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    _startTimer();
  }

  // ================= TIMER =================
  void _startTimer() {
    secondsLeft.value = maxSeconds;
    isExpired.value = false;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secondsLeft.value <= 1) {
        timer.cancel();
        isExpired.value = true;
      } else {
        secondsLeft.value--;
      }
    });
  }

  // ================= UI HELPERS =================
  String get timeText {
    final m = (secondsLeft.value ~/ 60).toString().padLeft(2, '0');
    final s = (secondsLeft.value % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void onOtpChanged(String value) {
    if (value.length <= 6) {
      otp.value = value;
    }
  }

  Future<void> resendOtp() async {
    if (!isExpired.value) return;

    try {
      isLoading.value = true;

      final result = await _authRepository.resendOtp(
        otpSessionId: otpSessionId.value,
      );

      otpSessionId.value = result['otp_session_id'];

      otp.value = '';
      _startTimer();

      DialogHelper.showNotification(
        title: "ส่ง OTP ใหม่แล้ว",
        type: NotificationType.success,
      );
    } catch (e) {
      DialogHelper.showNotification(
        title: "ส่ง OTP ไม่สำเร็จ",
        message: e.toString(),
        type: NotificationType.error,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ================= SUBMIT OTP =================
  Future<void> submitOtp() async {
    final loginController = Get.find<LoginController>();
    final rememberMe = loginController.rememberMe.value;
    if (otp.value.length != 6 || isExpired.value) return;

    isLoading.value = true;
    try {
      final result = await _authRepository.verifyOtp(
        otp: otp.value,
        otpSessionId: otpSessionId.value,
        rememberMe: rememberMe,
      );

      final token = result['access_token'];
      if (token == null || token is! String) {
        throw Exception('Token missing from OTP response');
      }

      final int userId = int.parse(result['user_id'].toString());
      final int instId = int.parse(result['inst_id'].toString());
      final String roleName = result['role_name'];

      // 🔥 ส่งให้ AuthController คนเดียวดูแล session
      final authController = Get.find<AuthController>();
print('🧠 OTP using AuthController hash = ${authController.hashCode}');
      await authController.establishSession(
        token: token,
        userId: userId,
        instId: instId,
        roleName: roleName,
      );

      Get.back(); // ปิด dialog
      Get.delete<OtpController>();
      // Get.offAllNamed('/home');
    } catch (e) {
      DialogHelper.showNotification(
        title: "เกิดข้อผิดพลาด",
        message: e.toString(),
        type: NotificationType.error,
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}
