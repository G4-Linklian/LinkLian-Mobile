import 'package:flutter/foundation.dart';

/// 🎨 AppLogger — Beautiful debug logger with HTTP tracking & screen context
class AppLogger {
  static String get _now {
    final t = DateTime.now();
    return '${_pad(t.hour)}:${_pad(t.minute)}:${_pad(t.second)}.${t.millisecond.toString().padLeft(3, '0')}';
  }

  static String _pad(int v) => v.toString().padLeft(2, '0');

  // ─── Basic Levels ─────────────────────────────────────────────

  static void info(String message, {String? screen}) {
    _log(icon: 'ℹ️ ', level: 'INFO', message: message, screen: screen);
  }

  static void error(String message, {String? screen, Object? exception, StackTrace? stackTrace}) {
    _log(
      icon: '❌',
      level: 'ERROR',
      message: message,
      screen: screen,
      extra: exception != null ? 'Exception: $exception' : null,
      stackTrace: stackTrace,
    );
  }

  static void warning(String message, {String? screen}) {
    _log(icon: '⚠️ ', level: 'WARNING', message: message, screen: screen);
  }

  static void success(String message, {String? screen}) {
    _log(icon: '✅', level: 'SUCCESS', message: message, screen: screen);
  }

  static void debug(String message, {String? screen}) {
    _log(icon: '🐛', level: 'DEBUG', message: message, screen: screen);
  }

  // ─── HTTP Request Logger ──────────────────────────────────────

  static void request({
    required String method,
    required String url,
    String? screen,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) {
    if (!kDebugMode) return;
    final buf = StringBuffer();
    buf.writeln('🚀  [$_now]  $method');
    buf.writeln('    🌐  $url');
    if (screen != null) buf.writeln('    📍  $screen');
    if (headers != null && headers.isNotEmpty) {
      buf.writeln('    🔑  Headers');
      headers.forEach((k, v) => buf.writeln('        $k: $v'));
    }
    if (body != null && body.isNotEmpty) {
      buf.writeln('    📦  Body');
      body.forEach((k, v) => buf.writeln('        $k: $v'));
    }
    print(buf.toString());
    print("");
  }

  static void response({
    required String url,
    required int statusCode,
    required int durationMs,
    String? screen,
    dynamic data,
    String? errorMessage,
  }) {
    if (!kDebugMode) return;
    final isSuccess = statusCode >= 200 && statusCode < 300;
    final icon = isSuccess ? '✅' : '❌';
    final dataStatus = _resolveDataStatus(data);

    final buf = StringBuffer();
    buf.writeln('$icon  [$_now]  ${_statusIcon(statusCode)} $statusCode ${_httpStatusText(statusCode)}  ⏱️ ${durationMs}ms');
    buf.writeln('    🌐  $url');
    if (screen != null) buf.writeln('    📍  $screen');
    buf.writeln('    📦  $dataStatus');
    if (errorMessage != null) buf.writeln('    ⚠️  $errorMessage');
    print(buf.toString());
    print("");
  }

  static void httpLog({
    required String method,
    required String url,
    required int statusCode,
    required int durationMs,
    String? screen,
    dynamic responseData,
    String? errorMessage,
  }) {
    if (!kDebugMode) return;
    final isSuccess = statusCode >= 200 && statusCode < 300;
    final icon = isSuccess ? '✅' : '❌';
    final dataStatus = _resolveDataStatus(responseData);

    final buf = StringBuffer();
    buf.writeln('$icon  [$_now]  $method  →  $url');
    if (screen != null) buf.writeln('    📍  $screen');
    buf.writeln('    ${_statusIcon(statusCode)}  $statusCode ${_httpStatusText(statusCode)}   ⏱️ ${durationMs}ms');
    buf.writeln('    📦  $dataStatus');
    if (errorMessage != null) buf.writeln('    ⚠️  $errorMessage');
    print(buf.toString());
    print("");
  }

  // ─── Data Found / Not Found ───────────────────────────────────

  static void dataFound(String dataName, {String? screen, int? count}) {
    final countStr = count != null ? ' ($count items)' : '';
    _log(icon: '📋', level: 'DATA FOUND', message: '$dataName$countStr', screen: screen);
  }

  static void dataNotFound(String dataName, {String? screen}) {
    _log(icon: '🔍', level: 'DATA NOT FOUND', message: dataName, screen: screen);
  }

  // ─── Screen Navigation ────────────────────────────────────────

  static void screenEnter(String screenName) {
    if (!kDebugMode) return;
    print('\n📱  ENTER  $screenName   [$_now]');
  }

  static void screenExit(String screenName) {
    if (!kDebugMode) return;
    print('\n🚪  EXIT   $screenName   [$_now]');
  }

  // ─── Internal ─────────────────────────────────────────────────

  static void _log({
    required String icon,
    required String level,
    required String message,
    String? screen,
    String? extra,
    StackTrace? stackTrace,
  }) {
    if (!kDebugMode) return;
    final buf = StringBuffer();
    buf.writeln('$icon  [$_now]  $level');
    if (screen != null) buf.writeln('    📍  $screen');
    buf.writeln('    💬  $message');
    if (extra != null) buf.writeln('    ⚠️  $extra');
    if (stackTrace != null) {
      buf.writeln('    📋  StackTrace:');
      buf.writeln(stackTrace.toString().split('\n').take(5).map((l) => '        $l').join('\n'));
    }
    print(buf.toString());
    print("");
  }

  static String _resolveDataStatus(dynamic data) {
    if (data == null) return '❌ null — ไม่ได้รับข้อมูล';
    if (data is List) {
      return data.isEmpty ? '⚠️ List ว่าง (0 items)' : '✅ พบข้อมูล (${data.length} items)';
    }
    if (data is Map) {
      return data.isEmpty ? '⚠️ Map ว่าง' : '✅ พบข้อมูล (${data.length} fields)';
    }
    return '✅ ได้รับข้อมูล';
  }

  static String _statusIcon(int code) {
    if (code >= 200 && code < 300) return '🟢';
    if (code >= 300 && code < 400) return '🔵';
    if (code >= 400 && code < 500) return '🟠';
    return '🔴';
  }

  static String _httpStatusText(int code) {
    const map = {
      200: 'OK', 201: 'Created', 204: 'No Content',
      301: 'Moved Permanently', 302: 'Found', 304: 'Not Modified',
      400: 'Bad Request', 401: 'Unauthorized', 403: 'Forbidden',
      404: 'Not Found', 408: 'Request Timeout', 422: 'Unprocessable Entity',
      429: 'Too Many Requests', 500: 'Internal Server Error',
      502: 'Bad Gateway', 503: 'Service Unavailable',
    };
    return map[code] ?? '';
  }
}