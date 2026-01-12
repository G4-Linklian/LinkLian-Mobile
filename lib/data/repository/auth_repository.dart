import '../../../core/services/api_client.dart';
import '../../../core/services/local_storage.dart';

class AuthRepository {
  final ApiClient _apiClient = ApiClient();

  // ===============================
  // VERIFY AUTH CONTEXT (มี token)
  // ===============================
  Future<Map<String, dynamic>> verifyAuthContext() async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/auth.verify',
    );

    if (response.data == null) {
      throw Exception('No response from server');
    }

    return response.data!;
  }

  // ===============================
  // LOGIN (🔥 แก้ไขเพื่อส่ง token ถ้ามี)
  // ===============================
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    String? userGroup,
    bool rememberMe = false,
  }) async {
    // 🔥 เช็คว่ามี token ใน local storage ไหม
    final existingToken = await LocalStorage.getToken();

    final response = await _apiClient.post<Map<String, dynamic>>(
      '/auth.login',
      data: {
        'email': email,
        'password': password,
        'user_group': userGroup,
        'remember_me': rememberMe,
      },
      // 🔥 ถ้ามี token → ส่งไปด้วย เพื่อให้ Backend skip OTP
      requiresAuth: existingToken != null,
    );

    if (response.data == null || response.data!['success'] != true) {
      throw Exception(response.data?['message'] ?? 'Login failed');
    }

    return response.data!;
  }

  // ===============================
  // RESET PASSWORD (ยังไม่มี token)
  // ===============================
  Future<void> resetPassword({
    required String email,
    required String password,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/auth.reset-password',
      data: {
        'email': email,
        'password': password,
        'new_password': newPassword,
        'confirm_password': confirmPassword,
      },
      requiresAuth: false,
    );

    if (response.data == null || response.data!['success'] != true) {
      throw Exception(response.data?['message'] ?? 'Reset password failed');
    }
  }

  // ===============================
  // FORGOT PASSWORD (ลบ token)
  // ===============================
  Future<void> forgotPassword({required String email}) async {
    print('🧪 [TEST] calling forgotPassword');
    print('🧪 [TEST] email = $email');

    final response = await _apiClient.post<Map<String, dynamic>>(
      '/auth.forgot-password',
      data: {'email': email},
      requiresAuth: false,
    );

    print('🧪 [TEST] response arrived');

    if (response.data == null || response.data!['success'] != true) {
      throw Exception(response.data?['message'] ?? 'Forgot password failed');
    }
  }

  // ===============================
  // VERIFY OTP
  // ===============================
  Future<Map<String, dynamic>> verifyOtp({
    required String otp,
    required String otpSessionId,
    required bool rememberMe,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/auth.verify-otp',
      data: {
        'otp': otp,
        'otp_session_id': otpSessionId,
        'remember_me': rememberMe,
      },
      requiresAuth: false,
    );

    if (response.data == null || response.data!['success'] != true) {
      throw Exception(response.data?['message'] ?? 'OTP verify failed');
    }

    return response.data!;
  }

  // ===============================
  // RESEND OTP
  // ===============================
  Future<Map<String, dynamic>> resendOtp({required String otpSessionId}) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/auth.resend-otp',
      data: {'otp_session_id': otpSessionId},
      requiresAuth: false,
    );

    if (response.data == null || response.data!['success'] != true) {
      throw Exception(response.data?['message'] ?? 'Resend OTP failed');
    }

    return response.data!;
  }
}