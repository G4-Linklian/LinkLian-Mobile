import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DEPENDENCIES (pubspec.yaml):
//   logger: ^2.4.0
// ─────────────────────────────────────────────────────────────────────────────

// ─── Log Event Model ──────────────────────────────────────────────────────────

/// Represents a single structured log entry
class AppLogEvent {
  final DateTime requestTime;
  final String? url;
  final int? statusCode;
  final String? actionPage;
  final String event;
  final String? method;
  final int? durationMs;
  final Object? exception;
  final StackTrace? stackTrace;

  const AppLogEvent({
    required this.requestTime,
    required this.event,
    this.url,
    this.statusCode,
    this.actionPage,
    this.method,
    this.durationMs,
    this.exception,
    this.stackTrace,
  });
}

// ─── Custom Pretty Printer ────────────────────────────────────────────────────

class _AppLogPrinter extends LogPrinter {
  @override
  List<String> log(LogEvent event) {
    final data = event.message;
    if (data is! AppLogEvent) return [event.message.toString()];

    final t = data.requestTime;
    final timeStr =
        '${_pad(t.hour)}.${_pad(t.minute)}.${_pad(t.second)}${t.millisecond > 0 ? '.${t.millisecond.toString().padLeft(3, '0')}' : ''}';

    final lines = <String>[];
    lines.add(_divider(event.level));
    lines.add('${_levelIcon(event.level)}  ${_levelLabel(event.level)}');
    lines.add('   Request Time : [$timeStr]');
    if (data.method != null && data.url != null) {
      lines.add('   URL          : ${data.method} ${data.url}');
    } else if (data.url != null) {
      lines.add('   URL          : ${data.url}');
    }
    if (data.statusCode != null) {
      lines.add('   Status       : ${data.statusCode} - ${_httpStatusText(data.statusCode!)}  ${_statusIcon(data.statusCode!)}');
    }
    if (data.durationMs != null) {
      lines.add('   Duration     : ${data.durationMs}ms');
    }
    if (data.actionPage != null) {
      lines.add('   Action Page  : [${data.actionPage}]');
    }
    lines.add('   Event        : ${data.event}');
    if (data.exception != null) {
      lines.add('   Exception    : ${data.exception}');
    }
    if (data.stackTrace != null) {
      final stLines = data.stackTrace.toString().split('\n').take(5);
      lines.add('   StackTrace   :');
      lines.addAll(stLines.map((l) => '      $l'));
    }
    lines.add('');
    return lines;
  }

  String _divider(Level level) {
    const width = 60;
    return '─' * width;
  }

  String _levelIcon(Level level) => switch (level) {
        Level.trace   => '🐛',
        Level.debug   => '🔍',
        Level.info    => 'ℹ️ ',
        Level.warning => '⚠️ ',
        Level.error   => '❌',
        Level.fatal   => '💀',
        _             => '📋',
      };

  String _levelLabel(Level level) => switch (level) {
        Level.trace   => 'TRACE',
        Level.debug   => 'DEBUG',
        Level.info    => 'INFO',
        Level.warning => 'WARNING',
        Level.error   => 'ERROR',
        Level.fatal   => 'FATAL',
        _             => 'LOG',
      };

  static String _pad(int v) => v.toString().padLeft(2, '0');

  static String _statusIcon(int code) {
    if (code >= 200 && code < 300) return '🟢';
    if (code >= 300 && code < 400) return '🔵';
    if (code >= 400 && code < 500) return '🟠';
    return '🔴';
  }

  static String _httpStatusText(int code) {
    const map = {
      200: 'OK',
      201: 'Created',
      204: 'No Content',
      301: 'Moved Permanently',
      302: 'Found',
      304: 'Not Modified',
      400: 'Bad Request',
      401: 'Unauthorized',
      403: 'Forbidden',
      404: 'Not Found',
      408: 'Request Timeout',
      422: 'Unprocessable Entity',
      429: 'Too Many Requests',
      500: 'Internal Server Error',
      502: 'Bad Gateway',
      503: 'Service Unavailable',
    };
    return map[code] ?? 'Unknown';
  }
}

// ─── AppLogger (Singleton) ────────────────────────────────────────────────────

/// 🎨 AppLogger — Structured, OOP-friendly logger for Flutter
///
/// Usage:
///   AppLogger.instance.http(
///     method: 'POST',
///     url: '/auth/otp',
///     statusCode: 200,
///     actionPage: 'LoginPage',
///     event: 'OTP popup showed',
///   );
class AppLogger {
  AppLogger._();

  static final AppLogger instance = AppLogger._();

  late final Logger _logger = Logger(
    level: kDebugMode ? Level.trace : Level.off,
    printer: _AppLogPrinter(),
  );

  // ─── HTTP / API Logging ────────────────────────────────────────

  /// Log an HTTP request + response in one call
  void http({
    required String method,
    required String url,
    required int statusCode,
    required String event,
    String? actionPage,
    int? durationMs,
  }) {
    final isSuccess = statusCode >= 200 && statusCode < 300;
    final logEvent = AppLogEvent(
      requestTime: DateTime.now(),
      method: method,
      url: url,
      statusCode: statusCode,
      actionPage: actionPage,
      durationMs: durationMs,
      event: event,
    );
    if (isSuccess) {
      _logger.i(logEvent);
    } else if (statusCode >= 500) {
      _logger.e(logEvent);
    } else {
      _logger.w(logEvent);
    }
  }

  // ─── General Levels ────────────────────────────────────────────

  void info(String event, {String? actionPage, String? url}) {
    _logger.i(AppLogEvent(
      requestTime: DateTime.now(),
      event: event,
      actionPage: actionPage,
      url: url,
    ));
  }

  void debug(String event, {String? actionPage, String? url}) {
    _logger.d(AppLogEvent(
      requestTime: DateTime.now(),
      event: event,
      actionPage: actionPage,
      url: url,
    ));
  }

  void warning(String event, {String? actionPage, String? url}) {
    _logger.w(AppLogEvent(
      requestTime: DateTime.now(),
      event: event,
      actionPage: actionPage,
      url: url,
    ));
  }

  void error(
    String event, {
    String? actionPage,
    String? url,
    int? statusCode,
    Object? exception,
    StackTrace? stackTrace,
  }) {
    _logger.e(AppLogEvent(
      requestTime: DateTime.now(),
      event: event,
      actionPage: actionPage,
      url: url,
      statusCode: statusCode,
      exception: exception,
      stackTrace: stackTrace,
    ));
  }

  void fatal(
    String event, {
    String? actionPage,
    Object? exception,
    StackTrace? stackTrace,
  }) {
    _logger.f(AppLogEvent(
      requestTime: DateTime.now(),
      event: event,
      actionPage: actionPage,
      exception: exception,
      stackTrace: stackTrace,
    ));
  }

  // ─── Navigation Helpers ────────────────────────────────────────

  void screenEnter(String screenName) {
    _logger.d(AppLogEvent(
      requestTime: DateTime.now(),
      event: 'Entered screen',
      actionPage: screenName,
    ));
  }

  void screenExit(String screenName) {
    _logger.d(AppLogEvent(
      requestTime: DateTime.now(),
      event: 'Exited screen',
      actionPage: screenName,
    ));
  }
}

// ─── Convenience top-level getter ────────────────────────────────────────────

/// Quick access: `appLog.http(...)`
AppLogger get appLog => AppLogger.instance;