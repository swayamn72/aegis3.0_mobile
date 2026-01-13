import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';
import 'dart:io';
import '../constants/api_constants.dart';

/// Reusable profile avatar widget with caching and fallback
/// Optimized to cache ImageProvider and only reload when imageUrl changes
class ProfileAvatar extends StatefulWidget {
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
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  ImageProvider? _cachedImageProvider;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(ProfileAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only reload if imageUrl actually changed
    if (oldWidget.imageUrl != widget.imageUrl) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    setState(() {
      _isLoading = true;
    });

    if (widget.imageUrl == null || widget.imageUrl!.isEmpty) {
      if (mounted) {
        setState(() {
          _cachedImageProvider = null;
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final url = widget.imageUrl!;

      // Decode base64 once and cache
      if (url.startsWith('data:image/')) {
        final base64Data = url.split(',').last;
        final bytes = base64Decode(base64Data);
        _cachedImageProvider = MemoryImage(bytes);
      }
      // Check file existence once and cache
      else if (url.startsWith('/') ||
          url.startsWith('C:') ||
          url.contains('profile_images')) {
        final file = File(url);
        if (await file.exists()) {
          _cachedImageProvider = FileImage(file);
        } else {
          _cachedImageProvider = null;
        }
      }
      // Network URL - use CachedNetworkImageProvider
      else {
        final fullUrl = _getFullImageUrl(url);
        _cachedImageProvider = CachedNetworkImageProvider(fullUrl);
      }
    } catch (e) {
      debugPrint('Error loading profile image: $e');
      _cachedImageProvider = null;
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white, width: widget.borderWidth),
        gradient: const LinearGradient(
          colors: [Color(0xFF06b6d4), Color(0xFF7c3aed)],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: _isLoading
            ? _buildLoadingPlaceholder()
            : _cachedImageProvider != null
            ? Image(
                image: ResizeImage(
                  _cachedImageProvider!,
                  width: (widget.size * 2).toInt(),
                  height: (widget.size * 2).toInt(),
                ),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildFallback(),
              )
            : _buildFallback(),
      ),
    );
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
          width: widget.size * 0.4,
          height: widget.size * 0.4,
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
        child: widget.fallbackText != null && widget.fallbackText!.isNotEmpty
            ? Text(
                _getInitials(widget.fallbackText!),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: widget.size * 0.4,
                  fontWeight: FontWeight.bold,
                ),
              )
            : Icon(Icons.person, size: widget.size * 0.5, color: Colors.white),
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
