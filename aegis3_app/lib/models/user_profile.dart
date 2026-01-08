class UserProfile {
  final String id;
  final String username;
  final String? realName;
  final int? age;
  final String? location;
  final String? bio;
  final List<String>? languages;
  final String? profilePicture;
  final String? inGameName;
  final num? earnings;
  final List<String>? inGameRole;
  final String? teamStatus;
  final String? availability;
  final String? discordTag;
  final String? twitch;
  final String? youtube;
  final String? profileVisibility;
  final String? cardTheme;
  final String? country;
  final num? aegisRating;
  final bool? verified;
  final String? createdAt;
  final List<PreviousTeam>? previousTeams;
  final Team? team;
  final int? tournamentsPlayed;
  final int? matchesPlayed;
  final String? primaryGame;

  UserProfile({
    required this.id,
    required this.username,
    this.realName,
    this.age,
    this.location,
    this.bio,
    this.languages,
    this.profilePicture,
    this.inGameName,
    this.earnings,
    this.inGameRole,
    this.teamStatus,
    this.availability,
    this.discordTag,
    this.twitch,
    this.youtube,
    this.profileVisibility,
    this.cardTheme,
    this.country,
    this.aegisRating,
    this.verified,
    this.createdAt,
    this.previousTeams,
    this.team,
    this.tournamentsPlayed,
    this.matchesPlayed,
    this.primaryGame,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    try {
      // Handle statistics object if present (extract tournamentsPlayed and matchesPlayed)
      final stats = json['statistics'] as Map<String, dynamic>?;
      final tournamentsPlayed =
          stats?['tournamentsPlayed'] ?? json['tournamentsPlayed'];
      final matchesPlayed = stats?['matchesPlayed'] ?? json['matchesPlayed'];

      return UserProfile(
        id: json['_id'] as String,
        username: json['username'] as String,
        realName: json['realName'] as String?,
        age: json['age'] != null
            ? (json['age'] is int
                  ? json['age']
                  : int.tryParse(json['age'].toString()))
            : null,
        location: json['location'] as String?,
        bio: json['bio'] as String?,
        languages: _parseStringList(json['languages']),
        profilePicture: json['profilePicture'] as String?,
        inGameName: json['inGameName'] as String?,
        earnings: json['earnings'] != null
            ? num.tryParse(json['earnings'].toString())
            : null,
        inGameRole: _parseStringList(json['inGameRole']),
        teamStatus: json['teamStatus'] as String?,
        availability: json['availability'] as String?,
        discordTag: json['discordTag'] as String?,
        twitch: json['twitch'] as String?,
        youtube: json['youtube'] as String?,
        profileVisibility: json['profileVisibility'] as String?,
        cardTheme: json['cardTheme'] as String?,
        country: json['country'] as String?,
        aegisRating: json['aegisRating'] != null
            ? num.tryParse(json['aegisRating'].toString())
            : null,
        verified: json['verified'] as bool?,
        createdAt: json['createdAt'] as String?,
        previousTeams: _parsePreviousTeams(json['previousTeams']),
        team: json['team'] != null && json['team'] is Map
            ? Team.fromJson(
                json['team'] is Map<String, dynamic>
                    ? json['team']
                    : Map<String, dynamic>.from(json['team']),
              )
            : null,
        tournamentsPlayed: tournamentsPlayed != null
            ? (tournamentsPlayed is int
                  ? tournamentsPlayed
                  : int.tryParse(tournamentsPlayed.toString()))
            : null,
        matchesPlayed: matchesPlayed != null
            ? (matchesPlayed is int
                  ? matchesPlayed
                  : int.tryParse(matchesPlayed.toString()))
            : null,
        primaryGame: json['primaryGame'] as String?,
      );
    } catch (e, stackTrace) {
      // In production, use a proper logging system
      print('Error parsing UserProfile: $e');
      print('Stack trace: $stackTrace');
      print('JSON data: $json');
      rethrow;
    }
  }

  static List<String>? _parseStringList(dynamic data) {
    if (data == null) return null;
    if (data is List) {
      return data.map((e) => e.toString()).toList();
    }
    return null;
  }

  static List<PreviousTeam>? _parsePreviousTeams(dynamic data) {
    if (data == null) return null;
    if (data is List) {
      return data.map((e) {
        if (e is Map<String, dynamic>) {
          return PreviousTeam.fromJson(e);
        } else if (e is Map) {
          return PreviousTeam.fromJson(Map<String, dynamic>.from(e));
        }
        throw Exception('Invalid previousTeam data: $e');
      }).toList();
    }
    return null;
  }
}

class PreviousTeam {
  final String? team;
  final String? startDate;
  final String? endDate;
  final String? reason;

  PreviousTeam({this.team, this.startDate, this.endDate, this.reason});

  factory PreviousTeam.fromJson(Map<String, dynamic> json) {
    return PreviousTeam(
      team: json['team'] is String
          ? json['team']
          : (json['team']?['_id'] as String?),
      startDate: json['startDate'] as String?,
      endDate: json['endDate'] as String?,
      reason: json['reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'team': team,
      'startDate': startDate,
      'endDate': endDate,
      'reason': reason,
    };
  }
}

class Team {
  final String id;
  final String teamName;
  final String? teamTag;
  final String? logo;
  final String? primaryGame;
  final String? region;
  final String? bio;
  final List<String>? players;
  final Captain? captain;

  Team({
    required this.id,
    required this.teamName,
    this.teamTag,
    this.logo,
    this.primaryGame,
    this.region,
    this.bio,
    this.players,
    this.captain,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    try {
      // Parse players list safely
      List<String>? playersList;
      if (json['players'] != null && json['players'] is List) {
        playersList = (json['players'] as List)
            .map((e) => e.toString())
            .toList();
      }

      return Team(
        id: json['_id'] as String,
        teamName: json['teamName'] as String,
        teamTag: json['teamTag'] as String?,
        logo: json['logo'] as String?,
        primaryGame: json['primaryGame'] as String?,
        region: json['region'] as String?,
        bio: json['bio'] as String?,
        players: playersList,
        captain: json['captain'] != null
            ? Captain.fromJson(
                json['captain'] is Map<String, dynamic>
                    ? json['captain']
                    : Map<String, dynamic>.from(json['captain']),
              )
            : null,
      );
    } catch (e) {
      // In production, use a proper logging system
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'teamName': teamName,
      'teamTag': teamTag,
      'logo': logo,
      'primaryGame': primaryGame,
      'region': region,
      'bio': bio,
      'players': players,
      'captain': captain?.toJson(),
    };
  }
}

class Captain {
  final String id;
  final String username;
  final String? profilePicture;

  Captain({required this.id, required this.username, this.profilePicture});

  factory Captain.fromJson(Map<String, dynamic> json) {
    return Captain(
      id: json['_id'] as String,
      username: json['username'] as String,
      profilePicture: json['profilePicture'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'_id': id, 'username': username, 'profilePicture': profilePicture};
  }
}

extension UserProfileToJson on UserProfile {
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'username': username,
      'realName': realName,
      'age': age,
      'location': location,
      'bio': bio,
      'languages': languages,
      'profilePicture': profilePicture,
      'inGameName': inGameName,
      'earnings': earnings,
      'inGameRole': inGameRole,
      'teamStatus': teamStatus,
      'availability': availability,
      'discordTag': discordTag,
      'twitch': twitch,
      'youtube': youtube,
      'profileVisibility': profileVisibility,
      'cardTheme': cardTheme,
      'country': country,
      'aegisRating': aegisRating,
      'verified': verified,
      'createdAt': createdAt,
      'previousTeams': previousTeams?.map((e) => e.toJson()).toList(),
      'team': team?.toJson(),
      'tournamentsPlayed': tournamentsPlayed,
      'matchesPlayed': matchesPlayed,
      'primaryGame': primaryGame,
    };
  }
}
