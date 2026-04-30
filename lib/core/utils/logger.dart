import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class AppLogEvent {
  final DateTime time;
  final String event;
  final String? actionPage;
  final String? url;
  final String? method;
  final int? statusCode;
  final int? durationMs;

  final Object? data;

  final Object? exception;
  final StackTrace? stackTrace;

  const AppLogEvent({
    required this.time,
    required this.event,
    this.actionPage,
    this.url,
    this.method,
    this.statusCode,
    this.durationMs,
    this.data,
    this.exception,
    this.stackTrace,
  });
}

class _AppLogPrinter extends LogPrinter {

  @override
  List<String> log(LogEvent event) {

    final message = event.message;

    if (message is! AppLogEvent) {
      return [message.toString()];
    }

    final data = message;

    final localTime = data.time.toLocal();
    final time =
      "${_pad(localTime.hour)}:${_pad(localTime.minute)}:${_pad(localTime.second)}";

    final lines = <String>[];

    lines.add("────────────────────────────────────────────");
    lines.add("${_icon(event.level)} ${event.level.name.toUpperCase()}");
    lines.add("Time        : $time");

    if (data.actionPage != null) {
      lines.add("Page        : ${data.actionPage}");
    }

    if (data.method != null && data.url != null) {
      lines.add("Request     : ${data.method} ${data.url}");
    }

    if (data.statusCode != null) {
      lines.add("Status      : ${data.statusCode}");
    }

    if (data.durationMs != null) {
      lines.add("Duration    : ${data.durationMs} ms");
    }

    lines.add("Event       : ${data.event}");

    /// NEW: render object data
    if (data.data != null) {

      lines.add("Data        :");

      final formatted = _formatObject(data.data!);

      for (final line in formatted.split('\n')) {
        lines.add("   $line");
      }
    }

    if (data.exception != null) {
      lines.add("Exception   : ${data.exception}");
    }

    if (data.stackTrace != null) {
      lines.add("StackTrace  :");
      final stackLines =
          data.stackTrace.toString().split('\n').take(5);

      for (final l in stackLines) {
        lines.add("   $l");
      }
    }

    lines.add("");

    return lines;
  }

  static String _pad(int v) => v.toString().padLeft(2, '0');

  String _icon(Level level) => switch (level) {
        Level.debug => "[DEBUG]",
        Level.info => "[INFO]",
        Level.warning => "[WARNING]",
        Level.error => "[ERROR]",
        Level.fatal => "[FATAL]",
        _ => "[UNKNOWN]",
      };

  /// pretty print object
  String _formatObject(Object obj) {
    try {
      return const JsonEncoder.withIndent('  ').convert(obj);
    } catch (_) {
      return obj.toString();
    }
  }
}

/// ─────────────────────────────────────────────────────────
/// Logger
/// ─────────────────────────────────────────────────────────

class AppLogger {

  AppLogger._();

  static final AppLogger instance = AppLogger._();

  late final Logger _logger = Logger(
    level: kDebugMode ? Level.debug : Level.off,
    printer: _AppLogPrinter(),
  );

  /// HTTP log
  void http({
    required String method,
    required String url,
    required int statusCode,
    required String event,
    Object? data,
    String? actionPage,
    int? durationMs,
  }) {

    final logEvent = AppLogEvent(
      time: DateTime.now().toLocal(),
      event: event,
      method: method,
      url: url,
      statusCode: statusCode,
      durationMs: durationMs,
      actionPage: actionPage,
      data: data,
    );

    if (statusCode >= 200 && statusCode < 300) {
      _logger.i(logEvent);
    } else if (statusCode >= 500) {
      _logger.e(logEvent);
    } else {
      _logger.w(logEvent);
    }
  }

  void debug(
    String event, {
    Object? data,
    String? actionPage,
  }) {
    _logger.d(
      AppLogEvent(
        time: DateTime.now().toLocal(),
        event: event,
        actionPage: actionPage,
        data: data,
      ),
    );
  }

  void warning(
  String event, {
  Object? data,
  String? actionPage,
}) {
  _logger.w(
    AppLogEvent(
      time: DateTime.now().toLocal(),
      event: event,
      actionPage: actionPage,
      data: data,
    ),
  );
}

  void info(
    String event, {
    Object? data,
    String? actionPage,
  }) {
    _logger.i(
      AppLogEvent(
        time: DateTime.now().toLocal(),
        event: event,
        actionPage: actionPage,
        data: data,
      ),
    );
  }

  void error(
    String event, {
    Object? data,
    String? actionPage,
    Object? exception,
    StackTrace? stackTrace,
  }) {
    _logger.e(
      AppLogEvent(
        time: DateTime.now().toLocal(),
        event: event,
        actionPage: actionPage,
        data: data,
        exception: exception,
        stackTrace: stackTrace,
      ),
    );
  }
}

AppLogger get appLog => AppLogger.instance;