import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_models.dart';
import '../services/chat_service.dart';
import '../services/socket_service.dart';
import 'core_providers.dart';
import 'user_profile_provider.dart';

// ============================================================================
// Chat State
// ============================================================================
class ChatState {
  final List<ChatUser> connections;
  final List<TryoutChat> tryoutChats;
  final List<TeamApplication> teamApplications;
  final List<RecruitmentApproach> recruitmentApproaches;
  final Map<String, List<ChatMessage>> messagesByUser;
  final Set<String> onlineUserIds;
  final bool isLoading;
  final String? error;

  const ChatState({
    this.connections = const [],
    this.tryoutChats = const [],
    this.teamApplications = const [],
    this.recruitmentApproaches = const [],
    this.messagesByUser = const {},
    this.onlineUserIds = const {},
    this.isLoading = false,
    this.error,
  });

  ChatState copyWith({
    List<ChatUser>? connections,
    List<TryoutChat>? tryoutChats,
    List<TeamApplication>? teamApplications,
    List<RecruitmentApproach>? recruitmentApproaches,
    Map<String, List<ChatMessage>>? messagesByUser,
    Set<String>? onlineUserIds,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return ChatState(
      connections: connections ?? this.connections,
      tryoutChats: tryoutChats ?? this.tryoutChats,
      teamApplications: teamApplications ?? this.teamApplications,
      recruitmentApproaches:
          recruitmentApproaches ?? this.recruitmentApproaches,
      messagesByUser: messagesByUser ?? this.messagesByUser,
      onlineUserIds: onlineUserIds ?? this.onlineUserIds,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ============================================================================
// Chat Provider
// ============================================================================
final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>(
  (ref) => ChatNotifier(ref),
);

class ChatNotifier extends StateNotifier<ChatState> {
  final Ref _ref;
  bool _isInitialized = false;

  ChatNotifier(this._ref) : super(const ChatState());

  ChatService get _chatService => _ref.read(chatServiceProvider);
  SocketService get _socketService => _ref.read(socketServiceProvider);

  // ==========================================================================
  // Initialize Chat System
  // ==========================================================================
  Future<void> initialize() async {
    final profile = _ref.read(userProfileProvider).profile;
    if (profile == null) {
      _ref.read(loggerProvider).e('Cannot initialize chat: User not logged in');
      return;
    }

    try {
      _ref.read(loggerProvider).d('Initializing chat system...');

      // Connect to socket
      await _socketService.connect(profile.id);

      // Setup socket listeners only once
      if (!_isInitialized) {
        _setupSocketListeners();
      }

      // Always fetch initial data on initialization
      await fetchAllData();

      _isInitialized = true;
      _ref.read(loggerProvider).d('Chat system initialized');
    } catch (e) {
      _ref.read(loggerProvider).e('Error initializing chat: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  // ==========================================================================
  // Setup Socket Listeners
  // ==========================================================================
  void _setupSocketListeners() {
    _socketService.onMessageReceived = (message) {
      _handleNewMessage(message);
    };

    _socketService.onTryoutMessageReceived = (message, chatId) {
      _handleNewTryoutMessage(message, chatId);
    };

    _socketService.onTryoutEnded = (chatId, data) {
      _handleTryoutEnded(chatId, data);
    };

    _socketService.onTeamOfferSent = (chatId, data) {
      _handleTeamOfferSent(chatId, data);
    };

    _socketService.onTeamOfferAccepted = (chatId, data) {
      _handleTeamOfferAccepted(chatId, data);
    };

    _socketService.onTeamOfferRejected = (chatId, data) {
      _handleTeamOfferRejected(chatId, data);
    };

    _socketService.onOnlineUsersUpdate = (onlineUserIds) {
      state = state.copyWith(onlineUserIds: onlineUserIds);
    };
  }

  // ==========================================================================
  // Handle Socket Events
  // ==========================================================================
  void _handleNewMessage(ChatMessage message) {
    final currentMessages = Map<String, List<ChatMessage>>.from(
      state.messagesByUser,
    );
    final userId =
        message.senderId == _ref.read(userProfileProvider).profile?.id
        ? message.receiverId
        : message.senderId;

    currentMessages[userId] = [...(currentMessages[userId] ?? []), message];
    state = state.copyWith(messagesByUser: currentMessages);
  }

  void _handleNewTryoutMessage(TryoutMessage message, String chatId) {
    _ref
        .read(loggerProvider)
        .d('📩 Handling new tryout message for chat: $chatId');
    _ref
        .read(loggerProvider)
        .d('📩 Current tryout chats count: ${state.tryoutChats.length}');

    final updatedChats = state.tryoutChats.map((chat) {
      if (chat.id == chatId) {
        // Check for duplicates - avoid adding if message with same content and sender already exists
        final isDuplicate = chat.messages.any(
          (existingMsg) =>
              existingMsg.sender == message.sender &&
              existingMsg.message == message.message &&
              existingMsg.timestamp
                      .difference(message.timestamp)
                      .abs()
                      .inSeconds <
                  3,
        );

        if (isDuplicate) {
          _ref
              .read(loggerProvider)
              .d('📩 Duplicate message detected, skipping');
          return chat;
        }

        _ref.read(loggerProvider).d('📩 Found matching chat, adding message');
        return TryoutChat(
          id: chat.id,
          team: chat.team,
          applicant: chat.applicant,
          participants: chat.participants,
          status: chat.status,
          chatType: chat.chatType,
          messages: [...chat.messages, message],
          tryoutStatus: chat.tryoutStatus,
          teamOffer: chat.teamOffer,
          endedAt: chat.endedAt,
          endReason: chat.endReason,
          createdAt: chat.createdAt,
        );
      }
      return chat;
    }).toList();

    state = state.copyWith(tryoutChats: updatedChats);
    _ref.read(loggerProvider).d('📩 State updated with new message');
  }

  void _handleTryoutEnded(String chatId, Map<String, dynamic> data) {
    // Refresh tryout chats
    fetchTryoutChats();
  }

  void _handleTeamOfferSent(String chatId, Map<String, dynamic> data) {
    fetchTryoutChats();
  }

  void _handleTeamOfferAccepted(String chatId, Map<String, dynamic> data) {
    fetchTryoutChats();
  }

  void _handleTeamOfferRejected(String chatId, Map<String, dynamic> data) {
    fetchTryoutChats();
  }

  // ==========================================================================
  // Fetch Data
  // ==========================================================================
  Future<void> fetchAllData() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await Future.wait([
        fetchConnections(),
        fetchTryoutChats(),
        fetchTeamApplications(),
        fetchRecruitmentApproaches(),
      ]);

      state = state.copyWith(isLoading: false);
    } catch (e) {
      _ref.read(loggerProvider).e('Error fetching chat data: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchConnections() async {
    try {
      final connections = await _chatService.getUsersWithChats();
      state = state.copyWith(connections: connections);
    } catch (e) {
      _ref.read(loggerProvider).e('Error fetching connections: $e');
      rethrow;
    }
  }

  Future<void> fetchTryoutChats() async {
    try {
      _ref.read(loggerProvider).d('🔄 Fetching tryout chats...');
      final tryoutChats = await _chatService.getMyTryoutChats();
      _ref
          .read(loggerProvider)
          .d('✅ Fetched ${tryoutChats.length} tryout chats');
      state = state.copyWith(tryoutChats: tryoutChats);
      _ref.read(loggerProvider).d('✅ State updated with tryout chats');
    } catch (e) {
      _ref.read(loggerProvider).e('❌ Error fetching tryout chats: $e');
      rethrow;
    }
  }

  Future<void> fetchTeamApplications() async {
    final profile = _ref.read(userProfileProvider).profile;
    if (profile?.team?.id == null) {
      state = state.copyWith(teamApplications: []);
      return;
    }

    try {
      final applications = await _chatService.getTeamApplications(
        profile!.team!.id,
      );
      state = state.copyWith(teamApplications: applications);
    } catch (e) {
      _ref.read(loggerProvider).e('Error fetching team applications: $e');
      rethrow;
    }
  }

  Future<void> fetchRecruitmentApproaches() async {
    try {
      final approaches = await _chatService.getMyApproaches();
      state = state.copyWith(recruitmentApproaches: approaches);
    } catch (e) {
      _ref.read(loggerProvider).e('Error fetching recruitment approaches: $e');
      rethrow;
    }
  }

  // ==========================================================================
  // Fetch Messages for a User
  // ==========================================================================
  Future<List<ChatMessage>> fetchMessages(String userId) async {
    try {
      final messages = await _chatService.getMessages(userId);
      final currentMessages = Map<String, List<ChatMessage>>.from(
        state.messagesByUser,
      );
      currentMessages[userId] = messages;
      state = state.copyWith(messagesByUser: currentMessages);
      return messages;
    } catch (e) {
      _ref.read(loggerProvider).e('Error fetching messages: $e');
      rethrow;
    }
  }

  // ==========================================================================
  // Send Message
  // ==========================================================================
  void sendMessage(String receiverId, String message) {
    _socketService.sendMessage(receiverId, message);

    // Optimistic update
    final profile = _ref.read(userProfileProvider).profile;
    if (profile != null) {
      final newMessage = ChatMessage(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        senderId: profile.id,
        receiverId: receiverId,
        message: message,
        messageType: 'text',
        timestamp: DateTime.now(),
      );
      _handleNewMessage(newMessage);
    }
  }

  // ==========================================================================
  // Tryout Actions
  // ==========================================================================
  Future<TryoutChat> startTryout(String applicationId) async {
    try {
      final tryoutChat = await _chatService.startTryout(applicationId);
      await fetchTryoutChats();
      await fetchTeamApplications();
      return tryoutChat;
    } catch (e) {
      _ref.read(loggerProvider).e('Error starting tryout: $e');
      rethrow;
    }
  }

  Future<void> endTryout(String chatId, String reason) async {
    try {
      await _chatService.endTryout(chatId, reason);
      await fetchTryoutChats();
    } catch (e) {
      _ref.read(loggerProvider).e('Error ending tryout: $e');
      rethrow;
    }
  }

  Future<void> sendTeamOffer(String chatId, String? message) async {
    try {
      await _chatService.sendTeamOffer(chatId, message);
      await fetchTryoutChats();
    } catch (e) {
      _ref.read(loggerProvider).e('Error sending team offer: $e');
      rethrow;
    }
  }

  Future<void> acceptTeamOffer(String chatId) async {
    try {
      await _chatService.acceptTeamOffer(chatId);
      await fetchTryoutChats();
    } catch (e) {
      _ref.read(loggerProvider).e('Error accepting team offer: $e');
      rethrow;
    }
  }

  Future<void> rejectTeamOffer(String chatId, String? reason) async {
    try {
      await _chatService.rejectTeamOffer(chatId, reason);
      await fetchTryoutChats();
    } catch (e) {
      _ref.read(loggerProvider).e('Error rejecting team offer: $e');
      rethrow;
    }
  }

  // ==========================================================================
  // Application Actions
  // ==========================================================================
  Future<void> rejectApplication(String applicationId, String reason) async {
    try {
      await _chatService.rejectApplication(applicationId, reason);
      await fetchTeamApplications();
    } catch (e) {
      _ref.read(loggerProvider).e('Error rejecting application: $e');
      rethrow;
    }
  }

  // ==========================================================================
  // Approach Actions
  // ==========================================================================
  Future<TryoutChat> acceptApproach(String approachId) async {
    try {
      final tryoutChat = await _chatService.acceptApproach(approachId);
      await fetchRecruitmentApproaches();
      await fetchTryoutChats();
      return tryoutChat;
    } catch (e) {
      _ref.read(loggerProvider).e('Error accepting approach: $e');
      rethrow;
    }
  }

  Future<void> rejectApproach(String approachId, String reason) async {
    try {
      await _chatService.rejectApproach(approachId, reason);
      await fetchRecruitmentApproaches();
    } catch (e) {
      _ref.read(loggerProvider).e('Error rejecting approach: $e');
      rethrow;
    }
  }

  // ==========================================================================
  // Invitation Actions
  // ==========================================================================
  Future<void> acceptInvitation(String invitationId) async {
    try {
      await _chatService.acceptInvitation(invitationId);
      await fetchMessages('system');
    } catch (e) {
      _ref.read(loggerProvider).e('Error accepting invitation: $e');
      rethrow;
    }
  }

  Future<void> declineInvitation(String invitationId) async {
    try {
      await _chatService.declineInvitation(invitationId);
      await fetchMessages('system');
    } catch (e) {
      _ref.read(loggerProvider).e('Error declining invitation: $e');
      rethrow;
    }
  }

  // ==========================================================================
  // Join/Leave Tryout Chat
  // ==========================================================================
  void joinTryoutChat(String chatId) {
    _ref.read(loggerProvider).d('🔗 Provider: Joining tryout chat $chatId');
    _socketService.joinTryoutChat(chatId);
  }

  void leaveTryoutChat(String chatId) {
    _socketService.leaveTryoutChat(chatId);
  }

  void sendTryoutMessage(String chatId, String message) {
    final profile = _ref.read(userProfileProvider).profile;
    if (profile == null) {
      _ref.read(loggerProvider).e('❌ Cannot send tryout message: No profile');
      return;
    }

    _ref.read(loggerProvider).d('📤 Sending tryout message from provider');
    _socketService.sendTryoutMessage(chatId, message, profile.id);

    // Optimistic update
    final tempMessage = TryoutMessage(
      sender: profile.id,
      message: message,
      messageType: 'text',
      timestamp: DateTime.now(),
    );
    _handleNewTryoutMessage(tempMessage, chatId);
  }

  // ==========================================================================
  // Cleanup
  // ==========================================================================
  @override
  void dispose() {
    _socketService.clearCallbacks();
    _socketService.disconnect();
    super.dispose();
  }
}
