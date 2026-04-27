import 'dart:async';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../data/repository/auth_repository.dart';
import '../../../core/services/local_storage.dart';
import '../../../core/services/socket_service.dart';
import '../../../core/utils/online_presence_utils.dart';
import 'package:flutter/foundation.dart';
import '../../layout/controllers/navigation_controller.dart';
import '../../../core/services/notification/notification_service.dart';

enum AuthStatus { checking, unauthenticated, authenticated }

String shortToken(String token) {
  if (token.length <= 20) return token;
  return '${token.substring(0, 10)}...${token.substring(token.length - 8)}';
}

class AuthController extends GetxController {
  final AuthRepository _authRepository = AuthRepository();
  final SocketService _socketService = SocketService();

  final RxnString token = RxnString();
  final RxnString roleName = RxnString();
  final RxnInt instId = RxnInt();
  final RxnInt userId = RxnInt();

  final Rx<AuthStatus> status = AuthStatus.checking.obs;
  Worker? _onlinePresenceWorker;
  int? _onlineJoinedUserId;

  @override
  void onInit() {
    super.onInit();
    _bindOnlinePresence();
    _tryAutoLogin();
    _loadFromStorage();
  }

  @override
  void onClose() {
    _onlinePresenceWorker?.dispose();
    super.onClose();
  }

  void _bindOnlinePresence() {
    _onlinePresenceWorker?.dispose();
    _onlinePresenceWorker = everAll([status, userId], (_) {
      final currentUserId = userId.value;
      if (status.value == AuthStatus.authenticated && currentUserId != null) {
        unawaited(_ensureOnlinePresence(currentUserId));
        return;
      }

      if (_onlineJoinedUserId != null) {
        _socketService.leaveOnline(userSysId: _onlineJoinedUserId!);
        _onlineJoinedUserId = null;
      }
      OnlinePresenceUtils.clearPresenceState();
      _socketService.disconnectOnline();
    });
  }

  Future<void> _ensureOnlinePresence(int currentUserId) async {
    if (_onlineJoinedUserId != null && _onlineJoinedUserId != currentUserId) {
      _socketService.leaveOnline(userSysId: _onlineJoinedUserId!);
    }

    final alreadyJoinedSameUser =
        _socketService.isOnlineConnected && _onlineJoinedUserId == currentUserId;
    if (alreadyJoinedSameUser) {
      return;
    }

    final onlineUrl = _buildOnlineSocketUrl();
    await _socketService.connectOnline(onlineUrl);

    if (!_socketService.isOnlineConnected) {
      return;
    }

    _socketService.joinOnline(userSysId: currentUserId);
    _onlineJoinedUserId = currentUserId;
  }

  String _buildOnlineSocketUrl() {
    final envSocketUrl = dotenv.env['SOCKET_URL']?.trim();
    final baseUrl =
        (envSocketUrl == null || envSocketUrl.isEmpty)
            ? 'wss://uat-socket.linklian.org/ws'
            : envSocketUrl;

    if (baseUrl.endsWith('/')) {
      return '${baseUrl}online';
    }
    return '$baseUrl/online';
  }

  Future<void> _loadFromStorage() async {
    final storedToken = await LocalStorage.getToken();

    debugPrint('🔐 Load token from storage = $storedToken');

    if (storedToken == null) return;

    token.value = storedToken;
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
    NotificationService().init(userId: userId);
  }

  Future<void> _tryAutoLogin() async {
    status.value = AuthStatus.checking;

    final storedToken = await LocalStorage.getToken();
    final storedUserId = await LocalStorage.getLastLoginUserId();

    if (storedToken == null || storedUserId == null) {
      _clearSession();
      return;
    }

    try {
      final res = await _authRepository.verifyAuthContext();

      final int tokenUserId = int.parse(res['data']['user_id'].toString());

      if (tokenUserId != storedUserId) {
        _clearSession();
        return;
      }

      token.value = storedToken;
      userId.value = tokenUserId;
      roleName.value = res['data']['role_name']?.toString();
      instId.value = int.tryParse(res['data']['inst_id'].toString());

      status.value = AuthStatus.authenticated;
      NotificationService().init(userId: tokenUserId);
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      if (statusCode == 401 || statusCode == 403) {
        _clearSession();
      } else {
        // network error / server error → ใช้ข้อมูลจาก storage แทน
        token.value = storedToken;
        userId.value = storedUserId;
        status.value = AuthStatus.authenticated;
      }
    } catch (_) {
      token.value = storedToken;
      userId.value = storedUserId;
      status.value = AuthStatus.authenticated;
    }
  }

  Future<void> refreshAuth() async {
    await _tryAutoLogin();
  }

  /// ===== Logout / hot reload =====
  Future<void> logout() async {
    if (userId.value != null) {
      await NotificationService().dispose(userId: userId.value!);
    }
    if (_onlineJoinedUserId != null) {
      _socketService.leaveOnline(userSysId: _onlineJoinedUserId!);
      _onlineJoinedUserId = null;
    }
    OnlinePresenceUtils.clearPresenceState();
    _socketService.disconnectOnline();

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

  void _clearSession() async {
    debugPrint('🚨 _clearSession() called — stack: ${StackTrace.current}');

    if (_onlineJoinedUserId != null) {
      _socketService.leaveOnline(userSysId: _onlineJoinedUserId!);
      _onlineJoinedUserId = null;
    }
    OnlinePresenceUtils.clearPresenceState();
    _socketService.disconnectOnline();

    await LocalStorage.clearAuthSession();

    token.value = null;
    roleName.value = null;
    instId.value = null;
    userId.value = null;
    status.value = AuthStatus.unauthenticated;
  }
}
