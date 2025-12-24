import 'package:flutter/foundation.dart';

class AppLogger {
  static void info(String message) {
    if (kDebugMode) {
      print('ℹ️ [INFO] $message');
    }
  }

  static void error(String message) {
    if (kDebugMode) {
      print('❌ [ERROR] $message');
    }
  }

  static void warning(String message) {
    if (kDebugMode) {
      print('⚠️ [WARNING] $message');
    }
  }

  static void success(String message) {
    if (kDebugMode) {
      print('✅ [SUCCESS] $message');
    }
  }

  static void debug(String message) {
    if (kDebugMode) {
      print('🐛 [DEBUG] $message');
    }
  }
}