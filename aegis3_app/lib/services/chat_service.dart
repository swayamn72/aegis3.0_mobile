import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../models/chat_models.dart';
import '../providers/core_providers.dart';

// ============================================================================
// Chat Service Provider
// ============================================================================
final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService(ref.read(dioProvider), ref.read(loggerProvider));
});

// ============================================================================
// Chat Service
// ============================================================================
class ChatService {
  final Dio _dio;
  final Logger _logger;

  ChatService(this._dio, this._logger);

  // ==========================================================================
  // Get Users with Chats
  // ==========================================================================
  Future<List<ChatUser>> getUsersWithChats() async {
    try {
      _logger.d('Fetching users with chats...');
      final response = await _dio.get('/chat/users/with-chats');

      if (response.statusCode == 200) {
        final users = (response.data['users'] as List)
            .map((u) => ChatUser.fromJson(u))
            .toList();
        _logger.d('Fetched ${users.length} chat users');
        return users;
      } else {
        throw Exception('Failed to fetch users with chats');
      }
    } on DioException catch (e) {
      _logger.e('Error fetching chat users: ${e.response?.data}');
      throw Exception(
          e.response?.data['error'] ?? 'Failed to fetch chat users');
    }
  }

  // ==========================================================================
  // Get Messages with a User
  // ==========================================================================
  Future<List<ChatMessage>> getMessages(
    String receiverId, {
    int limit = 50,
    DateTime? before,
  }) async {
    try {
      _logger.d('Fetching messages with user: $receiverId');
      final queryParams = <String, dynamic>{
        'limit': limit,
        if (before != null) 'before': before.toIso8601String(),
      };

      final response = await _dio.get(
        '/chat/$receiverId',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final messages = (response.data as List)
            .map((m) => ChatMessage.fromJson(m))
            .toList();
        _logger.d('Fetched ${messages.length} messages');
        return messages;
      } else {
        throw Exception('Failed to fetch messages');
      }
    } on DioException catch (e) {
      _logger.e('Error fetching messages: ${e.response?.data}');
      throw Exception(e.response?.data['message'] ?? 'Failed to fetch messages');
    }
  }

  // ==========================================================================
  // Get System Messages
  // ==========================================================================
  Future<List<ChatMessage>> getSystemMessages({
    int limit = 50,
    DateTime? before,
  }) async {
    try {
      _logger.d('Fetching system messages...');
      final queryParams = <String, dynamic>{
        'limit': limit,
        if (before != null) 'before': before.toIso8601String(),
      };

      final response = await _dio.get(
        '/chat/system',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final messages = (response.data as List)
            .map((m) => ChatMessage.fromJson(m))
            .toList();
        _logger.d('Fetched ${messages.length} system messages');
        return messages;
      } else {
        throw Exception('Failed to fetch system messages');
      }
    } on DioException catch (e) {
      _logger.e('Error fetching system messages: ${e.response?.data}');
      throw Exception(
          e.response?.data['message'] ?? 'Failed to fetch system messages');
    }
  }

  // ==========================================================================
  // Accept/Decline Team Invitation
  // ==========================================================================
  Future<void> acceptInvitation(String invitationId) async {
    try {
      _logger.d('Accepting invitation: $invitationId');
      await _dio.post('/teams/invitations/$invitationId/accept');
      _logger.d('Invitation accepted');
    } on DioException catch (e) {
      _logger.e('Error accepting invitation: ${e.response?.data}');
      throw Exception(
          e.response?.data['message'] ?? 'Failed to accept invitation');
    }
  }

  Future<void> declineInvitation(String invitationId) async {
    try {
      _logger.d('Declining invitation: $invitationId');
      await _dio.post('/teams/invitations/$invitationId/decline');
      _logger.d('Invitation declined');
    } on DioException catch (e) {
      _logger.e('Error declining invitation: ${e.response?.data}');
      throw Exception(
          e.response?.data['message'] ?? 'Failed to decline invitation');
    }
  }

  // ==========================================================================
  // Tryout Chat Endpoints
  // ==========================================================================
  Future<List<TryoutChat>> getMyTryoutChats({int limit = 20}) async {
    try {
      _logger.d('Fetching tryout chats...');
      final response = await _dio.get(
        '/tryout-chats/my-chats',
        queryParameters: {'limit': limit},
      );

      if (response.statusCode == 200) {
        final chats = (response.data['chats'] as List)
            .map((c) => TryoutChat.fromJson(c))
            .toList();
        _logger.d('Fetched ${chats.length} tryout chats');
        return chats;
      } else {
        throw Exception('Failed to fetch tryout chats');
      }
    } on DioException catch (e) {
      _logger.e('Error fetching tryout chats: ${e.response?.data}');
      throw Exception(
          e.response?.data['error'] ?? 'Failed to fetch tryout chats');
    }
  }

  Future<TryoutChat> getTryoutChat(String chatId) async {
    try {
      _logger.d('Fetching tryout chat: $chatId');
      final response = await _dio.get('/tryout-chats/$chatId');

      if (response.statusCode == 200) {
        _logger.d('Fetched tryout chat');
        return TryoutChat.fromJson(response.data['chat']);
      } else {
        throw Exception('Failed to fetch tryout chat');
      }
    } on DioException catch (e) {
      _logger.e('Error fetching tryout chat: ${e.response?.data}');
      throw Exception(e.response?.data['error'] ?? 'Failed to fetch chat');
    }
  }

