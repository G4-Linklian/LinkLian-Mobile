// lib/core/services/notification_service.dart
import 'package:flutter/material.dart';

class NotificationService {
  // สร้าง Singleton เพื่อให้เรียกใช้ได้ง่ายๆ (หรือจะใช้ Dependency Injection ก็ได้)
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Key นี้เปรียบเสมือนตัวกลางในการเข้าถึง Root ของ App
  final GlobalKey<ScaffoldMessengerState> messengerKey = GlobalKey<ScaffoldMessengerState>();

  // ฟังก์ชันสำหรับเรียกแสดงผล (เทียบเท่า dispatch ใน React)
  void showSuccess(String message) {
    messengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void showError(String message) {
    messengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}