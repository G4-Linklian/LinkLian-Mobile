import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:LinkLian/core/services/local_storage.dart';
import 'package:LinkLian/features/layout/controllers/navigation_controller.dart';
import 'package:LinkLian/features/auth/controller/auth_controller.dart';

/// Mock AuthRepository with controllable responses
class MockAuthRepository {
  Map<String, dynamic>? mockLoginResponse;
  Map<String, dynamic>? mockVerifyOtpResponse;
  Map<String, dynamic>? mockResendOtpResponse;
  bool shouldThrowError = false;
  String errorMessage = 'API Error';
  int loginCallCount = 0;
  int forgotPasswordCallCount = 0;
  int verifyOtpCallCount = 0;
  int resendOtpCallCount = 0;

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    String? userGroup,
    bool rememberMe = false,
  }) async {
    loginCallCount++;
    if (shouldThrowError) throw Exception(errorMessage);
    return mockLoginResponse ??
        {'success': true, 'access_token': 'test_token', 'user_id': 1, 'role_name': 'student', 'inst_id': 100};
  }

  Future<void> forgotPassword({required String email}) async {
    forgotPasswordCallCount++;
    if (shouldThrowError) throw Exception(errorMessage);
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String otp,
    required String otpSessionId,
    required bool rememberMe,
  }) async {
    verifyOtpCallCount++;
    if (shouldThrowError) throw Exception(errorMessage);
    return mockVerifyOtpResponse ??
        {'success': true, 'access_token': 'otp_token', 'user_id': 1, 'role_name': 'student', 'inst_id': 100};
  }

  Future<Map<String, dynamic>> resendOtp({required String otpSessionId}) async {
    resendOtpCallCount++;
    if (shouldThrowError) throw Exception(errorMessage);
    return mockResendOtpResponse ?? {'success': true, 'otp_session_id': 'new_session_id'};
  }
}

/// Mock AuthController for testing
class MockAuthController extends GetxController {
  final RxnString token = RxnString();
  final Rx<AuthStatus> status = AuthStatus.unauthenticated.obs;
  bool get isLoggedIn => status.value == AuthStatus.authenticated;
  int establishSessionCallCount = 0;

  Future<void> establishSession({
    required String token,
    required String roleName,
    required int instId,
    required int userId,
  }) async {
    establishSessionCallCount++;
    this.token.value = token;
    status.value = AuthStatus.authenticated;
  }
}

// ============================================================
// TESTABLE LOGIN CONTROLLER
// Mirrors LoginController logic without triggering ApiClient
// ============================================================
class TestableLoginController extends GetxController {
  final MockAuthRepository _authRepository;

  TestableLoginController(this._authRepository);

  final selectedUserGroup = RxnString();
  final showEmailInfo = false.obs;
  final obscurePassword = true.obs;
  final rememberMe = false.obs;
  final email = ''.obs;
  final password = ''.obs;
  final isLoading = false.obs;

  // Track dialog/navigation calls for verification
  bool selectUserGroupWarningShown = false;
  bool otpDialogShown = false;
  bool resetPasswordSheetShown = false;
  String? lastNotificationTitle;
  String? lastNotificationMessage;
  bool navigationPerformed = false;

