import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/user_profile.dart';
import '../services/player_services.dart';
import '../services/image_cache_service.dart';
import '../services/performance_service.dart';
import 'core_providers.dart';
import '../hive_setup.dart';

// ============================================================================
// Profile State Class (Fixed copyWith to handle null values)
// ============================================================================
class ProfileState {
  final UserProfile? profile;
  final bool isLoading;
  final String? error;

  const ProfileState({this.profile, this.isLoading = false, this.error});

  ProfileState copyWith({
    UserProfile? profile,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool clearProfile = false,
  }) {
    return ProfileState(
      profile: clearProfile ? null : (profile ?? this.profile),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ============================================================================
// User Profile Provider with Proper State Management
// ============================================================================
final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, ProfileState>(
      (ref) => UserProfileNotifier(ref),
    );

class UserProfileNotifier extends StateNotifier<ProfileState> {
  final Ref _ref;
  static const String _profileKey = 'profile';
  Box? _box;

  UserProfileNotifier(this._ref) : super(const ProfileState()) {
    _initializeBox();
  }

  Future<void> _initializeBox() async {
    try {
      // Use the cached box from hive_setup
      _box = await openProfileBox();
      await loadProfile();
    } catch (e) {
      final logger = _ref.read(loggerProvider);
      logger.e('Failed to initialize profile storage: $e');
      state = state.copyWith(error: 'Failed to initialize storage');
    }
  }

  /// Load profile from cache
  Future<void> loadProfile() async {
    if (_box == null) return;

    final perf = _ref.read(performanceServiceProvider);

    try {
      perf.startTrace('loadProfile');
      final cached = _box!.get(_profileKey);
      if (cached != null && cached is Map) {
        final logger = _ref.read(loggerProvider);
        logger.d('Loading profile from cache...');

        final jsonMap = _convertToJsonMap(cached);
        final profile = UserProfile.fromJson(jsonMap);

        state = state.copyWith(profile: profile, clearError: true);
        logger.d('Profile loaded: ${profile.username}');
      }
      perf.stopTrace('loadProfile');
    } catch (e) {
      perf.stopTrace('loadProfile');
      final logger = _ref.read(loggerProvider);
      logger.e('Error loading profile from cache: $e');
      state = state.copyWith(error: 'Failed to load profile');

      // Clear corrupted cache
      await _box?.delete(_profileKey);
    }
  }

  /// Fetch profile from API and cache it
  Future<void> fetchAndCacheProfile() async {
    if (_box == null) {
      await _initializeBox();
      if (_box == null) return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    final perf = _ref.read(performanceServiceProvider);
    perf.startTrace('fetchAndCacheProfile');

    try {
      final logger = _ref.read(loggerProvider);
      logger.d('Fetching profile from API...');

      final playerService = _ref.read(playerServiceProvider);
      final imageCacheService = _ref.read(imageCacheServiceProvider);

      perf.startTrace('fetchCurrentUserProfile');
      final profile = await playerService.fetchCurrentUserProfile();
      perf.stopTrace('fetchCurrentUserProfile');

      if (profile != null) {
        logger.d('Profile fetched: ${profile.username}');

        // Cache profile picture to disk if it's base64
        String? processedProfilePicture = profile.profilePicture;

        if (processedProfilePicture != null &&
            processedProfilePicture.startsWith('data:')) {
          logger.d('Converting base64 image to file cache...');
          perf.startTrace('cacheBase64Image');
          final cachedPath = await imageCacheService.cacheBase64Image(
            processedProfilePicture,
            profile.id,
          );
          perf.stopTrace('cacheBase64Image');
          if (cachedPath != null) {
            processedProfilePicture = cachedPath;
            logger.d('Image cached successfully at: $cachedPath');
          }
        }

        // Create updated profile with file path instead of base64
        final updatedProfile = UserProfile(
          id: profile.id,
          username: profile.username,
          profilePicture: processedProfilePicture,
          realName: profile.realName,
          age: profile.age,
          location: profile.location,
          bio: profile.bio,
          languages: profile.languages,
          inGameName: profile.inGameName,
          earnings: profile.earnings,
          inGameRole: profile.inGameRole,
          teamStatus: profile.teamStatus,
          availability: profile.availability,
          discordTag: profile.discordTag,
          twitch: profile.twitch,
          youtube: profile.youtube,
          profileVisibility: profile.profileVisibility,
          cardTheme: profile.cardTheme,
          country: profile.country,
          aegisRating: profile.aegisRating,
          verified: profile.verified,
          createdAt: profile.createdAt,
          previousTeams: profile.previousTeams,
          team: profile.team,
          tournamentsPlayed: profile.tournamentsPlayed,
          matchesPlayed: profile.matchesPlayed,
          primaryGame: profile.primaryGame,
        );

        state = state.copyWith(
          profile: updatedProfile,
          isLoading: false,
          clearError: true,
        );

        // Cache to Hive (now without base64 bloat)
        perf.startTrace('cacheProfileToHive');
        final jsonData = updatedProfile.toJson();
        await _box!.put(_profileKey, jsonData);
        perf.stopTrace('cacheProfileToHive');
        logger.d('Profile cached successfully');
        perf.stopTrace('fetchAndCacheProfile');
      } else {
        perf.stopTrace('fetchAndCacheProfile');
        state = state.copyWith(isLoading: false, error: 'Profile not found');
      }
    } catch (e) {
      perf.stopTrace('fetchAndCacheProfile');
      final logger = _ref.read(loggerProvider);
      logger.e('Error fetching profile: $e');

      state = state.copyWith(
        isLoading: false,
        error: 'Failed to fetch profile: ${e.toString()}',
      );

      // Clear corrupted cache
      await _box?.delete(_profileKey);
    }
  }

  /// Clear profile from state and cache
  Future<void> clearProfile() async {
    state = const ProfileState();
    await _box?.delete(_profileKey);
    final logger = _ref.read(loggerProvider);
    logger.d('Profile cleared');
  }

  /// Recursively converts a Map to Map<String, dynamic>
  Map<String, dynamic> _convertToJsonMap(dynamic data) {
    if (data is Map) {
      return data.map(
        (key, value) => MapEntry(key.toString(), _convertToJsonValue(value)),
      );
    }
    return {};
  }

  dynamic _convertToJsonValue(dynamic value) {
    if (value is Map) {
      return _convertToJsonMap(value);
    } else if (value is List) {
      return value.map((e) => _convertToJsonValue(e)).toList();
    }
    return value;
  }

  @override
  void dispose() {
    // Don't close the box here - it's managed globally
    super.dispose();
  }
}
