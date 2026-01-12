import '../../../core/services/api_client.dart';

class AuthRepository {
  final ApiClient _apiClient = ApiClient();
  // ===============================
  // VERIFY AUTH CONTEXT (มี token)
  // ===============================
  Future<Map<String, dynamic>> verifyAuthContext() async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/auth.verify',
    );

    if (response.data == null || response.data!['success'] != true) {
      throw Exception(response.data?['message'] ?? 'Token invalid');
    }

    return response.data!;
  }

  // ===============================
  // LOGIN (ยังไม่มี token)
  // ===============================
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    String? userGroup, // ⭐ เพิ่ม
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/auth.login',
      data: {'email': email, 'password': password, 'user_group': userGroup},
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
    );

    if (response.data == null || response.data!['success'] != true) {
      throw Exception(response.data?['message'] ?? 'Reset password failed');
    }
  }

  // ===============================
  // RESET PASSWORD (ลบ token)
  // ===============================

  Future<void> forgotPassword({required String email}) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/auth.forgot-password',
      data: {'email': email},
    );

    if (response.data == null || response.data!['success'] != true) {
      throw Exception(response.data?['message'] ?? 'Forgot password failed');
    }
  }

  // ===============================
  // VERIFY OTP (ต้องมี token)
  // ===============================
  Future<Map<String, dynamic>> verifyOtp({
    required String otp,
    required String otpSessionId,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/auth.verify-otp',
      data: {'otp': otp, 'otp_session_id': otpSessionId},
    );

    if (response.data == null || response.data!['success'] != true) {
      throw Exception(response.data?['message'] ?? 'OTP verify failed');
    }

    return response.data!;
  }

  Future<Map<String, dynamic>> resendOtp({required String otpSessionId}) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/auth.resend-otp',
      data: {'otp_session_id': otpSessionId},
    );

    if (response.data == null || response.data!['success'] != true) {
      throw Exception(response.data?['message'] ?? 'Resend OTP failed');
    }

    return response.data!;
  }
}
