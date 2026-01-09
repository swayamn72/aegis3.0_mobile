import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../providers/core_providers.dart';

final imageCacheServiceProvider = Provider<ImageCacheService>((ref) {
  return ImageCacheService(ref.read(loggerProvider));
});

class ImageCacheService {
  final Logger logger;
  Directory? _cacheDir;

  ImageCacheService(this.logger);

  Future<void> initialize() async {
    _cacheDir = await getApplicationCacheDirectory();
    final imageDir = Directory('${_cacheDir!.path}/profile_images');
    if (!await imageDir.exists()) {
      await imageDir.create(recursive: true);
    }
    logger.d('ImageCacheService initialized at: ${imageDir.path}');
  }

  /// Save base64 image to disk and return file path
  Future<String?> cacheBase64Image(String base64Data, String userId) async {
    try {
      if (_cacheDir == null) await initialize();

      // Remove data:image/... prefix if present
      final cleanBase64 = base64Data.contains(',')
          ? base64Data.split(',').last
          : base64Data;

      final bytes = base64Decode(cleanBase64);
      final hash = md5.convert(bytes).toString();
      final filePath = '${_cacheDir!.path}/profile_images/${userId}_$hash.jpg';

      final file = File(filePath);
      await file.writeAsBytes(bytes);

      logger.d('Cached image to: $filePath');
      return filePath;
    } catch (e) {
      logger.e('Failed to cache image: $e');
      return null;
    }
  }

  /// Get cached image path for a user
  String? getCachedImagePath(String userId) {
    if (_cacheDir == null) return null;

    final dir = Directory('${_cacheDir!.path}/profile_images');
    if (!dir.existsSync()) return null;

    final files = dir.listSync().where((f) => f.path.contains(userId)).toList();

    return files.isNotEmpty ? files.first.path : null;
  }

  /// Clear old cached images (default: older than 7 days)
  Future<void> clearOldCache({int daysOld = 7}) async {
    try {
      if (_cacheDir == null) await initialize();

      final dir = Directory('${_cacheDir!.path}/profile_images');
      if (!await dir.exists()) return;

      final cutoff = DateTime.now().subtract(Duration(days: daysOld));
      int deletedCount = 0;

      await for (var entity in dir.list()) {
        final stat = await entity.stat();
        if (stat.modified.isBefore(cutoff)) {
          await entity.delete();
          deletedCount++;
        }
      }

      logger.d('Cleared $deletedCount old cached images');
    } catch (e) {
      logger.e('Failed to clear old cache: $e');
    }
  }

  /// Clear all cached images
  Future<void> clearAllCache() async {
    try {
      if (_cacheDir == null) await initialize();

      final dir = Directory('${_cacheDir!.path}/profile_images');
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        await dir.create(recursive: true);
        logger.d('Cleared all cached images');
      }
    } catch (e) {
      logger.e('Failed to clear all cache: $e');
    }
  }
}
