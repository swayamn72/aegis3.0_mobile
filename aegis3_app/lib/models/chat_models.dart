import 'team_model.dart';

// ============================================================================
// Chat User Model (for chat list)
// ============================================================================
class ChatUser {
  final String id;
  final String username;
  final String? profilePicture;
  final String? inGameName;
  final num? aegisRating;
  final bool isOnline;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;

  ChatUser({
    required this.id,
    required this.username,
    this.profilePicture,
    this.inGameName,
    this.aegisRating,
    this.isOnline = false,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
  });

  factory ChatUser.fromJson(Map<String, dynamic> json) {
    return ChatUser(
      id: json['_id'] as String,
      username: json['username'] as String,
      profilePicture: json['profilePicture'] as String?,
      inGameName: json['inGameName'] as String?,
      aegisRating: json['aegisRating'] != null
          ? num.tryParse(json['aegisRating'].toString())
          : null,
      isOnline: json['isOnline'] as bool? ?? false,
      lastMessage: json['lastMessage'] as String?,
      lastMessageTime: json['lastMessageTime'] != null
          ? DateTime.parse(json['lastMessageTime'])
          : null,
      unreadCount: json['unreadCount'] as int? ?? 0,
    );
  }
}

// ============================================================================
// Chat Message Model
// ============================================================================
class ChatMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final String message;
  final String messageType;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;
  final String? tournamentId;
  final String? matchId;
  final String? invitationId;
  final String? invitationStatus;
  final TeamInvitationData? invitationData;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.message,
    this.messageType = 'text',
    required this.timestamp,
    this.metadata,
    this.tournamentId,
    this.matchId,
    this.invitationId,
    this.invitationStatus,
    this.invitationData,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['_id'] as String,
      senderId: json['senderId'] as String,
      receiverId: json['receiverId'] as String,
      message: json['message'] as String,
      messageType: json['messageType'] as String? ?? 'text',
      timestamp: DateTime.parse(json['timestamp'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
      tournamentId: json['tournamentId'] as String?,
      matchId: json['matchId'] as String?,
      invitationId: json['invitationId'] is String
          ? json['invitationId']
          : json['invitationId']?['_id'],
      invitationStatus: json['invitationStatus'] as String?,
      invitationData: json['invitationId'] is Map
          ? TeamInvitationData.fromJson(json['invitationId'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'messageType': messageType,
      'timestamp': timestamp.toIso8601String(),
      if (metadata != null) 'metadata': metadata,
      if (tournamentId != null) 'tournamentId': tournamentId,
      if (matchId != null) 'matchId': matchId,
      if (invitationId != null) 'invitationId': invitationId,
      if (invitationStatus != null) 'invitationStatus': invitationStatus,
    };
  }

  bool get isMine => false; // Will be set by the UI based on current user
}

// ============================================================================
// Team Invitation Data (for embedded invitations)
// ============================================================================
class TeamInvitationData {
  final String id;
  final TeamBasicInfo team;
  final String message;
  final String status;

  TeamInvitationData({
    required this.id,
    required this.team,
    required this.message,
    required this.status,
  });

  factory TeamInvitationData.fromJson(Map<String, dynamic> json) {
    return TeamInvitationData(
      id: json['_id'] as String,
      team: TeamBasicInfo.fromJson(json['team']),
      message: json['message'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
    );
  }
}

class TeamBasicInfo {
  final String id;
  final String teamName;
  final String? teamTag;
  final String? logo;
  final String? primaryGame;
  final String? region;

  TeamBasicInfo({
    required this.id,
    required this.teamName,
    this.teamTag,
    this.logo,
    this.primaryGame,
    this.region,
  });

  factory TeamBasicInfo.fromJson(Map<String, dynamic> json) {
    return TeamBasicInfo(
      id: json['_id'] as String,
      teamName: json['teamName'] as String,
      teamTag: json['teamTag'] as String?,
      logo: json['logo'] as String?,
      primaryGame: json['primaryGame'] as String?,
      region: json['region'] as String?,
    );
  }
}

// ============================================================================
// Tryout Chat Model
// ============================================================================
class TryoutChat {
  final String id;
  final TeamBasicInfo team;
  final PlayerBasicInfo applicant;
  final List<String> participants;
  final String status;
  final String chatType;
  final List<TryoutMessage> messages;
  final String tryoutStatus;
  final TeamOffer? teamOffer;
  final DateTime? endedAt;
  final String? endReason;
  final DateTime createdAt;

  TryoutChat({
    required this.id,
    required this.team,
    required this.applicant,
    required this.participants,
    required this.status,
    required this.chatType,
    required this.messages,
    required this.tryoutStatus,
    this.teamOffer,
    this.endedAt,
    this.endReason,
    required this.createdAt,
  });

  factory TryoutChat.fromJson(Map<String, dynamic> json) {
    return TryoutChat(
      id: json['_id'] as String,
      team: TeamBasicInfo.fromJson(json['team']),
      applicant: PlayerBasicInfo.fromJson(json['applicant']),
      participants: (json['participants'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      status: json['status'] as String? ?? 'active',
      chatType: json['chatType'] as String? ?? 'application',
      messages: (json['messages'] as List?)
              ?.map((e) => TryoutMessage.fromJson(e))
              .toList() ??
          [],
      tryoutStatus: json['tryoutStatus'] as String? ?? 'active',
      teamOffer: json['teamOffer'] != null
          ? TeamOffer.fromJson(json['teamOffer'])
          : null,
      endedAt:
          json['endedAt'] != null ? DateTime.parse(json['endedAt']) : null,
      endReason: json['endReason'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class TryoutMessage {
  final String sender;
  final String message;
  final String messageType;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  TryoutMessage({
    required this.sender,
    required this.message,
    required this.messageType,
    required this.timestamp,
    this.metadata,
  });

  factory TryoutMessage.fromJson(Map<String, dynamic> json) {
    return TryoutMessage(
      sender: json['sender'] as String,
      message: json['message'] as String,
      messageType: json['messageType'] as String? ?? 'text',
      timestamp: DateTime.parse(json['timestamp'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sender': sender,
      'message': message,
      'messageType': messageType,
      'timestamp': timestamp.toIso8601String(),
      if (metadata != null) 'metadata': metadata,
    };
  }
}

class TeamOffer {
  final String status;
  final DateTime? sentAt;
  final DateTime? respondedAt;
  final String? message;

  TeamOffer({
    required this.status,
    this.sentAt,
    this.respondedAt,
    this.message,
  });

  factory TeamOffer.fromJson(Map<String, dynamic> json) {
    return TeamOffer(
      status: json['status'] as String? ?? 'none',
      sentAt: json['sentAt'] != null ? DateTime.parse(json['sentAt']) : null,
      respondedAt: json['respondedAt'] != null
          ? DateTime.parse(json['respondedAt'])
          : null,
      message: json['message'] as String?,
    );
  }
}

class PlayerBasicInfo {
  final String id;
  final String username;
  final String? profilePicture;
  final String? inGameName;

  PlayerBasicInfo({
    required this.id,
    required this.username,
    this.profilePicture,
    this.inGameName,
  });

  factory PlayerBasicInfo.fromJson(Map<String, dynamic> json) {
    return PlayerBasicInfo(
      id: json['_id'] as String,
      username: json['username'] as String,
      profilePicture: json['profilePicture'] as String?,
      inGameName: json['inGameName'] as String?,
    );
  }
}

// ============================================================================
// Team Application Model (for application panel)
// ============================================================================
class TeamApplication {
  final String id;
  final PlayerBasicInfo player;
  final String teamId;
  final List<String> appliedRoles;
  final String? message;
  final String status;
  final DateTime createdAt;

  TeamApplication({
    required this.id,
    required this.player,
    required this.teamId,
    required this.appliedRoles,
    this.message,
    required this.status,
    required this.createdAt,
  });

  factory TeamApplication.fromJson(Map<String, dynamic> json) {
    return TeamApplication(
      id: json['_id'] as String,
      player: PlayerBasicInfo.fromJson(json['player']),
      teamId: json['team'] is String ? json['team'] : json['team']?['_id'],
      appliedRoles: (json['appliedRoles'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      message: json['message'] as String?,
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

// ============================================================================
// Recruitment Approach Model
// ============================================================================
class RecruitmentApproach {
  final String id;
  final TeamBasicInfo team;
  final String playerId;
  final String message;
  final String status;
  final DateTime createdAt;

  RecruitmentApproach({
    required this.id,
    required this.team,
    required this.playerId,
    required this.message,
    required this.status,
    required this.createdAt,
  });

  factory RecruitmentApproach.fromJson(Map<String, dynamic> json) {
    return RecruitmentApproach(
      id: json['_id'] as String,
      team: TeamBasicInfo.fromJson(json['team']),
      playerId:
          json['player'] is String ? json['player'] : json['player']?['_id'],
      message: json['message'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}