import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_models.dart';
import '../providers/chat_provider.dart';
import '../providers/user_profile_provider.dart';

import '../widgets/profile_avatar.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../main.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  String? _selectedUserId;
  String? _selectedChatId;
  String _chatType = 'direct'; // 'direct' or 'tryout'
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _showApplications = false;
  bool _chatInitialized = false;

  @override
  void initState() {
    super.initState();

    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;
      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel',
              'High Importance Notifications',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );
      }
    });

    // Print FCM token for testing
    FirebaseMessaging.instance.getToken().then((token) {
      print('FCM Token: ' + (token ?? 'No token'));
    });
  }

  void _initializeChatIfNeeded() {
    final profile = ref.read(userProfileProvider).profile;
    if (profile != null && !_chatInitialized) {
      _chatInitialized = true;
      Future.microtask(() {
        ref.read(chatProvider.notifier).initialize();
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final profile = ref.watch(userProfileProvider).profile;

    // Initialize chat once profile is loaded
    _initializeChatIfNeeded();

    if (profile == null) {
      return const Scaffold(
        backgroundColor: const Color(0xFF09090b),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Show chat window when a chat is selected, otherwise show list
    if (_selectedUserId != null || _selectedChatId != null) {
      return _buildChatWindow(chatState, profile);
    }

    return Scaffold(
      backgroundColor: const Color(0xFF09090b),
      body: SafeArea(
        child: Column(
          children: [
            _buildChatListHeader(chatState),
            _buildSearchBar(),
            Expanded(child: _buildChatList(chatState, profile)),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // Chat List Header
  // ==========================================================================
  Widget _buildChatListHeader(ChatState chatState) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFF06b6d4), Color(0xFF7c3aed)],
            ).createShader(bounds),
            child: const Text(
              'Messages',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          Row(
            children: [
              if (chatState.teamApplications.isNotEmpty)
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.group_add, color: Colors.white),
                      onPressed: () {
                        setState(() => _showApplications = true);
                      },
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFef4444),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${chatState.teamApplications.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white),
                onPressed: () {
                  // TODO: Settings
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // Search Bar
  // ==========================================================================
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search conversations...',
          hintStyle: const TextStyle(color: Color(0xFF71717a)),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF71717a)),
          filled: true,
          fillColor: const Color(0xFF27272a),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  // ==========================================================================
  // Chat List
  // ==========================================================================
  Widget _buildChatList(ChatState chatState, profile) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      children: [
        // Tryout Chats Section
        if (chatState.tryoutChats.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.groups, color: Color(0xFF06b6d4), size: 16),
                const SizedBox(width: 8),
                Text(
                  'Active Tryouts',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ...chatState.tryoutChats.map((chat) {
            return _buildTryoutChatItem(chat);
          }),
          const Divider(color: Color(0xFF27272a)),
        ],
        // Direct Chats
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            'Direct Messages',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...chatState.connections.map((user) {
          return _buildDirectChatItem(user, chatState);
        }),
      ],
    );
  }

  Widget _buildTryoutChatItem(TryoutChat chat) {
    final isSelected = _selectedChatId == chat.id && _chatType == 'tryout';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF06b6d4).withOpacity(0.2)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(color: const Color(0xFF06b6d4).withOpacity(0.5))
            : null,
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: chat.team.logo != null && chat.team.logo!.isNotEmpty
              ? NetworkImage(chat.team.logo!)
              : null,
          backgroundColor: const Color(0xFF06b6d4),
          child: chat.team.logo == null || chat.team.logo!.isEmpty
              ? Text(
                  chat.team.teamName[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white),
                )
              : null,
        ),
        title: Text(
          '${chat.team.teamName} Tryout',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          'with ${chat.applicant.username}',
          style: const TextStyle(color: Color(0xFF71717a), fontSize: 12),
        ),
        trailing: _getTryoutStatusBadge(chat.tryoutStatus),
        onTap: () {
          setState(() {
            _selectedChatId = chat.id;
            _selectedUserId = null;
            _chatType = 'tryout';
          });
          ref.read(chatProvider.notifier).joinTryoutChat(chat.id);
        },
      ),
    );
  }

  Widget _buildDirectChatItem(ChatUser user, ChatState chatState) {
    final isSelected = _selectedUserId == user.id && _chatType == 'direct';
    final isOnline = chatState.onlineUserIds.contains(user.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF06b6d4).withOpacity(0.2)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(color: const Color(0xFF06b6d4).withOpacity(0.5))
            : null,
      ),
      child: ListTile(
        leading: Stack(
          children: [
            ProfileAvatar(
              imageUrl: user.profilePicture,
              fallbackText: user.username,
              size: 40,
            ),
            if (user.id != 'system')
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: isOnline
                        ? const Color(0xFF22c55e)
                        : const Color(0xFF71717a),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF18181b),
                      width: 2,
                    ),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          user.inGameName ?? user.username,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: user.lastMessage != null
            ? Text(
                user.lastMessage!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF71717a), fontSize: 12),
              )
            : null,
        trailing: user.lastMessageTime != null
            ? Text(
                timeago.format(user.lastMessageTime!),
                style: const TextStyle(color: Color(0xFF71717a), fontSize: 10),
              )
            : null,
        onTap: () {
          setState(() {
            _selectedUserId = user.id;
            _selectedChatId = null;
            _chatType = 'direct';
          });
          ref.read(chatProvider.notifier).fetchMessages(user.id);
        },
      ),
    );
  }

  Widget _getTryoutStatusBadge(String status) {
    Color color;
    String text;

    switch (status) {
      case 'active':
        color = const Color(0xFF22c55e);
        text = 'Active';
        break;
      case 'offer_sent':
        color = const Color(0xFF3b82f6);
        text = 'Offer';
        break;
      case 'ended_by_team':
      case 'ended_by_player':
        color = const Color(0xFFef4444);
        text = 'Ended';
        break;
      case 'offer_accepted':
        color = const Color(0xFF22c55e);
        text = 'Joined';
        break;
      default:
        color = const Color(0xFF71717a);
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ==========================================================================
  // Chat Window
  // ==========================================================================
  Widget _buildChatWindow(ChatState chatState, profile) {
    if (_chatType == 'direct' && _selectedUserId != null) {
      return _buildDirectChatWindow(chatState, profile);
    } else if (_chatType == 'tryout' && _selectedChatId != null) {
      return _buildTryoutChatWindow(chatState, profile);
    }
    return _buildEmptyState();
  }

  Widget _buildDirectChatWindow(ChatState chatState, profile) {
    final selectedUser = chatState.connections.firstWhere(
      (u) => u.id == _selectedUserId,
      orElse: () => ChatUser(id: '', username: 'Unknown'),
    );
    final messages = chatState.messagesByUser[_selectedUserId] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFF09090b),
      body: SafeArea(
        child: Column(
          children: [
            _buildChatHeader(
              selectedUser.username,
              selectedUser.profilePicture,
            ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  final isMine = message.senderId == profile.id;
                  return _buildMessageBubble(message, isMine);
                },
              ),
            ),
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildTryoutChatWindow(ChatState chatState, profile) {
    final tryoutChat = chatState.tryoutChats.firstWhere(
      (c) => c.id == _selectedChatId,
      orElse: () => null as TryoutChat,
    );

    if (tryoutChat == null) return _buildEmptyState();

    final isCaptain = profile.team?.captain?.id == profile.id;
    final isApplicant = tryoutChat.applicant.id == profile.id;

    return Scaffold(
      backgroundColor: const Color(0xFF09090b),
      body: SafeArea(
        child: Column(
          children: [
            _buildTryoutChatHeader(tryoutChat, isCaptain),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: tryoutChat.messages.length,
                itemBuilder: (context, index) {
                  final message = tryoutChat.messages[index];
                  final isMine =
                      message.sender == profile.id ||
                      (message.sender != 'system' &&
                          message.sender == profile.id);
                  return _buildTryoutMessageBubble(message, isMine);
                },
              ),
            ),
            if (![
              'ended_by_team',
              'ended_by_player',
              'offer_accepted',
            ].contains(tryoutChat.tryoutStatus))
              _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildChatHeader(String name, String? avatar) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF18181b),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              setState(() {
                _selectedUserId = null;
                _selectedChatId = null;
              });
            },
          ),
          ProfileAvatar(imageUrl: avatar, fallbackText: name, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {
              // TODO: More options
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTryoutChatHeader(TryoutChat chat, bool isCaptain) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF18181b),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _selectedUserId = null;
                    _selectedChatId = null;
                  });
                },
              ),
              CircleAvatar(
                backgroundImage:
                    chat.team.logo != null && chat.team.logo!.isNotEmpty
                    ? NetworkImage(chat.team.logo!)
                    : null,
                backgroundColor: const Color(0xFF06b6d4),
                radius: 20,
                child: chat.team.logo == null || chat.team.logo!.isEmpty
                    ? Text(
                        chat.team.teamName[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${chat.team.teamName} Tryout',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'with ${chat.applicant.username}',
                      style: const TextStyle(
                        color: Color(0xFF71717a),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _getTryoutStatusBadge(chat.tryoutStatus),
            ],
          ),
          if (isCaptain && chat.tryoutStatus == 'active') ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _showSendOfferDialog(chat.id),
                  icon: const Icon(Icons.handshake, size: 16),
                  label: const Text('Send Offer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22c55e),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _showEndTryoutDialog(chat.id),
                  icon: const Icon(Icons.stop_circle, size: 18),
                  label: const Text('End Tryout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFef4444),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMine) {
    // Handle recruitment approach messages
    if (message.messageType == 'system' &&
        message.metadata?['type'] == 'recruitment_approach') {
      return _buildRecruitmentMessage(message, isMine);
    }

    // Handle team invitation messages
    if (message.messageType == 'invitation') {
      return _buildInvitationMessage(message, isMine);
    }

    // Regular text messages
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMine ? const Color(0xFF06b6d4) : const Color(0xFF27272a),
          borderRadius: BorderRadius.circular(16),
        ),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.message,
              style: TextStyle(
                color: isMine ? Colors.white : const Color(0xFFd4d4d8),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              timeago.format(message.timestamp),
              style: TextStyle(
                color: isMine
                    ? Colors.white.withOpacity(0.7)
                    : const Color(0xFF71717a),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecruitmentMessage(ChatMessage message, bool isMine) {
    final metadata = message.metadata;
    final teamName = metadata?['teamName'] as String? ?? 'Team';
    final teamLogo = metadata?['teamLogo'] as String?;
    final approachMessage = metadata?['message'] as String? ?? message.message;
    final approachStatus = metadata?['approachStatus'] as String?;
    final approachId = metadata?['approachId'] as String?;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF581c87), Color(0xFF4c1d95)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: const Color(0xFF7c3aed).withOpacity(0.3)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Team header
              Row(
                children: [
                  // Team logo/avatar
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF9333ea).withOpacity(0.5),
                        width: 2,
                      ),
                      color: const Color(0xFF7c3aed),
                    ),
                    child: teamLogo != null && teamLogo.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              teamLogo,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Center(
                                    child: Text(
                                      teamName[0].toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                      ),
                                    ),
                                  ),
                            ),
                          )
                        : Center(
                            child: Text(
                              teamName[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  // Team name and title
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          teamName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Recruitment Approach',
                          style: TextStyle(
                            color: Color(0xFFc4b5fd),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Message
              Text(
                approachMessage,
                style: const TextStyle(color: Color(0xFFddd6fe), fontSize: 14),
              ),
              const SizedBox(height: 16),
              // Action buttons or status
              if (approachStatus == null || approachStatus == 'pending')
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: approachId != null
                            ? () => _handleAcceptApproach(approachId)
                            : null,
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Accept & Start Chat'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF22c55e),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: approachId != null
                            ? () => _handleRejectApproach(approachId)
                            : null,
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Decline'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFef4444),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              else if (approachStatus == 'accepted')
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22c55e).withOpacity(0.2),
                    border: Border.all(
                      color: const Color(0xFF22c55e).withOpacity(0.3),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Color(0xFF86efac),
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Approach Accepted - Tryout Chat Created',
                        style: TextStyle(
                          color: Color(0xFF86efac),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                )
              else if (approachStatus == 'rejected' ||
                  approachStatus == 'declined')
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFef4444).withOpacity(0.2),
                    border: Border.all(
                      color: const Color(0xFFef4444).withOpacity(0.3),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cancel, color: Color(0xFFfca5a5), size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Approach Declined',
                        style: TextStyle(
                          color: Color(0xFFfca5a5),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                )
              else
                // Handle any other status (expired, canceled, etc.)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF71717a).withOpacity(0.2),
                    border: Border.all(
                      color: const Color(0xFF71717a).withOpacity(0.3),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Color(0xFFa1a1aa),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Status: ${approachStatus ?? "unknown"}',
                        style: const TextStyle(
                          color: Color(0xFFa1a1aa),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvitationMessage(ChatMessage message, bool isMine) {
    final invitationData = message.invitationData;
    if (invitationData == null) {
      return _buildMessageBubble(message, isMine);
    }

    final team = invitationData.team;
    final status = message.invitationStatus ?? invitationData.status;
    final invitationId = message.invitationId;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1e3a8a), Color(0xFF1e40af)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: const Color(0xFF3b82f6).withOpacity(0.3)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Team header
              Row(
                children: [
                  // Team logo/avatar
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF60a5fa).withOpacity(0.5),
                        width: 2,
                      ),
                      color: const Color(0xFF3b82f6),
                    ),
                    child: team.logo != null && team.logo!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              team.logo!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Center(
                                    child: Text(
                                      team.teamName[0].toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                      ),
                                    ),
                                  ),
                            ),
                          )
                        : Center(
                            child: Text(
                              team.teamName[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  // Team name and title
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          team.teamName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Team Invitation',
                          style: TextStyle(
                            color: Color(0xFFbfdbfe),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Message
              Text(
                message.message,
                style: const TextStyle(color: Color(0xFFdbeafe), fontSize: 14),
              ),
              const SizedBox(height: 16),
              // Action buttons or status
              if (status != 'accepted' && status != 'declined')
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: invitationId != null
                            ? () => _handleAcceptInvitation(invitationId)
                            : null,
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Accept Invitation'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF22c55e),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: invitationId != null
                            ? () => _handleDeclineInvitation(invitationId)
                            : null,
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Decline'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFef4444),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              else if (status == 'accepted')
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22c55e).withOpacity(0.2),
                    border: Border.all(
                      color: const Color(0xFF22c55e).withOpacity(0.3),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Color(0xFF86efac),
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Invitation Accepted',
                        style: TextStyle(
                          color: Color(0xFF86efac),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                )
              else if (status == 'declined')
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFef4444).withOpacity(0.2),
                    border: Border.all(
                      color: const Color(0xFFef4444).withOpacity(0.3),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cancel, color: Color(0xFFfca5a5), size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Invitation Declined',
                        style: TextStyle(
                          color: Color(0xFFfca5a5),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTryoutMessageBubble(TryoutMessage message, bool isMine) {
    if (message.messageType == 'system') {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF27272a),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            message.message,
            style: const TextStyle(color: Color(0xFF71717a), fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMine ? const Color(0xFF06b6d4) : const Color(0xFF27272a),
          borderRadius: BorderRadius.circular(16),
        ),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.message,
              style: TextStyle(
                color: isMine ? Colors.white : const Color(0xFFd4d4d8),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              timeago.format(message.timestamp),
              style: TextStyle(
                color: isMine
                    ? Colors.white.withOpacity(0.7)
                    : const Color(0xFF71717a),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF18181b),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Type your message...',
                hintStyle: const TextStyle(color: Color(0xFF71717a)),
                filled: true,
                fillColor: const Color(0xFF27272a),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF06b6d4), Color(0xFF7c3aed)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Select a chat to start messaging',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // Actions
  // ==========================================================================
  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    if (_chatType == 'direct' && _selectedUserId != null) {
      ref.read(chatProvider.notifier).sendMessage(_selectedUserId!, message);
    } else if (_chatType == 'tryout' && _selectedChatId != null) {
      ref
          .read(chatProvider.notifier)
          .sendTryoutMessage(_selectedChatId!, message);
    }

    _messageController.clear();
    _scrollToBottom();
  }

  Future<void> _handleAcceptApproach(String approachId) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF18181b),
        title: const Text(
          'Accept Recruitment Approach',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This will create a tryout chat with the team. Are you ready to proceed?',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF22c55e),
            ),
            child: const Text('Accept'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final tryoutChat = await ref
          .read(chatProvider.notifier)
          .acceptApproach(approachId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Approach accepted! Tryout chat created.'),
            backgroundColor: Color(0xFF22c55e),
          ),
        );
        // Navigate to the tryout chat
        setState(() {
          _selectedChatId = tryoutChat.id;
          _selectedUserId = null;
          _chatType = 'tryout';
        });
        ref.read(chatProvider.notifier).joinTryoutChat(tryoutChat.id);
      }
    } catch (e) {
      if (mounted) {
        // Parse error message to show user-friendly text
        String errorMessage = 'Failed to accept approach';
        if (e.toString().contains('already')) {
          errorMessage = 'This approach has already been processed';
        } else if (e.toString().contains('expired')) {
          errorMessage = 'This approach has expired';
        } else {
          errorMessage =
              'Failed to accept approach: ${e.toString().replaceAll('Exception:', '').trim()}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: const Color(0xFFef4444),
            duration: const Duration(seconds: 4),
          ),
        );
        // Refresh messages to show updated status
        if (_selectedUserId != null) {
          ref.read(chatProvider.notifier).fetchMessages(_selectedUserId!);
        }
      }
    }
  }

  Future<void> _handleRejectApproach(String approachId) async {
    final controller = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF18181b),
        title: const Text(
          'Decline Recruitment Approach',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to decline this recruitment approach?',
              style: TextStyle(color: Color(0xFFd4d4d8)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Reason (optional)',
                hintStyle: TextStyle(color: Color(0xFF71717a)),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFef4444),
            ),
            child: const Text('Decline'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await ref
            .read(chatProvider.notifier)
            .rejectApproach(
              approachId,
              controller.text.trim().isEmpty
                  ? 'No reason provided'
                  : controller.text.trim(),
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Approach declined'),
              backgroundColor: Color(0xFF71717a),
            ),
          );
          // Refresh messages to update UI
          if (_selectedUserId != null) {
            ref.read(chatProvider.notifier).fetchMessages(_selectedUserId!);
          }
        }
      } catch (e) {
        if (mounted) {
          // Parse error message to show user-friendly text
          String errorMessage = 'Failed to decline approach';
          if (e.toString().contains('already')) {
            errorMessage = 'This approach has already been processed';
          } else if (e.toString().contains('expired')) {
            errorMessage = 'This approach has expired';
          } else {
            errorMessage =
                'Failed to decline approach: ${e.toString().replaceAll('Exception:', '').trim()}';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: const Color(0xFFef4444),
              duration: const Duration(seconds: 4),
            ),
          );
          // Refresh messages to show updated status
          if (_selectedUserId != null) {
            ref.read(chatProvider.notifier).fetchMessages(_selectedUserId!);
          }
        }
      }
    }
    controller.dispose();
  }

  Future<void> _handleAcceptInvitation(String invitationId) async {
    try {
      await ref.read(chatProvider.notifier).acceptInvitation(invitationId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invitation accepted! You joined the team.'),
            backgroundColor: Color(0xFF22c55e),
          ),
        );
        // Refresh messages
        if (_selectedUserId != null) {
          ref.read(chatProvider.notifier).fetchMessages(_selectedUserId!);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept invitation: $e'),
            backgroundColor: const Color(0xFFef4444),
          ),
        );
      }
    }
  }

  Future<void> _handleDeclineInvitation(String invitationId) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF18181b),
        title: const Text(
          'Decline Team Invitation',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to decline this team invitation?',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFef4444),
            ),
            child: const Text('Decline'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await ref.read(chatProvider.notifier).declineInvitation(invitationId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invitation declined'),
              backgroundColor: Color(0xFF71717a),
            ),
          );
          // Refresh messages
          if (_selectedUserId != null) {
            ref.read(chatProvider.notifier).fetchMessages(_selectedUserId!);
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to decline invitation: $e'),
              backgroundColor: const Color(0xFFef4444),
            ),
          );
        }
      }
    }
  }

  void _showSendOfferDialog(String chatId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF18181b),
        title: const Text(
          'Send Team Offer',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Custom message (optional)',
            hintStyle: TextStyle(color: Color(0xFF71717a)),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref
                  .read(chatProvider.notifier)
                  .sendTeamOffer(chatId, controller.text);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Send Offer'),
          ),
        ],
      ),
    );
  }

  void _showEndTryoutDialog(String chatId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF18181b),
        title: const Text('End Tryout', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Reason (required)',
            hintStyle: TextStyle(color: Color(0xFF71717a)),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await ref
                    .read(chatProvider.notifier)
                    .endTryout(chatId, controller.text);
                if (context.mounted) Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFef4444),
            ),
            child: const Text('End Tryout'),
          ),
        ],
      ),
    );
  }
}
