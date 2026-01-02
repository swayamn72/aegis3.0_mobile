import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';

class AuthService {
  Future<String?> loginPlayer({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final token = response.data['token'];
        await _storage.write(key: 'auth_token', value: token);
        return null; // Success
      } else {
        return response.data['message'] ?? 'Login failed';
      }
    } on DioException catch (e) {
      return e.response?.data['message'] ?? 'Network error';
    } catch (e) {
      return 'Unexpected error';
    }
  }

  final Dio _dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<String?> signupPlayer({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/signup',
        data: {'username': username, 'email': email, 'password': password},
      );

      if (response.statusCode == 201) {
        final token = response.data['token'];
        await _storage.write(key: 'auth_token', value: token);
        return null; // Success
      } else {
        return response.data['message'] ?? 'Signup failed';
      }
    } on DioException catch (e) {
      return e.response?.data['message'] ?? 'Network error';
    } catch (e) {
      return 'Unexpected error';
    }
  }
}
