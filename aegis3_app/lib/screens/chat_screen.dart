import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_models.dart';
import '../providers/chat_provider.dart';
import '../providers/user_profile_provider.dart';
import '../widgets/profile_avatar.dart';
import 'package:timeago/timeago.dart' as timeago;

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
