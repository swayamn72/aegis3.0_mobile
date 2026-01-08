import 'package:dio/dio.dart';
import 'dart:io';
import 'dart:convert';
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
  /// Update user profile fields
  Future<UserProfile?> updateProfile(Map<String, dynamic> updateData) async {
    try {
      logger.d('Updating user profile...');
      final response = await _dio.put(
        '/players/update-profile',
        data: updateData,
      );
      if (response.statusCode == 200) {
        logger.d('Profile updated successfully');
        logger.d('Response data: ${response.data}');
        logger.d('Response data type: ${response.data.runtimeType}');

        // Parse response.data if it's a string
        final parsedData = response.data is String
            ? jsonDecode(response.data)
            : response.data;

        // Handle both cases: parsedData could be the player object or contain a 'player' field
        final playerData = parsedData is Map && parsedData.containsKey('player')
            ? parsedData['player']
            : parsedData;

        return UserProfile.fromJson(playerData as Map<String, dynamic>);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to update profile');
      }
    } on DioException catch (e) {
      logger.e('DioException while updating profile: ${e.response?.data}');
      throw Exception(e.response?.data['message'] ?? 'Network error');
    } catch (e) {
      logger.e('Error updating profile: $e');
      throw Exception('Unexpected error: $e');
    }
  }

  /// Upload profile picture
  Future<String?> uploadProfilePicture(File image) async {
    try {
      logger.d('Uploading profile picture...');
      final formData = FormData.fromMap({
        'profilePicture': await MultipartFile.fromFile(image.path),
      });
      final response = await _dio.post('/players/upload-pfp', data: formData);
      if (response.statusCode == 200) {
        logger.d(
          'Profile picture uploaded: ${response.data['profilePicture']}',
        );
        return response.data['profilePicture'];
      } else {
        throw Exception(
          response.data['message'] ?? 'Failed to upload profile picture',
        );
      }
    } on DioException catch (e) {
      logger.e(
        'DioException while uploading profile picture: ${e.response?.data}',
      );
      throw Exception(e.response?.data['message'] ?? 'Network error');
    } catch (e) {
      logger.e('Error uploading profile picture: $e');
      throw Exception('Unexpected error: $e');
    }
  }

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
