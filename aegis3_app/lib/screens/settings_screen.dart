import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_profile_provider.dart';
import '../services/player_services.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Theme colors
  static const _bgColor = Color(0xFF09090b);
  static const _cardColor = Color(0xFF18181b);
  static const _inputColor = Color(0xFF27272a);
  static const _borderColor = Color(0xFF52525b);
  static const _accentColor = Color(0xFF06b6d4);
  static const _textColor = Color(0xFFd4d4d8);
  static const _iconColor = Color(0xFF71717a);

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isSaving = false;
  File? _selectedImage;
  String? _currentProfilePicture;

  // Controllers for form fields
  final _realNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _locationController = TextEditingController();
  final _bioController = TextEditingController();
  final _inGameNameController = TextEditingController();
  final _discordTagController = TextEditingController();
  final _twitchController = TextEditingController();
  final _youtubeController = TextEditingController();

  // Read-only field controllers (created once)
  late final _countryController = TextEditingController(text: 'India');
  late final _primaryGameController = TextEditingController(text: 'BGMI');

  // Dropdown values
  String _selectedCountry = 'India';
  String _selectedPrimaryGame = 'BGMI';
  String _selectedTeamStatus = '';
  String _selectedAvailability = '';
  String _selectedProfileVisibility = 'public';

  // Note: languages and inGameRoles can be added later if needed

  bool _didPrefill = false;
  @override
  void initState() {
    super.initState();
    final profile = ref.read(userProfileProvider).profile;
    if (profile != null) {
      _prefillFromProfile(profile);
      _didPrefill = true;
    } else {
      _loadProfile();
    }
  }

  void _prefillFromProfile(profile) {
    setState(() {
      _realNameController.text = profile.realName ?? '';
      _ageController.text = profile.age?.toString() ?? '';
      _locationController.text = profile.location ?? '';
      _bioController.text = profile.bio ?? '';
      _selectedCountry = profile.country ?? 'India';
      _countryController.text = _selectedCountry;
      _currentProfilePicture = profile.profilePicture;
      _inGameNameController.text = profile.inGameName ?? '';
      _selectedPrimaryGame = profile.primaryGame ?? 'BGMI';
      _primaryGameController.text = _selectedPrimaryGame;
      _selectedTeamStatus = profile.teamStatus ?? '';
      _selectedAvailability = profile.availability ?? '';
      _discordTagController.text = profile.discordTag ?? '';
      _twitchController.text = profile.twitch ?? '';
      _youtubeController.text = profile.youtube ?? '';
      _selectedProfileVisibility = profile.profileVisibility ?? 'public';
    });
  }

  @override
  void dispose() {
    _realNameController.dispose();
    _ageController.dispose();
    _locationController.dispose();
    _bioController.dispose();
    _inGameNameController.dispose();
    _discordTagController.dispose();
    _twitchController.dispose();
    _youtubeController.dispose();
    _countryController.dispose();
    _primaryGameController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    // Profile will be loaded from cache via ref.listen in build
    setState(() => _isLoading = false);
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final playerService = ref.read(playerServiceProvider);

      // 1. Upload profile picture if selected
      if (_selectedImage != null) {
        try {
          final uploadedUrl = await playerService.uploadProfilePicture(
            _selectedImage!,
          );
          if (uploadedUrl != null) {
            _currentProfilePicture = uploadedUrl;
          }
        } catch (e) {
          _showError('Failed to upload profile picture: $e');
          setState(() => _isSaving = false);
          return;
        }
      }

      // 2. Prepare profile data: only include non-empty / non-null fields
      final profileData = <String, dynamic>{};

      void addIfPresent(String key, dynamic value) {
        if (value == null) return;
        if (value is String && value.trim().isEmpty) return;
        profileData[key] = value;
      }

      addIfPresent('realName', _realNameController.text.trim());
      final age = int.tryParse(_ageController.text.trim());
      if (age != null) profileData['age'] = age;
      addIfPresent('location', _locationController.text.trim());
      addIfPresent('bio', _bioController.text.trim());
      addIfPresent('country', _selectedCountry);
      addIfPresent('inGameName', _inGameNameController.text.trim());
      addIfPresent('primaryGame', _selectedPrimaryGame);
      addIfPresent('teamStatus', _selectedTeamStatus);
      addIfPresent('availability', _selectedAvailability);
      addIfPresent('discordTag', _discordTagController.text.trim());
      addIfPresent('twitch', _twitchController.text.trim());
      addIfPresent('youtube', _youtubeController.text.trim());
      addIfPresent('profileVisibility', _selectedProfileVisibility);
      if (_currentProfilePicture != null)
        profileData['profilePicture'] = _currentProfilePicture;

      // 3. Make API call to update profile
      final updatedProfile = await playerService.updateProfile(profileData);

      if (updatedProfile != null) {
        // Update local state with the updated profile
        _prefillFromProfile(updatedProfile);
        _didPrefill = true;
        // Also update the provider cache in background
        ref.read(userProfileProvider.notifier).fetchAndCacheProfile();
        _showSuccess('Profile updated successfully!');
        setState(() => _selectedImage = null);
      } else {
        _showError('Failed to update profile');
      }
    } catch (e) {
      _showError('An error occurred: $e');
    }

    setState(() => _isSaving = false);
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(userProfileProvider, (prev, next) {
      if (!_didPrefill && next.profile != null) {
        _prefillFromProfile(next.profile!);
        _didPrefill = true;
      }
    });
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _cardColor,
        elevation: 0,
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton(
              onPressed: _isSaving ? null : _saveProfile,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Save',
                      style: TextStyle(
                        color: Color(0xFF06b6d4),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF06b6d4)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection(
                      title: 'Profile Picture',
                      children: [_buildProfilePictureSection()],
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      title: 'Personal Information',
                      children: [
                        _buildTextField(
                          controller: _realNameController,
                          label: 'Real Name',
                          hint: 'Enter your full name',
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _ageController,
                          label: 'Age',
                          hint: 'Enter your age',
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _locationController,
                          label: 'Location',
                          hint: 'City, State',
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _countryController,
                          label: 'Country',
                          hint: 'India',
                          readOnly: true,
                          validator: (value) => null,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _bioController,
                          label: 'Bio',
                          hint: 'Tell us about yourself',
                          maxLines: 4,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      title: 'Gaming Profile',
                      children: [
                        _buildTextField(
                          controller: _inGameNameController,
                          label: 'In-Game Name (IGN)',
                          hint: 'Your primary IGN',
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _primaryGameController,
                          label: 'Primary Game',
                          hint: 'BGMI',
                          readOnly: true,
                          validator: (value) => null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      title: 'Socials',
                      children: [
                        _buildTextField(
                          controller: _discordTagController,
                          label: 'Discord',
                          hint: 'username#1234',
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _twitchController,
                          label: 'Twitch',
                          hint: 'twitch.tv/username',
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _youtubeController,
                          label: 'YouTube',
                          hint: 'youtube.com/@username',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      title: 'Preferences',
                      children: [
                        _buildDropdown(
                          label: 'Profile Visibility',
                          value: _selectedProfileVisibility,
                          items: const ['public', 'private'],
                          hint: 'Select Visibility',
                          onChanged: (value) {
                            setState(() => _selectedProfileVisibility = value!);
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildDropdown(
                          label: 'Team Status',
                          value: _selectedTeamStatus,
                          items: const [
                            'looking for a team',
                            'in a team',
                            'open for offers',
                          ],
                          hint: 'Select Team Status',
                          onChanged: (value) {
                            setState(() => _selectedTeamStatus = value ?? '');
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildDropdown(
                          label: 'Availability',
                          value: _selectedAvailability,
                          items: const [
                            'weekends only',
                            'evenings',
                            'flexible',
                            'full time',
                          ],
                          hint: 'Select Availability',
                          onChanged: (value) {
                            setState(() => _selectedAvailability = value ?? '');
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfilePictureSection() {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: _inputColor,
            backgroundImage: _selectedImage != null
                ? FileImage(_selectedImage!)
                : (_currentProfilePicture != null &&
                              _currentProfilePicture!.isNotEmpty &&
                              !_currentProfilePicture!.startsWith('data:')
                          ? CachedNetworkImageProvider(_currentProfilePicture!)
                          : null)
                      as ImageProvider?,
            child:
                (_selectedImage == null &&
                    (_currentProfilePicture == null ||
                        _currentProfilePicture!.isEmpty))
                ? const Icon(Icons.person, size: 60, color: _iconColor)
                : _currentProfilePicture != null &&
                      _currentProfilePicture!.startsWith('data:')
                ? _buildDataUriImage(_currentProfilePicture!)
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: _accentColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataUriImage(String dataUri) {
    try {
      final base64String = dataUri.split(',')[1];
      final bytes = base64Decode(base64String);
      return ClipOval(
        child: Image.memory(bytes, width: 120, height: 120, fit: BoxFit.cover),
      );
    } catch (e) {
      return const Icon(Icons.person, size: 60, color: _iconColor);
    }
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _inputColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    Widget? prefix,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFd4d4d8),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          readOnly: readOnly,
          style: TextStyle(color: readOnly ? Colors.grey : Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade600),
            filled: true,
            fillColor: _inputColor,
            prefixIcon: prefix != null
                ? Padding(
                    padding: const EdgeInsets.only(left: 12, right: 8),
                    child: prefix,
                  )
                : null,
            prefixIconConstraints: const BoxConstraints(minWidth: 0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _accentColor),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required String hint,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _textColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: _inputColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _borderColor),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value.isNotEmpty ? value : null,
              hint: Text(hint, style: TextStyle(color: Colors.grey.shade600)),
              isExpanded: true,
              dropdownColor: _inputColor,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
