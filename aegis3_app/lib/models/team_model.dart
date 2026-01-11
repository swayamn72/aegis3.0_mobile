// ============================================================================
// Team Model
// ============================================================================
class Team {
  final String id;
  final String teamName;
  final String? teamTag;
  final String? logo;
  final String? captainId;
  final Player? captain;
  final List<Player>? players;
  final String primaryGame;
  final String region;
  final String? country;
  final String? bio;
  final DateTime? establishedDate;
  final num totalEarnings;
  final num aegisRating;
  final TeamStatistics? statistics;
  final List<RecentResult>? recentResults;
  final List<QualifiedEvent>? qualifiedEvents;
  final Organization? organization;
  final Socials? socials;
  final String profileVisibility;
  final String status;
  final bool lookingForPlayers;
  final List<String>? openRoles;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Team({
    required this.id,
    required this.teamName,
    this.teamTag,
    this.logo,
    this.captainId,
    this.captain,
    this.players,
    required this.primaryGame,
    required this.region,
    this.country,
    this.bio,
    this.establishedDate,
    this.totalEarnings = 0,
    this.aegisRating = 0,
    this.statistics,
    this.recentResults,
    this.qualifiedEvents,
    this.organization,
    this.socials,
    this.profileVisibility = 'public',
    this.status = 'active',
    this.lookingForPlayers = false,
    this.openRoles,
    this.createdAt,
    this.updatedAt,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['_id'] as String,
      teamName: json['teamName'] as String,
      teamTag: json['teamTag'] as String?,
      logo: json['logo'] as String?,
      captainId: json['captain'] is String ? json['captain'] : null,
      captain: json['captain'] is Map<String, dynamic>
          ? Player.fromJson(json['captain'])
          : null,
      players: json['players'] != null
          ? (json['players'] as List)
                .map((p) => Player.fromJson(p as Map<String, dynamic>))
                .toList()
          : null,
      primaryGame: json['primaryGame'] as String? ?? 'BGMI',
      region: json['region'] as String? ?? 'India',
      country: json['country'] as String?,
      bio: json['bio'] as String?,
      establishedDate: json['establishedDate'] != null
          ? DateTime.parse(json['establishedDate'])
          : null,
      totalEarnings: json['totalEarnings'] != null
          ? num.tryParse(json['totalEarnings'].toString()) ?? 0
          : 0,
      aegisRating: json['aegisRating'] != null
          ? num.tryParse(json['aegisRating'].toString()) ?? 0
          : 0,
      statistics: json['statistics'] != null
          ? TeamStatistics.fromJson(json['statistics'])
          : null,
      recentResults: json['recentResults'] != null
          ? (json['recentResults'] as List)
                .map((r) => RecentResult.fromJson(r))
                .toList()
          : null,
      qualifiedEvents: json['qualifiedEvents'] != null
          ? (json['qualifiedEvents'] as List)
                .map((e) => QualifiedEvent.fromJson(e))
                .toList()
          : null,
      organization: json['organization'] != null && json['organization'] is Map
          ? Organization.fromJson(json['organization'])
          : null,
      socials: json['socials'] != null
          ? Socials.fromJson(json['socials'])
          : null,
      profileVisibility: json['profileVisibility'] as String? ?? 'public',
      status: json['status'] as String? ?? 'active',
      lookingForPlayers: json['lookingForPlayers'] as bool? ?? false,
      openRoles: json['openRoles'] != null
          ? List<String>.from(json['openRoles'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'teamName': teamName,
      'teamTag': teamTag,
      'logo': logo,
      'captain': captainId ?? captain?.id,
      'primaryGame': primaryGame,
      'region': region,
      'country': country,
      'bio': bio,
      'establishedDate': establishedDate?.toIso8601String(),
      'totalEarnings': totalEarnings,
      'aegisRating': aegisRating,
      'profileVisibility': profileVisibility,
      'status': status,
      'lookingForPlayers': lookingForPlayers,
      'openRoles': openRoles,
      if (socials != null) 'socials': socials!.toJson(),
    };
  }
}

// ============================================================================
// Player Model (for team context)
// ============================================================================
class Player {
  final String id;
  final String username;
  final String? profilePicture;
  final String? primaryGame;
  final String? inGameName;
  final String? realName;
  final int? age;
  final String? country;
  final num? aegisRating;
  final Map<String, dynamic>? statistics;
  final List<String>? inGameRole;
  final String? discordTag;
  final bool? verified;
  final int? tournamentsPlayed;
  final int? matchesPlayed;

  Player({
    required this.id,
    required this.username,
    this.profilePicture,
    this.primaryGame,
    this.inGameName,
    this.realName,
    this.age,
    this.country,
    this.aegisRating,
    this.statistics,
    this.inGameRole,
    this.discordTag,
    this.verified,
    this.tournamentsPlayed,
    this.matchesPlayed,
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['_id'] as String,
      username: json['username'] as String,
      profilePicture: json['profilePicture'] as String?,
      primaryGame: json['primaryGame'] as String?,
      inGameName: json['inGameName'] as String?,
      realName: json['realName'] as String?,
      age: json['age'] as int?,
      country: json['country'] as String?,
      aegisRating: json['aegisRating'] != null
          ? num.tryParse(json['aegisRating'].toString())
          : null,
      statistics: json['statistics'] as Map<String, dynamic>?,
      inGameRole: json['inGameRole'] != null
          ? List<String>.from(json['inGameRole'])
          : null,
      discordTag: json['discordTag'] as String?,
      verified: json['verified'] as bool?,
      tournamentsPlayed: json['tournamentsPlayed'] as int?,
      matchesPlayed: json['matchesPlayed'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'username': username,
      'profilePicture': profilePicture,
      'primaryGame': primaryGame,
      'inGameName': inGameName,
      'realName': realName,
      'age': age,
      'country': country,
      'aegisRating': aegisRating,
      'inGameRole': inGameRole,
      'discordTag': discordTag,
      'verified': verified,
    };
  }
}

// ============================================================================
// Team Statistics
// ============================================================================
class TeamStatistics {
  final int tournamentsPlayed;
  final int matchesPlayed;
  final int totalKills;
  final int chickenDinners;
  final num averagePlacement;
  final num winRate;

  TeamStatistics({
    this.tournamentsPlayed = 0,
    this.matchesPlayed = 0,
    this.totalKills = 0,
    this.chickenDinners = 0,
    this.averagePlacement = 0,
    this.winRate = 0,
  });

  factory TeamStatistics.fromJson(Map<String, dynamic> json) {
    return TeamStatistics(
      tournamentsPlayed: json['tournamentsPlayed'] as int? ?? 0,
      matchesPlayed: json['matchesPlayed'] as int? ?? 0,
      totalKills: json['totalKills'] as int? ?? 0,
      chickenDinners: json['chickenDinners'] as int? ?? 0,
      averagePlacement: json['averagePlacement'] != null
          ? num.tryParse(json['averagePlacement'].toString()) ?? 0
          : 0,
      winRate: json['winRate'] != null
          ? num.tryParse(json['winRate'].toString()) ?? 0
          : 0,
    );
  }
}

// ============================================================================
// Recent Result
// ============================================================================
class RecentResult {
  final String? tournamentId;
  final int? placement;
  final num? points;
  final num? earnings;
  final DateTime? date;

  RecentResult({
    this.tournamentId,
    this.placement,
    this.points,
    this.earnings,
    this.date,
  });

  factory RecentResult.fromJson(Map<String, dynamic> json) {
    return RecentResult(
      tournamentId: json['tournament'] is String
          ? json['tournament']
          : json['tournament']?['_id'],
      placement: json['placement'] as int?,
      points: json['points'] != null
          ? num.tryParse(json['points'].toString())
          : null,
      earnings: json['earnings'] != null
          ? num.tryParse(json['earnings'].toString())
          : null,
      date: json['date'] != null ? DateTime.parse(json['date']) : null,
    );
  }
}

// ============================================================================
// Qualified Event
// ============================================================================
class QualifiedEvent {
  final String? tournamentId;
  final String? eventName;
  final DateTime? qualificationDate;

  QualifiedEvent({this.tournamentId, this.eventName, this.qualificationDate});

  factory QualifiedEvent.fromJson(Map<String, dynamic> json) {
    return QualifiedEvent(
      tournamentId: json['tournament'] is String
          ? json['tournament']
          : json['tournament']?['_id'],
      eventName: json['eventName'] as String?,
      qualificationDate: json['qualificationDate'] != null
          ? DateTime.parse(json['qualificationDate'])
          : null,
    );
  }
}

// ============================================================================
// Organization
// ============================================================================
class Organization {
  final String id;
  final String orgName;
  final String? logo;
  final String? description;
  final String? website;
  final DateTime? establishedDate;

  Organization({
    required this.id,
    required this.orgName,
    this.logo,
    this.description,
    this.website,
    this.establishedDate,
  });

  factory Organization.fromJson(Map<String, dynamic> json) {
    return Organization(
      id: json['_id'] as String,
      orgName: json['orgName'] as String,
      logo: json['logo'] as String?,
      description: json['description'] as String?,
      website: json['website'] as String?,
      establishedDate: json['establishedDate'] != null
          ? DateTime.parse(json['establishedDate'])
          : null,
    );
  }
}

// ============================================================================
// Socials
// ============================================================================
class Socials {
  final String? discord;
  final String? twitter;
  final String? twitch;
  final String? youtube;
  final String? website;

  Socials({
    this.discord,
    this.twitter,
    this.twitch,
    this.youtube,
    this.website,
  });

  factory Socials.fromJson(Map<String, dynamic> json) {
    return Socials(
      discord: json['discord'] as String?,
      twitter: json['twitter'] as String?,
      twitch: json['twitch'] as String?,
      youtube: json['youtube'] as String?,
      website: json['website'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'discord': discord,
      'twitter': twitter,
      'twitch': twitch,
      'youtube': youtube,
      'website': website,
    };
  }
}

// ============================================================================
// Team Invitation
// ============================================================================
class TeamInvitation {
  final String id;
  final String teamId;
  final Team? team;
  final String fromPlayerId;
  final Player? fromPlayer;
  final String toPlayerId;
  final String? message;
  final String status;
  final DateTime? expiresAt;
  final DateTime createdAt;

  TeamInvitation({
    required this.id,
    required this.teamId,
    this.team,
    required this.fromPlayerId,
    this.fromPlayer,
    required this.toPlayerId,
    this.message,
    required this.status,
    this.expiresAt,
    required this.createdAt,
  });

  factory TeamInvitation.fromJson(Map<String, dynamic> json) {
    return TeamInvitation(
      id: json['_id'] as String,
      teamId: json['team'] is String ? json['team'] : json['team']?['_id'],
      team: json['team'] is Map<String, dynamic>
          ? Team.fromJson(json['team'])
          : null,
      fromPlayerId: json['fromPlayer'] is String
          ? json['fromPlayer']
          : json['fromPlayer']?['_id'],
      fromPlayer: json['fromPlayer'] is Map<String, dynamic>
          ? Player.fromJson(json['fromPlayer'])
          : null,
      toPlayerId: json['toPlayer'] is String
          ? json['toPlayer']
          : json['toPlayer']?['_id'],
      message: json['message'] as String?,
      status: json['status'] as String? ?? 'pending',
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'])
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

// ============================================================================
// Team Data Response
// ============================================================================
class TeamDataResponse {
  final Team team;
  final List<dynamic>? recentMatches;
  final List<dynamic>? ongoingTournaments;
  final List<dynamic>? recentTournaments;

  TeamDataResponse({
    required this.team,
    this.recentMatches,
    this.ongoingTournaments,
    this.recentTournaments,
  });

  factory TeamDataResponse.fromJson(Map<String, dynamic> json) {
    return TeamDataResponse(
      team: Team.fromJson(json['team']),
      recentMatches: json['recentMatches'] as List?,
      ongoingTournaments: json['ongoingTournaments'] as List?,
      recentTournaments: json['recentTournaments'] as List?,
    );
  }
}

// ============================================================================
// Search Results
// ============================================================================
class SearchResults {
  final List<Team> teams;
  final List<Player> players;

  SearchResults({required this.teams, required this.players});

  factory SearchResults.fromJson(Map<String, dynamic> json) {
    return SearchResults(
      teams: json['teams'] != null
          ? (json['teams'] as List)
                .map((t) => Team.fromJson(t as Map<String, dynamic>))
                .toList()
          : [],
      players: json['players'] != null
          ? (json['players'] as List)
                .map((p) => Player.fromJson(p as Map<String, dynamic>))
                .toList()
          : [],
    );
  }
}
