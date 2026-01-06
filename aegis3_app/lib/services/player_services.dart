import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../models/user_profile.dart';
import '../providers/core_providers.dart';

// ============================================================================
// Player Service Provider
// ============================================================================
final playerServiceProvider = Provider<PlayerService>((ref) {
  return PlayerService(ref.read(dioProvider), ref.read(loggerProvider));
});

// ============================================================================
// Player Service
// ============================================================================
class PlayerService {
  final Dio _dio;
  final Logger logger;

  PlayerService(this._dio, this.logger);

  Future<UserProfile?> fetchCurrentUserProfile() async {
    try {
      logger.d('Fetching current user profile...');

      final response = await _dio.get('/players/me');

      if (response.statusCode == 200) {
        logger.d('Profile fetched successfully');
        logger.d('Profile picture URL: ${response.data['profilePicture']}');
        return UserProfile.fromJson(response.data);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch profile');
      }
    } on DioException catch (e) {
      logger.e('DioException while fetching profile: ${e.response?.data}');
      throw Exception(e.response?.data['message'] ?? 'Network error');
    } catch (e) {
      logger.e('Error parsing profile: $e');
      throw Exception('Unexpected error: $e');
    }
  }
}
