import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../providers/core_providers.dart';
import 'token_manager.dart';

// ============================================================================
// Auth Service Provider
// ============================================================================
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    ref.read(dioProvider),
    ref.read(tokenManagerProvider),
    ref.read(loggerProvider),
  );
});

// ============================================================================
// Auth Service
// ============================================================================
class AuthService {
  final Dio _dio;
  final TokenManager _tokenManager;
  final Logger logger;

  AuthService(this._dio, this._tokenManager, this.logger);

  Future<void> logout() async {
    try {
      logger.d('Logging out user...');
      await _tokenManager.clearToken();
      logger.d('User logged out successfully');
    } catch (e) {
      logger.e('Error during logout: $e');
      rethrow;
    }
  }

  Future<String?> loginPlayer({
    required String email,
    required String password,
  }) async {
    try {
      logger.d('Attempting login for: $email');

      final response = await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final token = response.data['token'];
        await _tokenManager.setToken(token);
        logger.d('Login successful');
        return null; // Success
      } else {
        final errorMsg = response.data['message'] ?? 'Login failed';
        logger.w('Login failed: $errorMsg');
        return errorMsg;
      }
    } on DioException catch (e) {
      final errorMsg = e.response?.data['message'] ?? 'Network error';
      logger.e('Login error: $errorMsg');
      return errorMsg;
    } catch (e) {
      logger.e('Unexpected login error: $e');
      return 'Unexpected error';
    }
  }

  Future<String?> signupPlayer({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      logger.d('Attempting signup for: $email');

      final response = await _dio.post(
        '/auth/signup',
        data: {'username': username, 'email': email, 'password': password},
      );

      if (response.statusCode == 201) {
        final token = response.data['token'];
        await _tokenManager.setToken(token);
        logger.d('Signup successful');
        return null; // Success
      } else {
        final errorMsg = response.data['message'] ?? 'Signup failed';
        logger.w('Signup failed: $errorMsg');
        return errorMsg;
      }
    } on DioException catch (e) {
      final errorMsg = e.response?.data['message'] ?? 'Network error';
      logger.e('Signup error: $errorMsg');
      return errorMsg;
    } catch (e) {
      logger.e('Unexpected signup error: $e');
      return 'Unexpected error';
    }
  }
}