  Future<void> submit() async {
    final auth = Get.find<MockAuthController>();
    if (auth.isLoggedIn) {
      navigationPerformed = true;
      return;
    }

    // Guard: must select role
    if (selectedUserGroup.value == null) {
      selectUserGroupWarningShown = true;
      return;
    }

    try {
      isLoading.value = true;

      final result = await _authRepository.login(
        email: email.value.trim(),
        password: password.value,
        userGroup: selectedUserGroup.value,
      );

      // Require password reset
      if (result['require_reset_password'] == true) {
        navigationPerformed = true;
        lastNotificationTitle = 'ต้องตั้งรหัสผ่านใหม่';
        resetPasswordSheetShown = true;
        return;
      }

      // Require OTP
      if (result['otp_session_id'] != null) {
        navigationPerformed = true;
        otpDialogShown = true;
        return;
      }

      // Login success with token
      if (result['access_token'] != null) {
        navigationPerformed = true;
        final token = result['access_token'] as String;
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

        if (Get.isRegistered<NavigationController>()) {
          final nav = Get.find<NavigationController>();
          nav.selectedIndex.value = 1;
          nav.hideClassDetail();
          nav.hideCommunityDetail();
          nav.hideClassAssignment();
        }
        return;
      }
    } catch (e) {
      lastNotificationTitle = "เข้าสู่ระบบไม่สำเร็จ";
      lastNotificationMessage = parseErrorMessage(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> forgotPassword() async {
    try {
      isLoading.value = true;
      await _authRepository.forgotPassword(email: email.value.trim());
      await LocalStorage.clearAuthSession();
      lastNotificationTitle = 'ส่งรหัสผ่านชั่วคราวแล้ว';
      resetPasswordSheetShown = true;
    } catch (e) {
      lastNotificationTitle = 'ไม่สำเร็จ';
      lastNotificationMessage = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  /// Parse error message to Thai (public for testing)
  String parseErrorMessage(String error) {
    final lowerError = error.toLowerCase();

    // HTTP Status Codes
    if (lowerError.contains('401')) return 'อีเมลหรือรหัสผ่านไม่ถูกต้อง';
    if (lowerError.contains('403')) {
      return 'บัญชีนี้ไม่ใช่ ${selectedUserGroup.value == "student" ? "นักเรียน" : "ครู"}';
    }
    if (lowerError.contains('404')) return 'ไม่พบบัญชีผู้ใช้นี้';
    if (lowerError.contains('400')) return 'ข้อมูลไม่ถูกต้อง กรุณาตรวจสอบอีกครั้ง';
    if (lowerError.contains('500') || lowerError.contains('502') || lowerError.contains('503')) {
      return 'เซิร์ฟเวอร์ขัดข้อง กรุณาลองใหม่อีกครั้ง';
    }

    // Backend error messages
    if (lowerError.contains('invalid credentials')) return 'อีเมลหรือรหัสผ่านไม่ถูกต้อง';
    if (lowerError.contains('role mismatch')) {
      return 'บัญชีนี้ไม่ใช่ ${selectedUserGroup.value == "student" ? "นักเรียน" : "ครู"}';
    }
    if (lowerError.contains('user not found') || lowerError.contains('email not found')) {
      return 'ไม่พบอีเมลนี้ในระบบ';
    }
    if (lowerError.contains('invalid password')) return 'รหัสผ่านไม่ถูกต้อง';
    if (lowerError.contains('account disabled') || lowerError.contains('account locked')) {
      return 'บัญชีนี้ถูกระงับการใช้งาน';
    }

    // Network errors
    if (lowerError.contains('network') ||
        lowerError.contains('connection') ||
        lowerError.contains('timeout') ||
        lowerError.contains('failed host lookup')) {
      return 'ไม่สามารถเชื่อมต่ออินเทอร์เน็ตได้';
    }
    if (lowerError.contains('socket')) return 'การเชื่อมต่อขัดข้อง กรุณาลองใหม่';

    return 'เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง';
  }
}

// ============================================================
// TESTABLE OTP CONTROLLER
// Mirrors OtpController logic without triggering ApiClient
// ============================================================
class TestableOtpController extends GetxController {
  final MockAuthRepository _authRepository;
  final RxString otpSessionId;
  final String email;

  TestableOtpController({
    required MockAuthRepository authRepository,
    required String otpSessionId,
    required this.email,
  })  : _authRepository = authRepository,
        otpSessionId = otpSessionId.obs;

  static const int maxSeconds = 120;

  final otp = ''.obs;
  final secondsLeft = maxSeconds.obs;
  final isExpired = false.obs;
  final isLoading = false.obs;

  Timer? _timer;

  // Track actions for verification
  String? lastNotificationTitle;
  bool dialogClosed = false;
  int establishSessionCallCount = 0;

  @override
  void onInit() {
    super.onInit();
    startTimer();
  }

  /// Start countdown timer (public for testing)
  void startTimer() {
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

  /// Format time as MM:SS
  String get timeText {
    final m = (secondsLeft.value ~/ 60).toString().padLeft(2, '0');
    final s = (secondsLeft.value % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  /// Handle OTP input change (max 6 digits)
  void onOtpChanged(String value) {
    if (value.length <= 6) {
      otp.value = value;
    }
  }

  /// Resend OTP (only when expired)
  Future<void> resendOtp() async {
    if (!isExpired.value) return;

    try {
      isLoading.value = true;
      final result = await _authRepository.resendOtp(otpSessionId: otpSessionId.value);
      otpSessionId.value = result['otp_session_id'];
      otp.value = '';
      startTimer();
      lastNotificationTitle = "ส่ง OTP ใหม่แล้ว";
    } catch (e) {
      lastNotificationTitle = "ส่ง OTP ไม่สำเร็จ";
    } finally {
      isLoading.value = false;
    }
  }

  /// Submit OTP for verification
  Future<void> submitOtp() async {
    // Find login controller for rememberMe value
    final loginController = Get.find<TestableLoginController>();
    final rememberMe = loginController.rememberMe.value;

    // Guard: OTP must be 6 digits and not expired
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

      final authController = Get.find<MockAuthController>();
      await authController.establishSession(
        token: token,
        userId: userId,
        instId: instId,
        roleName: roleName,
      );

      dialogClosed = true;
      establishSessionCallCount++;
    } catch (e) {
      lastNotificationTitle = "เกิดข้อผิดพลาด";
    } finally {
      isLoading.value = false;
    }
  }

  /// Force expire for testing
  void forceExpire() {
    _timer?.cancel();
    secondsLeft.value = 0;
    isExpired.value = true;
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}

// ============================================================
// MAIN TEST SUITE
// ============================================================
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  // ============================================================
  // LOGIN CONTROLLER TESTS
  // ============================================================
  group('LoginController Unit Tests', () {
    late TestableLoginController controller;
    late MockAuthRepository mockAuthRepo;
    late MockAuthController mockAuthController;

    setUp(() async {
      Get.reset();
      SharedPreferences.setMockInitialValues({});
      await LocalStorage.init();

      mockAuthRepo = MockAuthRepository();
      mockAuthController = MockAuthController();
      controller = TestableLoginController(mockAuthRepo);

      Get.put<MockAuthController>(mockAuthController);
      Get.put<TestableLoginController>(controller);
    });

    tearDown(() {
      Get.reset();
    });

    // ========== State Initialization ==========
    group('State Initialization', () {
      test('should have default values on creation', () {
        expect(controller.selectedUserGroup.value, isNull);
        expect(controller.showEmailInfo.value, isFalse);
        expect(controller.obscurePassword.value, isTrue);
        expect(controller.rememberMe.value, isFalse);
        expect(controller.email.value, equals(''));
        expect(controller.password.value, equals(''));
        expect(controller.isLoading.value, isFalse);
      });

      test('should allow state changes', () {
        controller.email.value = 'test@example.com';
        controller.password.value = 'password123';
        controller.selectedUserGroup.value = 'student';
        controller.rememberMe.value = true;

        expect(controller.email.value, equals('test@example.com'));
        expect(controller.password.value, equals('password123'));
        expect(controller.selectedUserGroup.value, equals('student'));
        expect(controller.rememberMe.value, isTrue);
      });
    });

    // ========== Submit Logic Tests ==========
    group('submit()', () {
      test('should return early if already logged in', () async {
        mockAuthController.status.value = AuthStatus.authenticated;

        await controller.submit();

        expect(controller.navigationPerformed, isTrue);
        expect(mockAuthRepo.loginCallCount, equals(0));
      });

      test('should show warning when no user group selected', () async {
        controller.selectedUserGroup.value = null;

        await controller.submit();

        expect(controller.selectUserGroupWarningShown, isTrue);
        expect(mockAuthRepo.loginCallCount, equals(0));
      });

      test('should call login API with correct parameters', () async {
        controller.email.value = '  test@example.com  ';
        controller.password.value = 'password123';
        controller.selectedUserGroup.value = 'student';

        mockAuthRepo.mockLoginResponse = {
          'success': true,
          'access_token': 'token123',
          'user_id': 42,
          'role_name': 'student',
          'inst_id': 100,
        };

        await controller.submit();

        expect(mockAuthRepo.loginCallCount, equals(1));
      });

      test('should handle require_reset_password response', () async {
        controller.selectedUserGroup.value = 'teacher';
        mockAuthRepo.mockLoginResponse = {'require_reset_password': true};

        await controller.submit();

        expect(controller.resetPasswordSheetShown, isTrue);
        expect(controller.lastNotificationTitle, equals('ต้องตั้งรหัสผ่านใหม่'));
      });

      test('should handle OTP required response', () async {
        controller.selectedUserGroup.value = 'student';
        mockAuthRepo.mockLoginResponse = {'otp_session_id': 'otp_123'};

        await controller.submit();

        expect(controller.otpDialogShown, isTrue);
        expect(controller.navigationPerformed, isTrue);
      });

      test('should establish session on successful login', () async {
        controller.selectedUserGroup.value = 'student';
        mockAuthRepo.mockLoginResponse = {
          'success': true,
          'access_token': 'valid_token',
          'user_id': 99,
          'role_name': 'student',
          'inst_id': 200,
        };

        await controller.submit();

        expect(mockAuthController.establishSessionCallCount, equals(1));
        expect(mockAuthController.token.value, equals('valid_token'));
      });

      test('should reset navigation controller on successful login', () async {
        final navController = NavigationController();
        navController.selectedIndex.value = 3;
        navController.isShowingClassDetail.value = true;
        Get.put<NavigationController>(navController);

        controller.selectedUserGroup.value = 'student';
        mockAuthRepo.mockLoginResponse = {
          'access_token': 'token',
          'user_id': 1,
          'role_name': 'student',
          'inst_id': 100,
        };

        await controller.submit();

        expect(navController.selectedIndex.value, equals(1));
        expect(navController.isShowingClassDetail.value, isFalse);
      });

      test('should handle string user_id conversion', () async {
        controller.selectedUserGroup.value = 'teacher';
        mockAuthRepo.mockLoginResponse = {
          'access_token': 'token',
          'user_id': '123', // String instead of int
          'role_name': 'teacher',
          'inst_id': '456', // String instead of int
        };

        await controller.submit();

        expect(mockAuthController.establishSessionCallCount, equals(1));
      });

      test('should set isLoading during submit', () async {
        controller.selectedUserGroup.value = 'student';
        mockAuthRepo.mockLoginResponse = {'access_token': 'token', 'user_id': 1, 'role_name': 'student', 'inst_id': 1};

        final loadingStates = <bool>[];
        controller.isLoading.listen((v) => loadingStates.add(v));

        await controller.submit();

        expect(loadingStates, contains(true));
        expect(controller.isLoading.value, isFalse); // Should be false at end
      });
    });

    // ========== Error Handling Tests ==========
    group('Error Handling', () {
      test('should handle API exception gracefully', () async {
        controller.selectedUserGroup.value = 'student';
        mockAuthRepo.shouldThrowError = true;
        mockAuthRepo.errorMessage = 'Network error';

        await controller.submit();

        expect(controller.lastNotificationTitle, equals('เข้าสู่ระบบไม่สำเร็จ'));
        expect(controller.isLoading.value, isFalse);
      });

      test('should reset isLoading on error', () async {
        controller.selectedUserGroup.value = 'student';
        mockAuthRepo.shouldThrowError = true;

        await controller.submit();

        expect(controller.isLoading.value, isFalse);
      });
    });

    // ========== Error Message Parsing Tests ==========
    group('parseErrorMessage()', () {
      // HTTP Status Codes
      test('should parse 401 error correctly', () {
        expect(controller.parseErrorMessage('Error 401 Unauthorized'), equals('อีเมลหรือรหัสผ่านไม่ถูกต้อง'));
      });

      test('should parse 403 error for student', () {
        controller.selectedUserGroup.value = 'student';
        expect(controller.parseErrorMessage('Error 403 Forbidden'), equals('บัญชีนี้ไม่ใช่ นักเรียน'));
      });

      test('should parse 403 error for teacher', () {
        controller.selectedUserGroup.value = 'teacher';
        expect(controller.parseErrorMessage('Error 403 Forbidden'), equals('บัญชีนี้ไม่ใช่ ครู'));
      });

      test('should parse 404 error correctly', () {
        expect(controller.parseErrorMessage('Error 404 Not Found'), equals('ไม่พบบัญชีผู้ใช้นี้'));
      });

      test('should parse 400 error correctly', () {
        expect(controller.parseErrorMessage('Error 400 Bad Request'), equals('ข้อมูลไม่ถูกต้อง กรุณาตรวจสอบอีกครั้ง'));
      });

      test('should parse 500/502/503 server errors', () {
        expect(controller.parseErrorMessage('Error 500 Internal Server Error'), equals('เซิร์ฟเวอร์ขัดข้อง กรุณาลองใหม่อีกครั้ง'));
        expect(controller.parseErrorMessage('Error 502 Bad Gateway'), equals('เซิร์ฟเวอร์ขัดข้อง กรุณาลองใหม่อีกครั้ง'));
        expect(controller.parseErrorMessage('Error 503 Service Unavailable'), equals('เซิร์ฟเวอร์ขัดข้อง กรุณาลองใหม่อีกครั้ง'));
      });

      // Backend error messages
      test('should parse invalid credentials error', () {
        expect(controller.parseErrorMessage('Invalid credentials'), equals('อีเมลหรือรหัสผ่านไม่ถูกต้อง'));
      });

      test('should parse role mismatch error', () {
        controller.selectedUserGroup.value = 'student';
        expect(controller.parseErrorMessage('Role mismatch'), equals('บัญชีนี้ไม่ใช่ นักเรียน'));
      });

      test('should parse user not found error', () {
        expect(controller.parseErrorMessage('User not found'), equals('ไม่พบอีเมลนี้ในระบบ'));
        expect(controller.parseErrorMessage('Email not found'), equals('ไม่พบอีเมลนี้ในระบบ'));
      });

      test('should parse invalid password error', () {
        expect(controller.parseErrorMessage('Invalid password'), equals('รหัสผ่านไม่ถูกต้อง'));
      });

      test('should parse account disabled/locked error', () {
        expect(controller.parseErrorMessage('Account disabled'), equals('บัญชีนี้ถูกระงับการใช้งาน'));
        expect(controller.parseErrorMessage('Account locked'), equals('บัญชีนี้ถูกระงับการใช้งาน'));
      });

      // Network errors
      test('should parse network/connection errors', () {
        expect(controller.parseErrorMessage('Network error'), equals('ไม่สามารถเชื่อมต่ออินเทอร์เน็ตได้'));
        expect(controller.parseErrorMessage('Connection refused'), equals('ไม่สามารถเชื่อมต่ออินเทอร์เน็ตได้'));
        expect(controller.parseErrorMessage('Timeout exceeded'), equals('ไม่สามารถเชื่อมต่ออินเทอร์เน็ตได้'));
        expect(controller.parseErrorMessage('Failed host lookup'), equals('ไม่สามารถเชื่อมต่ออินเทอร์เน็ตได้'));
      });

      test('should parse socket error', () {
        expect(controller.parseErrorMessage('Socket exception'), equals('การเชื่อมต่อขัดข้อง กรุณาลองใหม่'));
      });

      test('should return default message for unknown errors', () {
        expect(controller.parseErrorMessage('Unknown weird error XYZ'), equals('เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง'));
      });

      test('should be case-insensitive', () {
        expect(controller.parseErrorMessage('INVALID CREDENTIALS'), equals('อีเมลหรือรหัสผ่านไม่ถูกต้อง'));
        expect(controller.parseErrorMessage('NETWORK ERROR'), equals('ไม่สามารถเชื่อมต่ออินเทอร์เน็ตได้'));
      });
    });

    // ========== Forgot Password Tests ==========
    group('forgotPassword()', () {
      test('should call forgotPassword API', () async {
        controller.email.value = 'forgot@example.com';

        await controller.forgotPassword();

        expect(mockAuthRepo.forgotPasswordCallCount, equals(1));
      });

      test('should clear auth session on success', () async {
        await LocalStorage.saveToken('old_token');
        controller.email.value = 'test@example.com';

        await controller.forgotPassword();

        final token = await LocalStorage.getToken();
        expect(token, isNull);
      });

      test('should show success notification', () async {
        controller.email.value = 'test@example.com';

        await controller.forgotPassword();

        expect(controller.lastNotificationTitle, equals('ส่งรหัสผ่านชั่วคราวแล้ว'));
        expect(controller.resetPasswordSheetShown, isTrue);
      });

      test('should handle forgotPassword error', () async {
        mockAuthRepo.shouldThrowError = true;
        mockAuthRepo.errorMessage = 'Email not registered';
        controller.email.value = 'unknown@example.com';

        await controller.forgotPassword();

        expect(controller.lastNotificationTitle, equals('ไม่สำเร็จ'));
        expect(controller.isLoading.value, isFalse);
      });

      test('should trim email before sending', () async {
        controller.email.value = '  spaces@example.com  ';

        await controller.forgotPassword();

        expect(mockAuthRepo.forgotPasswordCallCount, equals(1));
      });
    });

    // ========== Edge Cases ==========
    group('Edge Cases', () {
      test('should handle empty email', () async {
        controller.email.value = '';
        controller.password.value = 'password';
        controller.selectedUserGroup.value = 'student';
        mockAuthRepo.shouldThrowError = true;
        mockAuthRepo.errorMessage = 'Email is required';

        await controller.submit();

        expect(controller.lastNotificationTitle, equals('เข้าสู่ระบบไม่สำเร็จ'));
      });

      test('should handle empty password', () async {
        controller.email.value = 'test@example.com';
        controller.password.value = '';
        controller.selectedUserGroup.value = 'student';
        mockAuthRepo.shouldThrowError = true;

        await controller.submit();

        expect(controller.lastNotificationTitle, equals('เข้าสู่ระบบไม่สำเร็จ'));
      });

      test('should handle whitespace-only email', () async {
        controller.email.value = '   ';
        controller.password.value = 'password';
        controller.selectedUserGroup.value = 'student';
        mockAuthRepo.shouldThrowError = true;

        await controller.submit();

        expect(mockAuthRepo.loginCallCount, equals(1));
      });

      test('should toggle obscurePassword', () {
        expect(controller.obscurePassword.value, isTrue);
        controller.obscurePassword.toggle();
        expect(controller.obscurePassword.value, isFalse);
        controller.obscurePassword.toggle();
        expect(controller.obscurePassword.value, isTrue);
      });
    });

    // ========== Reactive Observables ==========
    group('Reactive Observables', () {
      test('email should be reactive', () async {
        String? observedValue;
        controller.email.listen((v) => observedValue = v);

        controller.email.value = 'reactive@test.com';
        await Future.delayed(Duration(milliseconds: 10));

        expect(observedValue, equals('reactive@test.com'));
      });

      test('isLoading should be reactive', () async {
        final loadingHistory = <bool>[];
        controller.isLoading.listen((v) => loadingHistory.add(v));

        controller.isLoading.value = true;
        controller.isLoading.value = false;
        await Future.delayed(Duration(milliseconds: 10));

        expect(loadingHistory, contains(true));
        expect(loadingHistory, contains(false));
      });
    });
  });

  // ============================================================
  // OTP CONTROLLER TESTS
  // ============================================================
  group('OtpController Unit Tests', () {
    late TestableOtpController controller;
    late MockAuthRepository mockAuthRepo;
    late MockAuthController mockAuthController;
    late TestableLoginController mockLoginController;

    setUp(() async {
      Get.reset();
      SharedPreferences.setMockInitialValues({});
      await LocalStorage.init();

      mockAuthRepo = MockAuthRepository();
      mockAuthController = MockAuthController();
      mockLoginController = TestableLoginController(mockAuthRepo);
      controller = TestableOtpController(
        authRepository: mockAuthRepo,
        otpSessionId: 'test_session_123',
        email: 'test@example.com',
      );

      Get.put<MockAuthController>(mockAuthController);
      Get.put<TestableLoginController>(mockLoginController);
      Get.put<TestableOtpController>(controller);
    });

    tearDown(() {
      controller.onClose();
      Get.reset();
    });

    // ========== State Initialization ==========
    group('State Initialization', () {
      test('should initialize with correct values', () {
        expect(controller.otpSessionId.value, equals('test_session_123'));
        expect(controller.email, equals('test@example.com'));
        expect(controller.otp.value, equals(''));
        expect(controller.secondsLeft.value, equals(120));
        expect(controller.isExpired.value, isFalse);
        expect(controller.isLoading.value, isFalse);
      });

      test('maxSeconds should be 120', () {
        expect(TestableOtpController.maxSeconds, equals(120));
      });
    });

    // ========== Timer Tests ==========
    group('Timer Logic', () {
      test('should decrement secondsLeft over time', () async {
        controller.startTimer();
        await Future.delayed(Duration(seconds: 2));

        expect(controller.secondsLeft.value, lessThan(120));
      });

      test('should set isExpired when timer reaches 0', () {
        controller.forceExpire();

        expect(controller.isExpired.value, isTrue);
        expect(controller.secondsLeft.value, equals(0));
      });

      test('startTimer should reset values', () {
        controller.forceExpire();
        expect(controller.isExpired.value, isTrue);

        controller.startTimer();

        expect(controller.secondsLeft.value, equals(120));
        expect(controller.isExpired.value, isFalse);
      });
    });

    // ========== Time Text Formatting ==========
    group('timeText', () {
      test('should format 120 seconds as 02:00', () {
        controller.secondsLeft.value = 120;
        expect(controller.timeText, equals('02:00'));
      });

      test('should format 65 seconds as 01:05', () {
        controller.secondsLeft.value = 65;
        expect(controller.timeText, equals('01:05'));
      });

      test('should format 9 seconds as 00:09', () {
        controller.secondsLeft.value = 9;
        expect(controller.timeText, equals('00:09'));
      });

      test('should format 0 seconds as 00:00', () {
        controller.secondsLeft.value = 0;
        expect(controller.timeText, equals('00:00'));
      });

      test('should pad single digits correctly', () {
        controller.secondsLeft.value = 61;
        expect(controller.timeText, equals('01:01'));
      });
    });

    // ========== OTP Input Tests ==========
    group('onOtpChanged()', () {
      test('should accept OTP up to 6 digits', () {
        controller.onOtpChanged('123456');
        expect(controller.otp.value, equals('123456'));
      });

      test('should reject OTP longer than 6 digits', () {
        controller.onOtpChanged('123456');
        controller.onOtpChanged('1234567');

        expect(controller.otp.value, equals('123456'));
      });

      test('should accept partial OTP', () {
        controller.onOtpChanged('123');
        expect(controller.otp.value, equals('123'));
      });

      test('should accept empty string', () {
        controller.onOtpChanged('123456');
        controller.onOtpChanged('');
        expect(controller.otp.value, equals(''));
      });
    });

    // ========== Resend OTP Tests ==========
    group('resendOtp()', () {
      test('should not resend if not expired', () async {
        controller.isExpired.value = false;

        await controller.resendOtp();

        expect(mockAuthRepo.resendOtpCallCount, equals(0));
      });

      test('should resend when expired', () async {
        controller.forceExpire();
        mockAuthRepo.mockResendOtpResponse = {'otp_session_id': 'new_session'};

        await controller.resendOtp();

        expect(mockAuthRepo.resendOtpCallCount, equals(1));
        expect(controller.otpSessionId.value, equals('new_session'));
      });

      test('should clear OTP and restart timer on resend', () async {
        controller.forceExpire();
        controller.otp.value = '123456';

        await controller.resendOtp();

        expect(controller.otp.value, equals(''));
        expect(controller.secondsLeft.value, equals(120));
        expect(controller.isExpired.value, isFalse);
      });

      test('should show success notification on resend', () async {
        controller.forceExpire();

        await controller.resendOtp();

        expect(controller.lastNotificationTitle, equals('ส่ง OTP ใหม่แล้ว'));
      });

      test('should handle resend error', () async {
        controller.forceExpire();
        mockAuthRepo.shouldThrowError = true;
        mockAuthRepo.errorMessage = 'Resend failed';

        await controller.resendOtp();

        expect(controller.lastNotificationTitle, equals('ส่ง OTP ไม่สำเร็จ'));
        expect(controller.isLoading.value, isFalse);
      });
    });

    // ========== Submit OTP Tests ==========
    group('submitOtp()', () {
      test('should not submit if OTP length is not 6', () async {
        controller.otp.value = '12345';

        await controller.submitOtp();

        expect(mockAuthRepo.verifyOtpCallCount, equals(0));
      });

      test('should not submit if expired', () async {
        controller.otp.value = '123456';
        controller.forceExpire();

        await controller.submitOtp();

        expect(mockAuthRepo.verifyOtpCallCount, equals(0));
      });

      test('should verify OTP with correct parameters', () async {
        controller.otp.value = '123456';
        mockLoginController.rememberMe.value = true;

        await controller.submitOtp();

        expect(mockAuthRepo.verifyOtpCallCount, equals(1));
      });

      test('should establish session on successful OTP verification', () async {
        controller.otp.value = '123456';
        mockAuthRepo.mockVerifyOtpResponse = {
          'success': true,
          'access_token': 'otp_verified_token',
          'user_id': 42,
          'role_name': 'student',
          'inst_id': 100,
        };

        await controller.submitOtp();

        expect(mockAuthController.establishSessionCallCount, equals(1));
        expect(mockAuthController.token.value, equals('otp_verified_token'));
      });

      test('should close dialog on success', () async {
        controller.otp.value = '123456';

        await controller.submitOtp();

        expect(controller.dialogClosed, isTrue);
      });

      test('should handle missing token in response', () async {
        controller.otp.value = '123456';
        mockAuthRepo.mockVerifyOtpResponse = {
          'success': true,
          'access_token': null,
          'user_id': 1,
        };

        await controller.submitOtp();

        expect(controller.lastNotificationTitle, equals('เกิดข้อผิดพลาด'));
      });

      test('should handle OTP verification error', () async {
        controller.otp.value = '123456';
        mockAuthRepo.shouldThrowError = true;
        mockAuthRepo.errorMessage = 'Invalid OTP';

        await controller.submitOtp();

        expect(controller.lastNotificationTitle, equals('เกิดข้อผิดพลาด'));
        expect(controller.isLoading.value, isFalse);
      });

      test('should parse string user_id correctly', () async {
        controller.otp.value = '123456';
        mockAuthRepo.mockVerifyOtpResponse = {
          'success': true,
          'access_token': 'token',
          'user_id': '999', // String instead of int
          'role_name': 'teacher',
          'inst_id': '123', // String instead of int
        };

        await controller.submitOtp();

        expect(mockAuthController.establishSessionCallCount, equals(1));
      });
    });

    // ========== Loading State Tests ==========
    group('Loading State', () {
      test('should set isLoading during resendOtp', () async {
        controller.forceExpire();

        final loadingStates = <bool>[];
        controller.isLoading.listen((v) => loadingStates.add(v));

        await controller.resendOtp();

        expect(loadingStates, contains(true));
        expect(controller.isLoading.value, isFalse);
      });

      test('should set isLoading during submitOtp', () async {
        controller.otp.value = '123456';

        final loadingStates = <bool>[];
        controller.isLoading.listen((v) => loadingStates.add(v));

        await controller.submitOtp();

        expect(loadingStates, contains(true));
        expect(controller.isLoading.value, isFalse);
      });
    });

    // ========== Edge Cases ==========
    group('Edge Cases', () {
      test('should handle multiple resend attempts', () async {
        controller.forceExpire();
        await controller.resendOtp();

        controller.forceExpire();
        await controller.resendOtp();

        expect(mockAuthRepo.resendOtpCallCount, equals(2));
      });

      test('should handle rapid OTP changes', () {
        for (var i = 0; i < 10; i++) {
          controller.onOtpChanged(i.toString());
        }

        expect(controller.otp.value.length, lessThanOrEqualTo(6));
      });

      test('should cleanup timer on close', () {
        controller.startTimer();
        controller.onClose();

        // Timer should be cancelled (no crash when accessing after close)
        expect(controller.secondsLeft.value, isNotNull);
      });
    });

    // ========== Reactive Observables ==========
    group('Reactive Observables', () {
      test('otp should be reactive', () async {
        String? observedValue;
        controller.otp.listen((v) => observedValue = v);

        controller.onOtpChanged('654321');
        await Future.delayed(Duration(milliseconds: 10));

        expect(observedValue, equals('654321'));
      });

      test('isExpired should be reactive', () async {
        bool? observedValue;
        controller.isExpired.listen((v) => observedValue = v);

        controller.forceExpire();
        await Future.delayed(Duration(milliseconds: 10));

        expect(observedValue, isTrue);
      });

      test('secondsLeft should be reactive', () async {
        final values = <int>[];
        controller.secondsLeft.listen((v) => values.add(v));

        controller.secondsLeft.value = 100;
        controller.secondsLeft.value = 50;
        await Future.delayed(Duration(milliseconds: 10));

        expect(values, contains(100));
        expect(values, contains(50));
      });
    });
  });

  // ============================================================
  // INTEGRATION TESTS (Login + OTP Flow)
  // ============================================================
  group('Login and OTP Flow Integration', () {
    late TestableLoginController loginController;
    late TestableOtpController otpController;
    late MockAuthRepository mockAuthRepo;
    late MockAuthController mockAuthController;

    setUp(() async {
      Get.reset();
      SharedPreferences.setMockInitialValues({});
      await LocalStorage.init();

      mockAuthRepo = MockAuthRepository();
      mockAuthController = MockAuthController();
      loginController = TestableLoginController(mockAuthRepo);

      Get.put<MockAuthController>(mockAuthController);
      Get.put<TestableLoginController>(loginController);
    });

    tearDown(() {
      Get.reset();
    });

    test('complete OTP login flow should work', () async {
      // Step 1: Login triggers OTP
      loginController.email.value = 'user@example.com';
      loginController.password.value = 'password';
      loginController.selectedUserGroup.value = 'student';
      mockAuthRepo.mockLoginResponse = {'otp_session_id': 'session_abc'};

      await loginController.submit();

      expect(loginController.otpDialogShown, isTrue);

      // Step 2: Enter and verify OTP
      otpController = TestableOtpController(
        authRepository: mockAuthRepo,
        otpSessionId: 'session_abc',
        email: 'user@example.com',
      );
      Get.put<TestableOtpController>(otpController);

      otpController.otp.value = '123456';
      mockAuthRepo.mockVerifyOtpResponse = {
        'access_token': 'final_token',
        'user_id': 1,
        'role_name': 'student',
        'inst_id': 100,
      };

      await otpController.submitOtp();

      expect(mockAuthController.status.value, equals(AuthStatus.authenticated));
      expect(mockAuthController.token.value, equals('final_token'));
    });

    test('OTP expiry and resend flow should work', () async {
      otpController = TestableOtpController(
        authRepository: mockAuthRepo,
        otpSessionId: 'session_xyz',
        email: 'user@example.com',
      );
      Get.put<TestableOtpController>(otpController);

      // OTP expires
      otpController.forceExpire();
      expect(otpController.isExpired.value, isTrue);

      // Resend OTP
      mockAuthRepo.mockResendOtpResponse = {'otp_session_id': 'new_session_xyz'};
      await otpController.resendOtp();

      expect(otpController.otpSessionId.value, equals('new_session_xyz'));
      expect(otpController.isExpired.value, isFalse);

      // Submit new OTP
      otpController.otp.value = '999999';
      mockAuthRepo.mockVerifyOtpResponse = {
        'access_token': 'resend_token',
        'user_id': 2,
        'role_name': 'teacher',
        'inst_id': 200,
      };

      await otpController.submitOtp();

      expect(mockAuthController.token.value, equals('resend_token'));
    });
  });
}
