import 'dart:async';
import 'package:get/get.dart';
import '../../../data/repository/auth_repository.dart';
import '../../../core/services/local_storage.dart';
import '../../../core/utils/dialog_helper.dart';

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
    if (otp.value.length != 6 || isExpired.value) return;

    isLoading.value = true;
    try {
      final result = await _authRepository.verifyOtp(
        otp: otp.value,
        otpSessionId: otpSessionId.value,
      );

      await LocalStorage.saveToken(result['token']);
      final int userId = int.parse(result['user_id'].toString());

      await LocalStorage.saveLastLoginUserId(userId);

      Get.back();
      Get.delete<OtpController>();
      Get.offAllNamed('/home');
    } catch (e) {
      DialogHelper.showNotification(
        title: "OTP ไม่ถูกต้อง",
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
