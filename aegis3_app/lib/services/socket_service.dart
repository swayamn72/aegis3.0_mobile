import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../constants/api_constants.dart';
import '../providers/core_providers.dart';
import '../models/chat_models.dart';

// ============================================================================
// Socket Service Provider
// ============================================================================
final socketServiceProvider = Provider<SocketService>((ref) {
  return SocketService(ref.read(loggerProvider));
});

// ============================================================================
// Socket Service
// ============================================================================
class SocketService {
  final Logger _logger;
  IO.Socket? _socket;
  bool _isConnected = false;

  // Callbacks
  Function(ChatMessage)? onMessageReceived;
  Function(TryoutMessage, String chatId)? onTryoutMessageReceived;
  Function(String chatId, Map<String, dynamic> data)? onTryoutEnded;
  Function(String chatId, Map<String, dynamic> data)? onTeamOfferSent;
  Function(String chatId, Map<String, dynamic> data)? onTeamOfferAccepted;
  Function(String chatId, Map<String, dynamic> data)? onTeamOfferRejected;
  Function(Set<String> onlineUserIds)? onOnlineUsersUpdate;

  SocketService(this._logger);

  bool get isConnected => _isConnected;

  // ==========================================================================
  // Initialize and Connect
  // ==========================================================================
  Future<void> connect(String userId) async {
    if (_isConnected && _socket != null) {
      _logger.d('Socket already connected');
      return;
    }

    try {
      _logger.d('Connecting to socket server...');

      // Replace http://10.0.2.2:5000/api with http://10.0.2.2:5000
      final baseUrl = ApiConstants.baseUrl.replaceAll('/api', '');

      _socket = IO.io(
        baseUrl,
        IO.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .enableAutoConnect()
            .enableForceNew()
            .setExtraHeaders({'userId': userId})
            .build(),
      );

      _socket!.onConnect((_) {
        _isConnected = true;
        _logger.d('✅ Socket connected, ID: ${_socket!.id}');
        _socket!.emit('joinRoom', userId);
        _logger.d('✅ Emitted joinRoom with userId: $userId');
      });

      _socket!.onDisconnect((_) {
        _isConnected = false;
        _logger.w('❌ Socket disconnected');
      });

      _socket!.onConnectError((error) {
        _logger.e('Socket connection error: $error');
      });

      _socket!.onError((error) {
        _logger.e('Socket error: $error');
      });

      // Listen for messages
      _socket!.on('receiveMessage', (data) {
        _logger.d('📩 Message received: ${data['message']}');
        try {
          final message = ChatMessage.fromJson(data);
          onMessageReceived?.call(message);
        } catch (e) {
          _logger.e('Error parsing received message: $e');
        }
      });

      // Listen for tryout messages
      _socket!.on('newTryoutMessage', (data) {
        _logger.d('📩 ✅ Tryout message received via socket!');
        _logger.d('📩 Data: $data');
        try {
          final message = TryoutMessage.fromJson(data['message']);
          final chatId = data['chatId'] as String;
          _logger.d(
            '📩 Parsed message for chat $chatId from ${message.sender}',
          );
          onTryoutMessageReceived?.call(message, chatId);
          _logger.d('📩 Message callback executed');
        } catch (e) {
          _logger.e('❌ Error parsing tryout message: $e');
          _logger.e('❌ Raw data: $data');
        }
      });

      // Listen for tryout events
      _socket!.on('tryoutEnded', (data) {
        _logger.d('🛑 Tryout ended');
        final chatId = data['chatId'] as String;
        onTryoutEnded?.call(chatId, data);
      });

      _socket!.on('teamOfferSent', (data) {
        _logger.d('📬 Team offer sent');
        final chatId = data['chatId'] as String;
        onTeamOfferSent?.call(chatId, data);
      });

      _socket!.on('teamOfferAccepted', (data) {
        _logger.d('✅ Team offer accepted');
        final chatId = data['chatId'] as String;
        onTeamOfferAccepted?.call(chatId, data);
      });

      _socket!.on('teamOfferRejected', (data) {
        _logger.d('❌ Team offer rejected');
        final chatId = data['chatId'] as String;
        onTeamOfferRejected?.call(chatId, data);
      });

      // Listen for online users updates
      _socket!.on('onlineUsersUpdate', (data) {
        try {
          final userIds = Set<String>.from(data['onlineUsers'] as List);
          onOnlineUsersUpdate?.call(userIds);
        } catch (e) {
          _logger.e('Error parsing online users: $e');
        }
      });

      _logger.d('Socket listeners registered');
    } catch (e) {
      _logger.e('Error connecting to socket: $e');
      rethrow;
    }
  }

  // ==========================================================================
  // Send Message (Direct Chat)
  // ==========================================================================
  void sendMessage(String receiverId, String message) {
    if (!_isConnected || _socket == null) {
      _logger.e('Cannot send message: Socket not connected');
      return;
    }

    _logger.d('Sending message to $receiverId');
    _socket!.emit('sendMessage', {
      'receiverId': receiverId,
      'message': message,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // ==========================================================================
  // Tryout Chat Methods
  // ==========================================================================
  void joinTryoutChat(String chatId) {
    if (!_isConnected || _socket == null) {
      _logger.e('❌ Cannot join tryout chat: Socket not connected');
      return;
    }

    _logger.d('🔗 Joining tryout chat: $chatId');
    _socket!.emit('joinTryoutChat', chatId);
    _logger.d('✅ Emitted joinTryoutChat for chat: $chatId');
  }

  void leaveTryoutChat(String chatId) {
    if (!_isConnected || _socket == null) {
      _logger.e('❌ Cannot leave tryout chat: Socket not connected');
      return;
    }

    _logger.d('🔗 Leaving tryout chat: $chatId');
    _socket!.emit('leaveTryoutChat', chatId);
    _logger.d('✅ Emitted leaveTryoutChat for chat: $chatId');
  }

  void sendTryoutMessage(String chatId, String message, String senderId) {
    if (!_isConnected || _socket == null) {
      _logger.e('❌ Cannot send tryout message: Socket not connected');
      return;
    }

    _logger.d('📤 Sending tryout message to chat: $chatId from $senderId');
    _logger.d(
      '📤 Message payload: chatId=$chatId, senderId=$senderId, message=$message',
    );

    _socket!.emit('sendTryoutMessage', {
      'chatId': chatId,
      'message': message,
      'senderId': senderId,
    });

    _logger.d('✅ Message emitted successfully');
  }

  // ==========================================================================
  // Disconnect
  // ==========================================================================
  void disconnect() {
    if (_socket != null) {
      _logger.d('Disconnecting socket...');
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _isConnected = false;
    }
  }

  // ==========================================================================
  // Clear Callbacks
  // ==========================================================================
  void clearCallbacks() {
    onMessageReceived = null;
    onTryoutMessageReceived = null;
    onTryoutEnded = null;
    onTeamOfferSent = null;
    onTeamOfferAccepted = null;
    onTeamOfferRejected = null;
    onOnlineUsersUpdate = null;
  }
}
