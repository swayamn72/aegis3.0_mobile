import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import '../constants/api_constants.dart';

// ============================================================================
// Secure Storage Provider
// ============================================================================
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
});

// ============================================================================
// Logger Provider
// ============================================================================
final loggerProvider = Provider<Logger>((ref) {
  return Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 50,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
    level: kDebugMode ? Level.debug : Level.error,
  );
});

// ============================================================================
// Dio Provider with Interceptors
// ============================================================================
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // Add logging interceptor in debug mode
  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        requestHeader: true,
        responseHeader: false,
        error: true,
        logPrint: (obj) {
          final logger = ref.read(loggerProvider);
          logger.d(obj);
        },
      ),
    );
  }

  // Add auth interceptor
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          final storage = ref.read(secureStorageProvider);
          final token = await storage.read(key: 'auth_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        } catch (e) {
          final logger = ref.read(loggerProvider);
          logger.e('Error reading auth token: $e');
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        final logger = ref.read(loggerProvider);

        // Handle 401 unauthorized globally
        if (error.response?.statusCode == 401) {
          logger.w('Unauthorized request - token may be invalid');
          // TODO: Trigger logout flow
          // final storage = ref.read(secureStorageProvider);
          // await storage.delete(key: 'auth_token');
          // Navigate to login screen
        }

        // Log other errors
        logger.e(
          'API Error: ${error.response?.statusCode}',
          error: error.response?.data,
        );

        return handler.next(error);
      },
      onResponse: (response, handler) {
        return handler.next(response);
      },
    ),
  );

  return dio;
});
