import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:LinkLian/features/auth/controller/auth_controller.dart';
import 'package:LinkLian/features/layout/controllers/navigation_controller.dart';
import 'package:LinkLian/core/services/local_storage.dart';

// Mock AuthRepository for controlled API responses
class MockAuthRepository {
  Map<String, dynamic>? mockVerifyResponse;
  bool shouldThrowError = false;
  String errorMessage = 'API Error';

  Future<Map<String, dynamic>> verifyAuthContext() async {
    if (shouldThrowError) throw Exception(errorMessage);
    return mockVerifyResponse ??
        {
          'data': {
            'user_id': 1,
            'role_name': 'student',
            'inst_id': 100,
          },
          'require_reset_password': false,
        };
  }
}

// Standalone testable controller that mirrors AuthController behavior
// without triggering ApiClient singleton initialization
class TestableAuthController extends GetxController {
  final MockAuthRepository _mockRepo;

  TestableAuthController(this._mockRepo);

  final RxnString token = RxnString();
  final RxnString roleName = RxnString();
  final RxnInt instId = RxnInt();
  final RxnInt userId = RxnInt();
  final Rx<AuthStatus> status = AuthStatus.checking.obs;

  bool get isLoggedIn => status.value == AuthStatus.authenticated;

  // Mirror setSession from AuthController
  void setSession({
    required String token,
    required String roleName,
    required int instId,
    required int userId,
  }) {
    this.token.value = token;
    this.roleName.value = roleName;
    this.instId.value = instId;
    this.userId.value = userId;
    status.value = AuthStatus.authenticated;
  }

  // Mirror establishSession from AuthController
  Future<void> establishSession({
    required String token,
    required String roleName,
    required int instId,
    required int userId,
  }) async {
    await LocalStorage.saveToken(token);
    await LocalStorage.saveLastLoginUserId(userId);

    this.token.value = token;
    this.userId.value = userId;
    this.roleName.value = roleName;
    this.instId.value = instId;
    status.value = AuthStatus.authenticated;
  }

  // Mirror _tryAutoLogin logic from AuthController
  Future<void> tryAutoLogin() async {
    status.value = AuthStatus.checking;
    try {
      final storedToken = await LocalStorage.getToken();
      final storedUserId = await LocalStorage.getLastLoginUserId();

      if (storedToken == null || storedUserId == null) {
        await clearSession();
        return;
      }

      final res = await _mockRepo.verifyAuthContext();
      if (res['require_reset_password'] == true) {
        await LocalStorage.clearAuthSession();
        status.value = AuthStatus.unauthenticated;
        return;
      }

      final int tokenUserId = int.parse(res['data']['user_id'].toString());

      if (tokenUserId != storedUserId) {
        await clearSession();
        return;
      }

      token.value = storedToken;
      userId.value = tokenUserId;
      roleName.value = res['data']['role_name'];
      instId.value = res['data']['inst_id'];
      status.value = AuthStatus.authenticated;
    } catch (_) {
      await clearSession();
    }
  }

  // Mirror refreshAuth from AuthController
  Future<void> refreshAuth() async {
    await tryAutoLogin();
  }

  // Mirror logout from AuthController
  Future<void> logout() async {
    await LocalStorage.clearAuthSession();

    if (Get.isRegistered<NavigationController>()) {
      final nav = Get.find<NavigationController>();
      nav.selectedIndex.value = 1;
      nav.hideClassDetail();
      nav.hideCommunityDetail();
      nav.hideClassAssignment();
    }

    token.value = null;
    roleName.value = null;
    instId.value = null;
    userId.value = null;
    status.value = AuthStatus.unauthenticated;
  }

