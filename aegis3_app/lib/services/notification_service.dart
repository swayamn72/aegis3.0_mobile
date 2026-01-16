import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../providers/core_providers.dart';

// ============================================================================
// Notification Service Provider
// ============================================================================
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref.read(dioProvider), ref.read(loggerProvider));
});

// ============================================================================
// Notification Service
// ============================================================================
class NotificationService {
  final Dio _dio;
  final Logger logger;

  NotificationService(this._dio, this.logger);

  Future<void> updateFcmToken({required String userId}) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) {
        logger.w('FCM token is null, cannot update backend');
        return;
      }
      logger.d('Preparing to update FCM token for user $userId: $token');
      logger.d('POST URL: /notifications/update-fcm-token');
      logger.d('POST DATA: {userId: $userId, fcmToken: $token}');
      final response = await _dio.post(
        '/notifications/update-fcm-token',
        data: {'userId': userId, 'fcmToken': token},
      );
      logger.d(
        'FCM token update response: ${response.statusCode} ${response.data}',
      );
    } catch (e) {
      logger.e('Error updating FCM token: $e');
    }
  }
}
