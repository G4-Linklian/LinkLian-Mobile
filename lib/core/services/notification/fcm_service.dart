import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:LinkLian/core/utils/logger.dart';
import 'package:LinkLian/firebase_options.dart';
import 'notification_payload.dart';

/// Background message handler — ต้องเป็น top-level function เท่านั้น
/// Android จะแสดง system notification อัตโนมัติจาก notification block ใน FCM payload
/// Handler นี้ทำงานใน isolate แยก — ใช้สำหรับ log และ side-effects เท่านั้น
@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final payload = NotificationPayload.fromFCM(message.data);
  appLog.info(
    'FCM background received: '
    'type=${payload.refType} '
    'id=${payload.notificationId} '
    'from=${payload.actorName}',
  );
}

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  String? _token;
  String? get token => _token;

  String get deviceType => Platform.isIOS ? 'ios' : 'android';

  /// เรียกครั้งเดียวหลัง Firebase.initializeApp()
  Future<void> init({
    required Future<void> Function(String token, String deviceType) onTokenReady,
    required void Function(NotificationPayload payload) onTap,
  }) async {
    // ขอ permission (iOS)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    appLog.info('FCM permission: ${settings.authorizationStatus}');

    // Background handler
    FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);

    // Foreground — ไม่แสดง system notification เพราะ Socket จะจัดการแทน
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: false,
      sound: false,
    );

    // รับ token แล้วส่งขึ้น Core
    await _refreshToken(onTokenReady: onTokenReady);

    // Token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      _token = newToken;
      onTokenReady(newToken, deviceType);
    });

    // Tap notification ขณะ app ถูก terminate
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      final payload = NotificationPayload.fromFCM(initial.data);
      onTap(payload);
    }

    // Tap notification ขณะ app อยู่ background
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final payload = NotificationPayload.fromFCM(message.data);
      onTap(payload);
    });
  }

  Future<void> _refreshToken({
    required Future<void> Function(String token, String deviceType) onTokenReady,
  }) async {
    try {
      final t = await _messaging.getToken();
      if (t != null) {
        _token = t;
        await onTokenReady(t, deviceType);
        appLog.info('FCM token ready');
      }
    } catch (e) {
      appLog.error('FCM getToken error: $e');
    }
  }

  Future<void> deleteToken() async {
    await _messaging.deleteToken();
    _token = null;
  }
}
