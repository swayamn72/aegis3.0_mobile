import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/team_model.dart';
import '../services/team_service.dart';
import 'core_providers.dart';

// ============================================================================
// Team State Class
// ============================================================================
class TeamState {
  final Team? team;
  final TeamDataResponse? teamData;
  final List<TeamInvitation> invitations;
  final bool isLoading;
  final String? error;

  const TeamState({
    this.team,
    this.teamData,
    this.invitations = const [],
    this.isLoading = false,
    this.error,
  });

  TeamState copyWith({
    Team? team,
    TeamDataResponse? teamData,
    List<TeamInvitation>? invitations,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool clearTeam = false,
  }) {
    return TeamState(
      team: clearTeam ? null : (team ?? this.team),
      teamData: teamData ?? this.teamData,
      invitations: invitations ?? this.invitations,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ============================================================================
// Team Provider
// ============================================================================
final teamProvider = StateNotifierProvider<TeamNotifier, TeamState>(
  (ref) => TeamNotifier(ref),
);

class TeamNotifier extends StateNotifier<TeamState> {
  final Ref _ref;

  TeamNotifier(this._ref) : super(const TeamState());

  TeamService get _teamService => _ref.read(teamServiceProvider);

  // ==========================================================================
  // Fetch Team by ID
  // ==========================================================================
  Future<void> fetchTeam(String teamId) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final teamData = await _teamService.getTeamById(teamId);
      state = state.copyWith(
        teamData: teamData,
        team: teamData.team,
        isLoading: false,
      );
    } catch (e) {
      _ref.read(loggerProvider).e('Error fetching team: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  // ==========================================================================
  // Fetch Team Invitations
  // ==========================================================================
  Future<void> fetchInvitations() async {
    try {
      final invitations = await _teamService.getReceivedInvitations();
      state = state.copyWith(invitations: invitations);
    } catch (e) {
      _ref.read(loggerProvider).e('Error fetching invitations: $e');
      state = state.copyWith(error: e.toString().replaceAll('Exception: ', ''));
    }
  }

  // ==========================================================================
  // Create Team
  // ==========================================================================
  Future<Team?> createTeam({
    required String teamName,
    String? teamTag,
    String primaryGame = 'BGMI',
    String region = 'India',
    String? bio,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final team = await _teamService.createTeam(
        teamName: teamName,
        teamTag: teamTag,
        primaryGame: primaryGame,
        region: region,
        bio: bio,
      );
      state = state.copyWith(team: team, isLoading: false);
      return team;
    } catch (e) {
      _ref.read(loggerProvider).e('Error creating team: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return null;
    }
  }

  // ==========================================================================
  // Accept Invitation
  // ==========================================================================
  Future<bool> acceptInvitation(String invitationId) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final team = await _teamService.acceptInvitation(invitationId);
      state = state.copyWith(team: team, isLoading: false);
      await fetchInvitations(); // Refresh invitations
      return true;
    } catch (e) {
      _ref.read(loggerProvider).e('Error accepting invitation: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  // ==========================================================================
  // Decline Invitation
  // ==========================================================================
  Future<bool> declineInvitation(String invitationId) async {
    try {
      await _teamService.declineInvitation(invitationId);
      await fetchInvitations(); // Refresh invitations
      return true;
    } catch (e) {
      _ref.read(loggerProvider).e('Error declining invitation: $e');
      state = state.copyWith(error: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  // ==========================================================================
  // Remove Player (Kick or Leave)
  // ==========================================================================
  Future<bool> removePlayer({
    required String teamId,
    required String playerId,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _teamService.removePlayerFromTeam(
        teamId: teamId,
        playerId: playerId,
      );
      state = state.copyWith(isLoading: false);
      await fetchTeam(teamId); // Refresh team data
      return true;
    } catch (e) {
      _ref.read(loggerProvider).e('Error removing player: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  // ==========================================================================
  // Send Invitation
  // ==========================================================================
  Future<bool> sendInvitation({
    required String teamId,
    required String playerId,
    String? message,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _teamService.sendInvitation(
        teamId: teamId,
        playerId: playerId,
        message: message,
      );
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      _ref.read(loggerProvider).e('Error sending invitation: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  // ==========================================================================
  // Upload Team Logo
  // ==========================================================================
  Future<bool> uploadLogo({
    required String teamId,
    required dynamic logoFile,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final team = await _teamService.uploadTeamLogo(
        teamId: teamId,
        logoFile: logoFile,
      );
      state = state.copyWith(team: team, isLoading: false);
      return true;
    } catch (e) {
      _ref.read(loggerProvider).e('Error uploading logo: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  // ==========================================================================
  // Clear Error
  // ==========================================================================
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  // ==========================================================================
  // Reset State
  // ==========================================================================
  void reset() {
    state = const TeamState();
  }
}

// ============================================================================
// Search Provider (for player/team search)
// ============================================================================
final searchProvider = StateNotifierProvider<SearchNotifier, SearchState>(
  (ref) => SearchNotifier(ref),
);

class SearchState {
  final SearchResults? results;
  final bool isLoading;
  final String? error;

  const SearchState({this.results, this.isLoading = false, this.error});

  SearchState copyWith({
    SearchResults? results,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return SearchState(
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class SearchNotifier extends StateNotifier<SearchState> {
  final Ref _ref;
  Timer? _debounceTimer;

  SearchNotifier(this._ref) : super(const SearchState());

  TeamService get _teamService => _ref.read(teamServiceProvider);

  Future<void> search({
    required String query,
    String? game,
    String? region,
    String searchType = 'all',
  }) async {
    // Cancel any existing debounce timer
    _debounceTimer?.cancel();

    if (query.trim().isEmpty) {
      state = const SearchState();
      return;
    }

    // Minimum character requirement
    if (query.trim().length < 2) {
      return;
    }

    // Set loading state immediately for better UX
    state = state.copyWith(isLoading: true, clearError: true);

    // Debounce: wait 400ms before making API call
    _debounceTimer = Timer(const Duration(milliseconds: 400), () async {
      try {
        final results = await _teamService.search(
          query: query,
          game: game,
          region: region,
          searchType: searchType,
        );
        state = state.copyWith(results: results, isLoading: false);
      } catch (e) {
        _ref.read(loggerProvider).e('Error searching: $e');
        state = state.copyWith(
          isLoading: false,
          error: e.toString().replaceAll('Exception: ', ''),
        );
      }
    });
  }

  void clear() {
    _debounceTimer?.cancel();
    state = const SearchState();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
