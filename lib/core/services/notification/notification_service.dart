import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import 'package:LinkLian/core/services/api_client.dart';
import 'package:LinkLian/core/services/badge_service.dart';
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

  Future<void> init({required int userId}) async {
    // 1. init FCM — register token + setup tap handler
    await _fcm.init(
      onTokenReady: (token, deviceType) =>
          _registerToken(userId, token, deviceType),
      onTap: (payload) => NotificationNavigationHelper.navigate(payload),
    );

    // 2. connect notification socket แล้วส่ง REGISTER_NOTI
    await _socket.connectNotification(userId);

    // 3. โหลด unread count ครั้งแรก
    await refreshUnreadCount();

    // 4. listen NOTIFICATION event — วิเคราะห์ feature แล้วส่งไป BadgeService
    _socket.notiStream.listen((data) {
      if (data is Map && data['type'] == 'NOTIFICATION') {
        appLog.debug('Socket NOTIFICATION raw payload', data: data['payload']);
        final payload = NotificationPayload.fromSocket(
          Map<String, dynamic>.from(data['payload'] ?? {}),
        );
        inAppNotification.value = payload;

        // general notification badge เท่านั้น
        if (payload.feature != BadgeFeature.chat) {
          BadgeService().increment(BadgeFeature.general);
        }

        // [TODO: ทีม Chat] chat badge — ให้ทีม chat เรียกใช้เองจาก chat socket (CHAT_RECEIVE)
        // ตัวอย่าง:
        //   BadgeService().increment(BadgeFeature.chat);  // เมื่อมีข้อความใหม่
        //   BadgeService().set(BadgeFeature.chat, count); // ตอน init โหลดจาก API
        //   BadgeService().clear(BadgeFeature.chat);      // ตอนเปิดห้องแชท
      }
    });

    appLog.info('NotificationService initialized for user $userId');
  }

  /// โหลด unread count (ไม่รวม chat) — ตั้งค่าผ่าน BadgeService
  Future<void> refreshUnreadCount() async {
    try {
      final api = Get.find<ApiClient>();
      final res = await api.get<Map<String, dynamic>>(
        '/notification/unread-count',
        queryParameters: {'exclude_feature': 'chat'},
      );
      final count =
          int.tryParse(res.data?['data']?['unread_count']?.toString() ?? '0') ??
              0;
      BadgeService().set(BadgeFeature.general, count);
    } catch (_) {}
  }

  Future<void> dispose({required int userId}) async {
    await _socket.disconnectNotification();
    final token = _fcm.token;
    if (token != null) {
      await _removeToken(userId, token);
      await _fcm.deleteToken();
    }
    inAppNotification.value = null;
    BadgeService().clear(BadgeFeature.general);
    // [TODO: ทีม Chat] เคลียร์ chat badge ตอน logout
    // BadgeService().clear(BadgeFeature.chat);
  }

  // ─── Private ────────────────────────────────────────────────────────────────

  Future<void> _registerToken(
      int userId, String token, String deviceType) async {
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
