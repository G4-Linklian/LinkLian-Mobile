import 'package:get/get.dart';
import '../../../data/repository/auth_repository.dart';
import '../../../core/services/local_storage.dart';

enum AuthStatus { checking, unauthenticated, authenticated }

String shortToken(String token) {
  if (token.length <= 20) return token;
  return '${token.substring(0, 10)}...${token.substring(token.length - 8)}';
}

class AuthController extends GetxController {
  final AuthRepository _authRepository = AuthRepository();

  /// ===== ของเดิม (ไม่ลบ) =====
  final RxnString token = RxnString();
  final RxnString roleName = RxnString();
  final RxnInt instId = RxnInt();
  final RxnInt userId = RxnInt();

  /// ===== เพิ่มใหม่ =====
  final Rx<AuthStatus> status = AuthStatus.checking.obs;

  /// ===== lifecycle =====
@override
void onInit() {
  super.onInit();
  print('🧠 AuthController hash = ${hashCode}');
  _tryAutoLogin();
}

  /// ===== public getters =====
  bool get isLoggedIn => status.value == AuthStatus.authenticated;

  /// ===== ของเดิม (ยังใช้ได้) =====
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

  /// ===== ใช้หลัง OTP สำเร็จ (แนะนำให้ใช้แทน setSession ตรง ๆ) =====
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

  print('✅ Auth status changed to AUTHENTICATED');
}
  /// ===== Auto-login แบบใหม่ (ไม่พัง) =====
  Future<void> _tryAutoLogin() async {
    try {
      status.value = AuthStatus.checking;

      final storedToken = await LocalStorage.getToken();
      final storedUserId = await LocalStorage.getLastLoginUserId();

      print('🔐 [AUTH] tryAutoLogin');
      print(
        '🔐 [AUTH] storedToken = ${storedToken != null ? shortToken(storedToken) : 'null'}',
      );
      print('🔐 [AUTH] storedUserId = $storedUserId');

      if (storedToken == null || storedUserId == null) {
        _clearSession();
        return;
      }

      // backend เป็นคนตัดสิน
      final res = await _authRepository.verifyAuthContext();
      // 🔥 กรณีต้อง reset password
      if (res['require_reset_password'] == true) {
        await LocalStorage.clearAuthSession();
        status.value = AuthStatus.unauthenticated;
        return;
      }

      // กรณีปกติ
      final data = res['data'];
      print('🔐 [AUTH] verifyAuthContext OK');
      print('🔐 [AUTH] backend user_id = ${res['data']['user_id']}');
      print('🔐 [AUTH] role = ${res['data']['role_name']}');
      print('🔐 [AUTH] inst_id = ${res['data']['inst_id']}');

      final int tokenUserId = int.parse(res['data']['user_id'].toString());

      // 🔒 guard: token ต้องเป็นของ user เดียวกัน
      if (tokenUserId != storedUserId) {
        _clearSession();
        return;
      }

      token.value = storedToken;
      userId.value = tokenUserId;
      roleName.value = res['data']['role_name'];
      instId.value = res['data']['inst_id'];

      status.value = AuthStatus.authenticated;
    } catch (_) {
      _clearSession();
    }
  }
  Future<void> refreshAuth() async {
    await _tryAutoLogin();
  }

  /// ===== Logout / hot reload =====
  Future<void> logout() async {
  // ❗ ลบแค่ state ใน memory
  token.value = null;
  roleName.value = null;
  instId.value = null;
  userId.value = null;
  status.value = AuthStatus.unauthenticated;
}

  void _clearSession() {
    token.value = null;
    roleName.value = null;
    instId.value = null;
    userId.value = null;
    status.value = AuthStatus.unauthenticated;
  }
}
