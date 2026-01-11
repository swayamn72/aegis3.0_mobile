import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../models/team_model.dart';
import '../providers/core_providers.dart';

// ============================================================================
// Team Service Provider
// ============================================================================
final teamServiceProvider = Provider<TeamService>((ref) {
  return TeamService(ref.read(dioProvider), ref.read(loggerProvider));
});

// ============================================================================
// Team Service
// ============================================================================
class TeamService {
  final Dio _dio;
  final Logger logger;

  TeamService(this._dio, this.logger);

  // ==========================================================================
  // GET Team by ID
  // ==========================================================================
  Future<TeamDataResponse> getTeamById(String teamId) async {
    try {
      logger.d('Fetching team data for ID: $teamId');

      final response = await _dio.get('/teams/$teamId');

      if (response.statusCode == 200) {
        logger.d('Team data fetched successfully');
        return TeamDataResponse.fromJson(response.data);
      } else {
        throw Exception('Failed to fetch team data');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        logger.w('Team profile is private');
        throw Exception(
          e.response?.data['message'] ?? 'This team profile is private',
        );
      }
      if (e.response?.statusCode == 404) {
        logger.w('Team not found');
        throw Exception('Team not found');
      }
      logger.e('Error fetching team: ${e.message}');
      throw Exception(e.response?.data['message'] ?? 'Failed to fetch team');
    } catch (e) {
      logger.e('Unexpected error fetching team: $e');
      throw Exception('Failed to fetch team data');
    }
  }

  // ==========================================================================
  // GET Team Invitations (Received)
  // ==========================================================================
  Future<List<TeamInvitation>> getReceivedInvitations() async {
    try {
      logger.d('Fetching received team invitations');

      final response = await _dio.get('/teams/invitations/received');

      if (response.statusCode == 200) {
        final invitations = (response.data['invitations'] as List)
            .map((i) => TeamInvitation.fromJson(i))
            .toList();
        logger.d('Fetched ${invitations.length} invitations');
        return invitations;
      } else {
        throw Exception('Failed to fetch invitations');
      }
    } on DioException catch (e) {
      logger.e('Error fetching invitations: ${e.message}');
      throw Exception(
        e.response?.data['message'] ?? 'Failed to fetch invitations',
      );
    }
  }

  // ==========================================================================
  // POST Create Team
  // ==========================================================================
  Future<Team> createTeam({
    required String teamName,
    String? teamTag,
    String primaryGame = 'BGMI',
    String region = 'India',
    String? bio,
    String? logo,
  }) async {
    try {
      logger.d('Creating new team: $teamName');

      final response = await _dio.post(
        '/teams',
        data: {
          'teamName': teamName,
          'teamTag': teamTag,
          'primaryGame': primaryGame,
          'region': region,
          'bio': bio,
          'logo': logo,
        },
      );

      if (response.statusCode == 201) {
        logger.d('Team created successfully');
        return Team.fromJson(response.data['team']);
      } else {
        throw Exception('Failed to create team');
      }
    } on DioException catch (e) {
      logger.e('Error creating team: ${e.message}');
      throw Exception(e.response?.data['message'] ?? 'Failed to create team');
    }
  }

  // ==========================================================================
  // POST Accept Team Invitation
  // ==========================================================================
  Future<Team> acceptInvitation(String invitationId) async {
    try {
      logger.d('Accepting invitation: $invitationId');

      final response = await _dio.post(
        '/teams/invitations/$invitationId/accept',
      );

      if (response.statusCode == 200) {
        logger.d('Invitation accepted successfully');
        return Team.fromJson(response.data['team']);
      } else {
        throw Exception('Failed to accept invitation');
      }
    } on DioException catch (e) {
      logger.e('Error accepting invitation: ${e.message}');
      throw Exception(
        e.response?.data['message'] ?? 'Failed to accept invitation',
      );
    }
  }

  // ==========================================================================
  // POST Decline Team Invitation
  // ==========================================================================
  Future<void> declineInvitation(String invitationId) async {
    try {
      logger.d('Declining invitation: $invitationId');

      final response = await _dio.post(
        '/teams/invitations/$invitationId/decline',
      );

      if (response.statusCode == 200) {
        logger.d('Invitation declined successfully');
      } else {
        throw Exception('Failed to decline invitation');
      }
    } on DioException catch (e) {
      logger.e('Error declining invitation: ${e.message}');
      throw Exception(
        e.response?.data['message'] ?? 'Failed to decline invitation',
      );
    }
  }

  // ==========================================================================
  // DELETE Remove Player from Team (Kick or Leave)
  // ==========================================================================
  Future<void> removePlayerFromTeam({
    required String teamId,
    required String playerId,
  }) async {
    try {
      logger.d('Removing player $playerId from team $teamId');

      final response = await _dio.delete('/teams/$teamId/players/$playerId');

      if (response.statusCode == 200) {
        logger.d('Player removed successfully');
      } else {
        throw Exception('Failed to remove player');
      }
    } on DioException catch (e) {
      logger.e('Error removing player: ${e.message}');
      throw Exception(e.response?.data['message'] ?? 'Failed to remove player');
    }
  }