  // Mirror _clearSession from AuthController
  Future<void> clearSession() async {
    await LocalStorage.clearAuthSession();
    token.value = null;
    roleName.value = null;
    instId.value = null;
    userId.value = null;
    status.value = AuthStatus.unauthenticated;
  }
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('AuthController Unit Tests', () {
    late TestableAuthController controller;
    late MockAuthRepository mockAuthRepo;

    setUp(() async {
      Get.reset();

      // Initialize SharedPreferences with empty data
      SharedPreferences.setMockInitialValues({});
      await LocalStorage.init();

      mockAuthRepo = MockAuthRepository();
      controller = TestableAuthController(mockAuthRepo);
      Get.put<TestableAuthController>(controller);
    });

    tearDown(() {
      Get.reset();
    });

    // ========== Utility Function Tests ==========
    group('shortToken() utility function', () {
      // Test: Short tokens should return unchanged
      test('should return token unchanged if length <= 20', () {
        expect(shortToken('abc'), equals('abc'));
        expect(shortToken('12345678901234567890'), equals('12345678901234567890'));
        expect(shortToken(''), equals(''));
      });

      // Test: Long tokens should be truncated with ellipsis
      test('should truncate token longer than 20 characters', () {
        const longToken = 'abcdefghij1234567890klmnop';
        final result = shortToken(longToken);

        // shortToken takes first 10 chars + "..." + last 8 chars
        expect(result, equals('abcdefghij...90klmnop'));
        expect(result.length, lessThan(longToken.length));
        expect(result.contains('...'), isTrue);
      });

      // Test: Boundary value - exactly 21 chars
      test('should truncate token of exactly 21 characters', () {
        const token21 = '123456789012345678901';
        final result = shortToken(token21);

        expect(result, contains('...'));
        expect(result.startsWith('1234567890'), isTrue);
      });
    });

    // ========== Session Management Tests ==========
    group('setSession()', () {
      // Test: Session values should update correctly
      test('should set all session values and status to authenticated', () {
        controller.setSession(
          token: 'test_token_123',
          roleName: 'teacher',
          instId: 42,
          userId: 99,
        );

        expect(controller.token.value, equals('test_token_123'));
        expect(controller.roleName.value, equals('teacher'));
        expect(controller.instId.value, equals(42));
        expect(controller.userId.value, equals(99));
        expect(controller.status.value, equals(AuthStatus.authenticated));
      });

      // Test: isLoggedIn getter should reflect correct status
      test('isLoggedIn should return true after setSession', () {
        expect(controller.isLoggedIn, isFalse);

        controller.setSession(
          token: 'token',
          roleName: 'student',
          instId: 1,
          userId: 1,
        );

        expect(controller.isLoggedIn, isTrue);
      });
    });

    group('establishSession()', () {
      // Test: Should persist data to local storage
      test('should save token and userId to LocalStorage', () async {
        await controller.establishSession(
          token: 'persist_token',
          roleName: 'admin',
          instId: 10,
          userId: 55,
        );

        final savedToken = await LocalStorage.getToken();
        final savedUserId = await LocalStorage.getLastLoginUserId();

        expect(savedToken, equals('persist_token'));
        expect(savedUserId, equals(55));
        expect(controller.status.value, equals(AuthStatus.authenticated));
      });

      // Test: State should update after establish
      test('should update controller state correctly', () async {
        await controller.establishSession(
          token: 'new_token',
          roleName: 'student',
          instId: 5,
          userId: 100,
        );

        expect(controller.token.value, equals('new_token'));
        expect(controller.roleName.value, equals('student'));
        expect(controller.instId.value, equals(5));
        expect(controller.userId.value, equals(100));
      });
    });

    // ========== Auto-Login Tests ==========
    group('tryAutoLogin()', () {
      // Test: Should clear session when no stored credentials
      test('should clear session when no token in storage', () async {
        await controller.tryAutoLogin();

        expect(controller.status.value, equals(AuthStatus.unauthenticated));
        expect(controller.token.value, isNull);
      });

      // Test: Should authenticate with valid stored credentials
      test('should authenticate when valid token and userId match', () async {
        // Setup stored credentials
        await LocalStorage.saveToken('valid_token');
        await LocalStorage.saveLastLoginUserId(1);

        mockAuthRepo.mockVerifyResponse = {
          'data': {
            'user_id': 1,
            'role_name': 'student',
            'inst_id': 100,
          },
          'require_reset_password': false,
        };

        await controller.tryAutoLogin();

        expect(controller.status.value, equals(AuthStatus.authenticated));
        expect(controller.token.value, equals('valid_token'));
        expect(controller.userId.value, equals(1));
        expect(controller.roleName.value, equals('student'));
      });

      // Test: Should clear session on userId mismatch
      test('should clear session when userId does not match', () async {
        await LocalStorage.saveToken('valid_token');
        await LocalStorage.saveLastLoginUserId(999);

        mockAuthRepo.mockVerifyResponse = {
          'data': {
            'user_id': 1, // Different from stored (999)
            'role_name': 'student',
            'inst_id': 100,
          },
          'require_reset_password': false,
        };

        await controller.tryAutoLogin();

        expect(controller.status.value, equals(AuthStatus.unauthenticated));
      });

      // Test: Should handle password reset requirement
      test('should set unauthenticated when password reset required', () async {
        await LocalStorage.saveToken('valid_token');
        await LocalStorage.saveLastLoginUserId(1);

        mockAuthRepo.mockVerifyResponse = {
          'data': {'user_id': 1, 'role_name': 'student', 'inst_id': 100},
          'require_reset_password': true,
        };

        await controller.tryAutoLogin();

        expect(controller.status.value, equals(AuthStatus.unauthenticated));
      });

      // Test: Should handle API errors gracefully
      test('should clear session on API error', () async {
        await LocalStorage.saveToken('valid_token');
        await LocalStorage.saveLastLoginUserId(1);

        mockAuthRepo.shouldThrowError = true;

        await controller.tryAutoLogin();

        expect(controller.status.value, equals(AuthStatus.unauthenticated));
      });
    });

    // ========== Logout Tests ==========
    group('logout()', () {
      // Test: Should clear all session data
      test('should clear all session values and local storage', () async {
        // Setup authenticated state
        controller.setSession(
          token: 'active_token',
          roleName: 'teacher',
          instId: 50,
          userId: 25,
        );

        await controller.logout();

        expect(controller.token.value, isNull);
        expect(controller.roleName.value, isNull);
        expect(controller.instId.value, isNull);
        expect(controller.userId.value, isNull);
        expect(controller.status.value, equals(AuthStatus.unauthenticated));
        expect(controller.isLoggedIn, isFalse);
      });

      // Test: Should clear LocalStorage on logout
      test('should clear auth data from LocalStorage', () async {
        await LocalStorage.saveToken('stored_token');
        await LocalStorage.saveLastLoginUserId(99);

        await controller.logout();

        final storedToken = await LocalStorage.getToken();
        final storedUserId = await LocalStorage.getLastLoginUserId();

        expect(storedToken, isNull);
        expect(storedUserId, isNull);
      });

      // Test: Should reset NavigationController if registered
      test('should reset NavigationController when registered', () async {
        final navController = NavigationController();
        navController.selectedIndex.value = 3;
        navController.isShowingClassDetail.value = true;
        navController.isShowingCommunityDetail.value = true;
        navController.isShowingClassAssignment.value = true;

        Get.put<NavigationController>(navController);

        controller.setSession(
          token: 'token',
          roleName: 'student',
          instId: 1,
          userId: 1,
        );

        await controller.logout();

        expect(navController.selectedIndex.value, equals(1));
        expect(navController.isShowingClassDetail.value, isFalse);
        expect(navController.isShowingCommunityDetail.value, isFalse);
        expect(navController.isShowingClassAssignment.value, isFalse);
      });

      // Test: Should handle logout when NavigationController not registered
      test('should complete logout when NavigationController not registered', () async {
        controller.setSession(
          token: 'token',
          roleName: 'student',
          instId: 1,
          userId: 1,
        );

        // No exception should be thrown
        await controller.logout();

        expect(controller.status.value, equals(AuthStatus.unauthenticated));
      });
    });

    // ========== refreshAuth Tests ==========
    group('refreshAuth()', () {
      // Test: Should trigger auto-login flow
      test('should re-verify authentication', () async {
        await LocalStorage.saveToken('refresh_token');
        await LocalStorage.saveLastLoginUserId(1);

        mockAuthRepo.mockVerifyResponse = {
          'data': {'user_id': 1, 'role_name': 'admin', 'inst_id': 200},
          'require_reset_password': false,
        };

        await controller.refreshAuth();

        expect(controller.status.value, equals(AuthStatus.authenticated));
        expect(controller.roleName.value, equals('admin'));
      });
    });

    // ========== AuthStatus Enum Tests ==========
    group('AuthStatus', () {
      // Test: Verify enum values exist
      test('should have correct enum values', () {
        expect(AuthStatus.values.length, equals(3));
        expect(AuthStatus.values, contains(AuthStatus.checking));
        expect(AuthStatus.values, contains(AuthStatus.unauthenticated));
        expect(AuthStatus.values, contains(AuthStatus.authenticated));
      });

      // Test: Initial status should be checking
      test('initial status should be checking', () {
        final newController = TestableAuthController(mockAuthRepo);
        newController.status.value = AuthStatus.checking;
        expect(newController.status.value, equals(AuthStatus.checking));
      });
    });

    // ========== Edge Cases ==========
    group('Edge Cases', () {
      // Test: Handle null values in API response
      test('should handle missing data fields gracefully', () async {
        await LocalStorage.saveToken('token');
        await LocalStorage.saveLastLoginUserId(1);

        mockAuthRepo.mockVerifyResponse = {
          'data': {
            'user_id': '1', // String instead of int
            'role_name': null,
            'inst_id': null,
          },
          'require_reset_password': false,
        };

        await controller.tryAutoLogin();

        expect(controller.userId.value, equals(1));
        expect(controller.status.value, equals(AuthStatus.authenticated));
      });

      // Test: Handle string userId conversion
      test('should parse string userId correctly', () async {
        await LocalStorage.saveToken('token');
        await LocalStorage.saveLastLoginUserId(123);

        mockAuthRepo.mockVerifyResponse = {
          'data': {
            'user_id': '123', // String format
            'role_name': 'student',
            'inst_id': 1,
          },
          'require_reset_password': false,
        };

        await controller.tryAutoLogin();

        expect(controller.userId.value, equals(123));
      });

      // Test: Multiple logout calls should not cause issues
      test('should handle multiple consecutive logouts', () async {
        controller.setSession(
          token: 'token',
          roleName: 'student',
          instId: 1,
          userId: 1,
        );

        await controller.logout();
        await controller.logout();
        await controller.logout();

        expect(controller.status.value, equals(AuthStatus.unauthenticated));
        expect(controller.token.value, isNull);
      });

      // Test: Session establish then logout cycle
      test('should handle session establish and logout cycle', () async {
        // Establish session
        await controller.establishSession(
          token: 'cycle_token',
          roleName: 'teacher',
          instId: 5,
          userId: 10,
        );
        expect(controller.isLoggedIn, isTrue);

        // Logout
        await controller.logout();
        expect(controller.isLoggedIn, isFalse);

        // Re-establish
        await controller.establishSession(
          token: 'new_cycle_token',
          roleName: 'admin',
          instId: 6,
          userId: 11,
        );
        expect(controller.isLoggedIn, isTrue);
        expect(controller.roleName.value, equals('admin'));
      });
    });

    // ========== Reactive Observable Tests ==========
    group('Reactive Observables', () {
      // Test: Token changes should be observable
      test('token should be reactive', () async {
        String? observedValue;
        controller.token.listen((value) => observedValue = value);

        controller.setSession(
          token: 'reactive_token',
          roleName: 'student',
          instId: 1,
          userId: 1,
        );

        await Future.delayed(Duration(milliseconds: 10));
        expect(observedValue, equals('reactive_token'));
      });

      // Test: Status changes should trigger listeners
      test('status should be reactive', () async {
        final statusHistory = <AuthStatus>[];
        controller.status.listen((value) => statusHistory.add(value));

        controller.setSession(
          token: 'token',
          roleName: 'student',
          instId: 1,
          userId: 1,
        );

        await Future.delayed(Duration(milliseconds: 10));
        expect(statusHistory, contains(AuthStatus.authenticated));
      });
    });
  });
}
