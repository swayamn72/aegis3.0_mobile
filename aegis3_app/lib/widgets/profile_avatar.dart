import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';
import 'dart:io';
import '../constants/api_constants.dart';

/// Reusable profile avatar widget with caching and fallback
class ProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? fallbackText;
  final double size;
  final double borderWidth;

  const ProfileAvatar({
    Key? key,
    this.imageUrl,
    this.fallbackText,
    this.size = 70,
    this.borderWidth = 2,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white, width: borderWidth),
        gradient: const LinearGradient(
          colors: [Color(0xFF06b6d4), Color(0xFF7c3aed)],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    // If we have a valid image URL, try to load it
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      // Check if it's a local file path (cached image)
      if (imageUrl!.startsWith('/') ||
          imageUrl!.startsWith('C:') ||
          imageUrl!.contains('profile_images')) {
        return _buildFileImage(imageUrl!);
      }

      // Check if it's a base64 data URI
      if (imageUrl!.startsWith('data:image/')) {
        return _buildBase64Image(imageUrl!);
      }

      // Otherwise treat as network URL
      final fullImageUrl = _getFullImageUrl(imageUrl!);

      if (kDebugMode) {
        print('ProfileAvatar: Loading network image from: $fullImageUrl');
      }

      return CachedNetworkImage(
        imageUrl: fullImageUrl,
        fit: BoxFit.cover,
        memCacheWidth: (size * 2).toInt(), // 2x for retina displays
        memCacheHeight: (size * 2).toInt(),
        maxHeightDiskCache: (size * 3).toInt(),
        maxWidthDiskCache: (size * 3).toInt(),
        placeholder: (context, url) => _buildLoadingPlaceholder(),
        errorWidget: (context, url, error) {
          if (kDebugMode) {
            print('ProfileAvatar: Failed to load image. Error: $error');
          }
          return _buildFallback();
        },
      );
    }

    // No image URL, show fallback
    return _buildFallback();
  }

  /// Build image from local file path
  Widget _buildFileImage(String filePath) {
    try {
      if (kDebugMode) {
        print('ProfileAvatar: Loading file image from: $filePath');
      }

      final file = File(filePath);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          cacheWidth: (size * 2).toInt(),
          cacheHeight: (size * 2).toInt(),
          errorBuilder: (context, error, stackTrace) {
            if (kDebugMode) {
              print('ProfileAvatar: Failed to load file image: $error');
            }
            return _buildFallback();
          },
        );
      } else {
        if (kDebugMode) {
          print('ProfileAvatar: File does not exist: $filePath');
        }
        return _buildFallback();
      }
    } catch (e) {
      if (kDebugMode) {
        print('ProfileAvatar: Error loading file image: $e');
      }
      return _buildFallback();
    }
  }

  /// Build image from base64 data URI
  Widget _buildBase64Image(String dataUri) {
    try {
      if (kDebugMode) {
        print('ProfileAvatar: Loading base64 image');
      }

      // Extract the base64 data after the comma
      final base64Data = dataUri.split(',').last;
      final bytes = base64Decode(base64Data);

      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          if (kDebugMode) {
            print('ProfileAvatar: Failed to decode base64 image: $error');
          }
          return _buildFallback();
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('ProfileAvatar: Error parsing base64 image: $e');
      }
      return _buildFallback();
    }
  }

  /// Convert relative URLs to absolute URLs
  String _getFullImageUrl(String url) {
    // If already absolute URL, return as is
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }

    // Remove leading slash if present
    final cleanUrl = url.startsWith('/') ? url.substring(1) : url;

    // Get base URL without /api suffix
    final baseUrl = ApiConstants.baseUrl.replaceAll('/api', '');

    // Construct full URL
    return '$baseUrl/$cleanUrl';
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.grey.shade800, Colors.grey.shade700],
        ),
      ),
      child: Center(
        child: SizedBox(
          width: size * 0.4,
          height: size * 0.4,
          child: const CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white54),
          ),
        ),
      ),
    );
  }

  Widget _buildFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF06b6d4), Color(0xFF7c3aed)],
        ),
      ),
      child: Center(
        child: fallbackText != null && fallbackText!.isNotEmpty
            ? Text(
                _getInitials(fallbackText!),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.4,
                  fontWeight: FontWeight.bold,
                ),
              )
            : Icon(Icons.person, size: size * 0.5, color: Colors.white),
      ),
    );
  }

  /// Extract initials from name (max 2 characters)
  String _getInitials(String text) {
    final words = text.trim().split(' ');
    if (words.isEmpty) return '?';
    if (words.length == 1) return words[0][0].toUpperCase();
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }
}
