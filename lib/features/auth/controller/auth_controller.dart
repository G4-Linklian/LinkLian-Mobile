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


  final RxnString token = RxnString();
  final RxnString roleName = RxnString();
  final RxnInt instId = RxnInt();
  final RxnInt userId = RxnInt();

  final Rx<AuthStatus> status = AuthStatus.checking.obs;

@override
void onInit() {
  super.onInit();
  print('🧠 AuthController hash = ${hashCode}');
  _tryAutoLogin();
}


  bool get isLoggedIn => status.value == AuthStatus.authenticated;

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

  Future<void> _tryAutoLogin() async {
    try {
      status.value = AuthStatus.checking;

      final storedToken = await LocalStorage.getToken();
      final storedUserId = await LocalStorage.getLastLoginUserId();

      if (storedToken == null || storedUserId == null) {
        _clearSession();
        return;
      }

      final res = await _authRepository.verifyAuthContext();
      if (res['require_reset_password'] == true) {
        await LocalStorage.clearAuthSession();
        status.value = AuthStatus.unauthenticated;
        return;
      }

      final data = res['data'];

      final int tokenUserId = int.parse(res['data']['user_id'].toString());

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