  Future<void> endTryout(String chatId, String reason) async {
    try {
      _logger.d('Ending tryout: $chatId');
      await _dio.post('/tryout-chats/$chatId/end-tryout', data: {'reason': reason});
      _logger.d('Tryout ended');
    } on DioException catch (e) {
      _logger.e('Error ending tryout: ${e.response?.data}');
      throw Exception(e.response?.data['error'] ?? 'Failed to end tryout');
    }
  }

  Future<void> sendTeamOffer(String chatId, String? message) async {
    try {
      _logger.d('Sending team offer to chat: $chatId');
      await _dio.post('/tryout-chats/$chatId/send-offer', data: {'message': message});
      _logger.d('Team offer sent');
    } on DioException catch (e) {
      _logger.e('Error sending team offer: ${e.response?.data}');
      throw Exception(e.response?.data['error'] ?? 'Failed to send offer');
    }
  }

  Future<void> acceptTeamOffer(String chatId) async {
    try {
      _logger.d('Accepting team offer for chat: $chatId');
      await _dio.post('/tryout-chats/$chatId/accept-offer');
      _logger.d('Team offer accepted');
    } on DioException catch (e) {
      _logger.e('Error accepting team offer: ${e.response?.data}');
      throw Exception(e.response?.data['error'] ?? 'Failed to accept offer');
    }
  }

  Future<void> rejectTeamOffer(String chatId, String? reason) async {
    try {
      _logger.d('Rejecting team offer for chat: $chatId');
      await _dio.post('/tryout-chats/$chatId/reject-offer', data: {'reason': reason});
      _logger.d('Team offer rejected');
    } on DioException catch (e) {
      _logger.e('Error rejecting team offer: ${e.response?.data}');
      throw Exception(e.response?.data['error'] ?? 'Failed to reject offer');
    }
  }

  // ==========================================================================
  // Team Applications
  // ==========================================================================
  Future<List<TeamApplication>> getTeamApplications(String teamId) async {
    try {
      _logger.d('Fetching team applications for team: $teamId');
      final response = await _dio.get('/team-applications/team/$teamId');

      if (response.statusCode == 200) {
        final applications = (response.data['applications'] as List)
            .map((a) => TeamApplication.fromJson(a))
            .toList();
        _logger.d('Fetched ${applications.length} applications');
        return applications;
      } else {
        throw Exception('Failed to fetch applications');
      }
    } on DioException catch (e) {
      _logger.e('Error fetching applications: ${e.response?.data}');
      throw Exception(
          e.response?.data['error'] ?? 'Failed to fetch applications');
    }
  }

  Future<TryoutChat> startTryout(String applicationId) async {
    try {
      _logger.d('Starting tryout for application: $applicationId');
      final response =
          await _dio.post('/team-applications/$applicationId/start-tryout');

      if (response.statusCode == 200) {
        _logger.d('Tryout started');
        return TryoutChat.fromJson(response.data['tryoutChat']);
      } else {
        throw Exception('Failed to start tryout');
      }
    } on DioException catch (e) {
      _logger.e('Error starting tryout: ${e.response?.data}');
      throw Exception(e.response?.data['error'] ?? 'Failed to start tryout');
    }
  }

  Future<void> rejectApplication(String applicationId, String reason) async {
    try {
      _logger.d('Rejecting application: $applicationId');
      await _dio.post('/team-applications/$applicationId/reject',
          data: {'reason': reason});
      _logger.d('Application rejected');
    } on DioException catch (e) {
      _logger.e('Error rejecting application: ${e.response?.data}');
      throw Exception(
          e.response?.data['error'] ?? 'Failed to reject application');
    }
  }

  // ==========================================================================
  // Recruitment Approaches
  // ==========================================================================
  Future<List<RecruitmentApproach>> getMyApproaches() async {
    try {
      _logger.d('Fetching recruitment approaches...');
      final response = await _dio.get('/recruitment/my-approaches');

      if (response.statusCode == 200) {
        final approaches = (response.data['approaches'] as List)
            .map((a) => RecruitmentApproach.fromJson(a))
            .toList();
        _logger.d('Fetched ${approaches.length} approaches');
        return approaches;
      } else {
        throw Exception('Failed to fetch approaches');
      }
    } on DioException catch (e) {
      _logger.e('Error fetching approaches: ${e.response?.data}');
      throw Exception(
          e.response?.data['error'] ?? 'Failed to fetch approaches');
    }
  }

  Future<TryoutChat> acceptApproach(String approachId) async {
    try {
      _logger.d('Accepting recruitment approach: $approachId');
      final response =
          await _dio.post('/recruitment/approach/$approachId/accept');

      if (response.statusCode == 200) {
        _logger.d('Approach accepted, tryout chat created');
        return TryoutChat.fromJson(response.data['tryoutChat']);
      } else {
        throw Exception('Failed to accept approach');
      }
    } on DioException catch (e) {
      _logger.e('Error accepting approach: ${e.response?.data}');
      throw Exception(e.response?.data['error'] ?? 'Failed to accept approach');
    }
  }

  Future<void> rejectApproach(String approachId, String reason) async {
    try {
      _logger.d('Rejecting recruitment approach: $approachId');
      await _dio.post('/recruitment/approach/$approachId/reject',
          data: {'reason': reason});
      _logger.d('Approach rejected');
    } on DioException catch (e) {
      _logger.e('Error rejecting approach: ${e.response?.data}');
      throw Exception(e.response?.data['error'] ?? 'Failed to reject approach');
    }
  }
}