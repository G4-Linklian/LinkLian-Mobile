import 'package:dio/dio.dart';
import '../utils/logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'local_storage.dart';
import 'dart:io';
import 'package:http_parser/http_parser.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;
import '../../features/auth/controller/auth_controller.dart';

class ApiClient {
  static final String baseUrl =
      '${dotenv.env['BASE_URL']}${dotenv.env['BASE_PATH']}';
  late final Dio _dio;

  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _setupInterceptors();
  }

  int? _getCurrentUserId() {
    try {
      if (Get.isRegistered<AuthController>()) {
        return Get.find<AuthController>().userId.value;
      }
    } catch (e) {
      // ✅ ใช้ appLog แทน AppLogger.warning(...)
      appLog.warning('Cannot get userId: $e', actionPage: 'ApiClient');
    }
    return null;
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final extra = options.extra;
          final requiresAuth = extra['requiresAuth'] ?? true;

          if (requiresAuth) {
            final token = await LocalStorage.getToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            } else {
              options.headers.remove('Authorization');
              appLog.warning(
                'Missing token — request will be sent without Authorization',
                actionPage: 'ApiClient',
                url: options.path,
              );
            }

            final userId = _getCurrentUserId();
            if (userId != null) {
              options.headers['x-user-id'] = userId.toString();
            }
          } else {
            options.headers.remove('Authorization');
            options.headers.remove('x-user-id');
          }

          options.extra['_startTime'] = DateTime.now().millisecondsSinceEpoch;

          // ✅ Log request เริ่มต้น (ยังไม่มี statusCode, ใช้ info แทน)
          appLog.info(
            '${options.method} request sent',
            url: options.path,
            actionPage: 'ApiClient',
          );

          handler.next(options);
        },

        onResponse: (response, handler) {
          final startTime = response.requestOptions.extra['_startTime'];
          final durationMs = startTime != null
              ? DateTime.now().millisecondsSinceEpoch - (startTime as int)
              : 0;

          // ✅ ใช้ appLog.http สำหรับ response สำเร็จ
          appLog.http(
            method: response.requestOptions.method,
            url: response.requestOptions.path,
            statusCode: response.statusCode ?? 0,
            durationMs: durationMs,
            event: _resolveResponseEvent(response.statusCode ?? 0),
            actionPage: 'ApiClient',
          );

          handler.next(response);
        },

        onError: (error, handler) {
          final startTime = error.requestOptions.extra['_startTime'];
          final durationMs = startTime != null
              ? DateTime.now().millisecondsSinceEpoch - (startTime as int)
              : 0;

          final statusCode = error.response?.statusCode ?? 0;

          // ✅ ใช้ appLog.http สำหรับ error response
          appLog.http(
            method: error.requestOptions.method,
            url: error.requestOptions.path,
            statusCode: statusCode,
            durationMs: durationMs,
            event: error.message ?? 'Request failed',
            actionPage: 'ApiClient',
          );

          handler.next(error);
        },
      ),
    );
  }

  // ─── HTTP Methods ──────────────────────────────────────────────

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    bool requiresAuth = true,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final requestOptions = options ?? Options();
    requestOptions.extra ??= {};
    requestOptions.extra!['requiresAuth'] = requiresAuth;

    return await _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: requestOptions,
    );
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  // ─── Internal Helpers ──────────────────────────────────────────

  /// แปลง statusCode เป็น event message อัตโนมัติ
  String _resolveResponseEvent(int code) {
    if (code >= 200 && code < 300) return 'Response received successfully';
    if (code == 400) return 'Bad request — check request body';
    if (code == 401) return 'Unauthorized — token may be expired';
    if (code == 403) return 'Forbidden — insufficient permissions';
    if (code == 404) return 'Resource not found';
    if (code == 422) return 'Validation error';
    if (code == 429) return 'Too many requests — rate limited';
    if (code >= 500) return 'Server error';
    return 'Response received';
  }
}

// ─── Multipart Upload Extension ────────────────────────────────────────────────

extension MultipartApi on ApiClient {
  Future<Response<dynamic>> uploadMultipart(
    String path, {
    String method = 'POST', 
    required List<File> files,
    required String fieldName,
    Map<String, dynamic>? fields,
    bool requiresAuth = true,
    String? actionPage, // ✅ รับ actionPage เพื่อ log ให้ตรงกับ page ที่เรียก
  }) async {
    final formData = FormData();

    for (final file in files) {
      String fileName = file.path.split('/').last;
      if (!fileName.contains('.')) {
        fileName = '$fileName.jpg';
      }

      final fileSize = await file.length();

      // ✅ ใช้ appLog.info พร้อม actionPage
      appLog.info(
        'Uploading file → name=$fileName, size=$fileSize bytes',
        actionPage: actionPage ?? 'ApiClient',
        url: path,
      );

      formData.files.add(
        MapEntry(
          fieldName,
          await MultipartFile.fromFile(
            file.path,
            filename: fileName,
            contentType: MediaType('image', 'jpeg'),
          ),
        ),
      );
    }

    if (fields != null) {
      fields.forEach((key, value) {
        formData.fields.add(MapEntry(key, value.toString()));
      });
    }

    final options = Options(
      method: method,
      contentType: 'multipart/form-data',
      extra: {'requiresAuth': requiresAuth},
    );

    AppLogger.info('📤 Upload multipart → $path');

    return _dio.request(
      path,
      data: formData,
      options: options,
    );
  }
}