  // ==========================================================================
  // PUT Update Team
  // ==========================================================================
  Future<Team> updateTeam({
    required String teamId,
    String? teamName,
    String? teamTag,
    String? bio,
    String? status,
    Map<String, String>? socials,
    String? profileVisibility,
  }) async {
    try {
      logger.d('Updating team: $teamId');

      final data = <String, dynamic>{};
      if (teamName != null) data['teamName'] = teamName;
      if (teamTag != null) data['teamTag'] = teamTag;
      if (bio != null) data['bio'] = bio;
      if (status != null) data['status'] = status;
      if (socials != null) data['socials'] = socials;
      if (profileVisibility != null) {
        data['profileVisibility'] = profileVisibility;
      }

      final response = await _dio.put('/teams/$teamId', data: {'data': data});

      if (response.statusCode == 200) {
        logger.d('Team updated successfully');
        return Team.fromJson(response.data['team']);
      } else {
        throw Exception('Failed to update team');
      }
    } on DioException catch (e) {
      logger.e('Error updating team: ${e.message}');
      throw Exception(e.response?.data['message'] ?? 'Failed to update team');
    }
  }

  // ==========================================================================
  // PUT Upload Team Logo
  // ==========================================================================
  Future<Team> uploadTeamLogo({
    required String teamId,
    required File logoFile,
  }) async {
    try {
      logger.d('Uploading team logo for team: $teamId');

      final formData = FormData.fromMap({
        'logo': await MultipartFile.fromFile(
          logoFile.path,
          filename: 'team_logo.jpg',
        ),
      });

      final response = await _dio.put('/teams/$teamId', data: formData);

      if (response.statusCode == 200) {
        logger.d('Team logo uploaded successfully');
        return Team.fromJson(response.data['team']);
      } else {
        throw Exception('Failed to upload logo');
      }
    } on DioException catch (e) {
      logger.e('Error uploading logo: ${e.message}');
      throw Exception(e.response?.data['message'] ?? 'Failed to upload logo');
    }
  }

  // ==========================================================================
  // GET Search Teams and Players
  // ==========================================================================
  Future<SearchResults> search({
    required String query,
    String? game,
    String? region,
    int limit = 20,
    String searchType = 'all',
  }) async {
    try {
      logger.d('Searching for: $query');

      final queryParams = <String, dynamic>{
        'limit': limit,
        'searchType': searchType,
      };
      if (game != null) queryParams['game'] = game;
      if (region != null) queryParams['region'] = region;

      final response = await _dio.get(
        '/teams/search/$query',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        logger.d('Search completed successfully');
        return SearchResults.fromJson(response.data);
      } else {
        throw Exception('Search failed');
      }
    } on DioException catch (e) {
      logger.e('Error searching: ${e.message}');
      throw Exception(e.response?.data['message'] ?? 'Search failed');
    }
  }

  // ==========================================================================
  // POST Send Team Invitation
  // ==========================================================================
  Future<TeamInvitation> sendInvitation({
    required String teamId,
    required String playerId,
    String? message,
  }) async {
    try {
      logger.d('Sending invitation to player: $playerId');

      final response = await _dio.post(
        '/teams/$teamId/invite',
        data: {'playerId': playerId, 'message': message},
      );

      if (response.statusCode == 201) {
        logger.d('Invitation sent successfully');
        return TeamInvitation.fromJson(response.data['invitation']);
      } else {
        throw Exception('Failed to send invitation');
      }
    } on DioException catch (e) {
      logger.e('Error sending invitation: ${e.message}');
      throw Exception(
        e.response?.data['message'] ?? 'Failed to send invitation',
      );
    }
  }

  // ==========================================================================
  // GET Browse Teams (with pagination)
  // ==========================================================================
  Future<Map<String, dynamic>> browseTeams({
    int page = 1,
    int limit = 10,
    String? game,
    String? region,
    String status = 'active',
  }) async {
    try {
      logger.d('Browsing teams - page: $page');

      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        'status': status,
      };
      if (game != null) queryParams['game'] = game;
      if (region != null) queryParams['region'] = region;

      final response = await _dio.get('/teams', queryParameters: queryParams);

      if (response.statusCode == 200) {
        final teams = (response.data['teams'] as List)
            .map((t) => Team.fromJson(t))
            .toList();
        return {
          'teams': teams,
          'totalPages': response.data['totalPages'] ?? 1,
          'currentPage': response.data['currentPage'] ?? 1,
        };
      } else {
        throw Exception('Failed to browse teams');
      }
    } on DioException catch (e) {
      logger.e('Error browsing teams: ${e.message}');
      throw Exception(e.response?.data['message'] ?? 'Failed to browse teams');
    }
  }
}
