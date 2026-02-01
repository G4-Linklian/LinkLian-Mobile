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

  /// Helper to get current user ID from AuthController
  int? _getCurrentUserId() {
    try {
      if (Get.isRegistered<AuthController>()) {
        return Get.find<AuthController>().userId.value;
      }
    } catch (e) {
      AppLogger.info('⚠️ Cannot get userId: $e');
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
            AppLogger.info('Attach token → ${options.path}');
          } else {
            options.headers.remove('Authorization');
            AppLogger.info('🚫 Missing token → ${options.path}');
          }

          // Add x-user-id header for authenticated requests
          final userId = _getCurrentUserId();
          if (userId != null) {
            options.headers['x-user-id'] = userId.toString();
            AppLogger.info('👤 Attach x-user-id: $userId → ${options.path}');
          }
        } else {
          options.headers.remove('Authorization');
          options.headers.remove('x-user-id');
          AppLogger.info(' Public API → ${options.path}');
        }

        AppLogger.info('🌐 FULL URL: ${options.uri}');
        handler.next(options);
      },
    ),
  );
}

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      rethrow;
    }
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
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      rethrow;
    }
  }
}

extension MultipartApi on ApiClient {
  Future<Response<dynamic>> uploadMultipart(
    String path, {
    required List<File> files,
    required String fieldName,
    Map<String, dynamic>? fields,
    bool requiresAuth = true,
  }) async {
    final formData = FormData();

    for (final file in files) {
      String fileName = file.path.split('/').last;

      if (!fileName.contains('.')) {
        fileName = '$fileName.jpg';
      }

      AppLogger.info(
  ' Upload file → '
  'name=$fileName, '
  'path=${file.path}, '
  'size=${await file.length()} bytes',
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
      contentType: 'multipart/form-data',
      extra: {'requiresAuth': requiresAuth},
    );

    AppLogger.info('📤 Upload multipart → $path');

    return _dio.post(
      path,
      data: formData,
      options: options,
    );
  }
}