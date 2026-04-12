import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import 'package:LinkLian/core/services/api_client.dart';
import 'package:LinkLian/core/services/socket_service.dart';
import 'package:LinkLian/core/utils/logger.dart';
import 'package:LinkLian/core/utils/notification_navigation_helper.dart';
import 'fcm_service.dart';
import 'notification_payload.dart';

/// Coordinator — เชื่อม Socket + FCM เข้าด้วยกัน
/// เรียก init() หลัง login, dispose() หลัง logout
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FCMService _fcm = FCMService();
  final SocketService _socket = SocketService();

  // Stream สำหรับ widget ที่ต้องการ listen notification แบบ real-time
  final inAppNotification = Rxn<NotificationPayload>();

  // จำนวน unread — ใช้แสดง badge บน bell icon ใน layout
  final unreadCount = 0.obs;

  Future<void> init({required int userId}) async {
    // 1. init FCM — register token + setup tap handler
    await _fcm.init(
      onTokenReady: (token, deviceType) => _registerToken(userId, token, deviceType),
      onTap: (payload) => NotificationNavigationHelper.navigate(payload),
    );

    // 2. connect notification socket แล้วส่ง REGISTER_NOTI
    await _socket.connectNotification(userId);

    // 3. listen notification stream สำหรับ NOTIFICATION event
    _socket.notiStream.listen((data) {
      if (data is Map && data['type'] == 'NOTIFICATION') {
        // DEBUG — ลบออกหลัง verify
        appLog.debug('Socket NOTIFICATION raw payload', data: data['payload']);
        final payload = NotificationPayload.fromSocket(
          Map<String, dynamic>.from(data['payload'] ?? {}),
        );
        inAppNotification.value = payload;
      }
    });

    appLog.info('NotificationService initialized for user $userId');
  }

  Future<void> dispose({required int userId}) async {
    await _socket.disconnectNotification();
    final token = _fcm.token;
    if (token != null) {
      await _removeToken(userId, token);
      await _fcm.deleteToken();
    }
    inAppNotification.value = null;
  }

  // ─── Private ────────────────────────────────────────────────────────────────

  Future<void> _registerToken(int userId, String token, String deviceType) async {
    try {
      final api = Get.find<ApiClient>();
      await api.post(
        '/notification/fcm-token',
        data: {'token': token, 'device_type': deviceType},
      );
      appLog.info('FCM token registered');
    } on DioException catch (e) {
      appLog.error('Register FCM token failed: ${e.message}');
    }
  }

  Future<void> _removeToken(int userId, String token) async {
    try {
      final api = Get.find<ApiClient>();
      await api.delete(
        '/notification/fcm-token',
        data: {'token': token},
      );
      appLog.info('FCM token removed');
    } on DioException catch (e) {
      appLog.error('Remove FCM token failed: ${e.message}');
    }
  }
}
