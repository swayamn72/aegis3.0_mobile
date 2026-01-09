import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/core_providers.dart';

final tokenManagerProvider = Provider<TokenManager>((ref) {
  return TokenManager(
    ref.read(secureStorageProvider),
    ref.read(loggerProvider),
  );
});

/// Manages authentication tokens with in-memory caching to reduce
/// expensive secure storage reads on every API request
class TokenManager {
  final FlutterSecureStorage _storage;
  final Logger _logger;
  String? _cachedToken;
  DateTime? _lastRead;
  static const Duration _cacheExpiry = Duration(minutes: 5);

  TokenManager(this._storage, this._logger);

  /// Get token from cache or storage
  /// Caches token for 5 minutes to avoid repeated secure storage reads
  Future<String?> getToken() async {
    // Return cached token if still valid
    if (_cachedToken != null &&
        _lastRead != null &&
        DateTime.now().difference(_lastRead!) < _cacheExpiry) {
      return _cachedToken;
    }

    try {
      _cachedToken = await _storage.read(key: 'auth_token');
      _lastRead = DateTime.now();

      if (_cachedToken != null) {
        _logger.d('Token loaded from secure storage and cached');
      }

      return _cachedToken;
    } catch (e) {
      _logger.e('Error reading token from secure storage: $e');
      return null;
    }
  }

  /// Save token to storage and update cache
  Future<void> setToken(String token) async {
    try {
      await _storage.write(key: 'auth_token', value: token);
      _cachedToken = token;
      _lastRead = DateTime.now();
      _logger.d('Token saved to secure storage and cached');
    } catch (e) {
      _logger.e('Error saving token to secure storage: $e');
      rethrow;
    }
  }

  /// Clear token from storage and cache
  Future<void> clearToken() async {
    try {
      await _storage.delete(key: 'auth_token');
      _cachedToken = null;
      _lastRead = null;
      _logger.d('Token cleared from secure storage and cache');
    } catch (e) {
      _logger.e('Error clearing token from secure storage: $e');
      rethrow;
    }
  }

  /// Check if a valid cached token exists
  bool hasCachedToken() {
    return _cachedToken != null &&
        _lastRead != null &&
        DateTime.now().difference(_lastRead!) < _cacheExpiry;
  }

  /// Force refresh token from storage (bypasses cache)
  Future<String?> refreshToken() async {
    try {
      _cachedToken = await _storage.read(key: 'auth_token');
      _lastRead = DateTime.now();
      _logger.d('Token refreshed from secure storage');
      return _cachedToken;
    } catch (e) {
      _logger.e('Error refreshing token from secure storage: $e');
      return null;
    }
  }

  /// Clear only the cache (keeps storage intact)
  void clearCache() {
    _cachedToken = null;
    _lastRead = null;
    _logger.d('Token cache cleared');
  }
}
