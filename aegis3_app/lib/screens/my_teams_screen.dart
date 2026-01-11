import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/team_model.dart';
import '../providers/team_provider.dart';
import '../providers/user_profile_provider.dart';
import '../widgets/team_widgets.dart';
import 'detailed_team_screen.dart';

class MyTeamsScreen extends ConsumerStatefulWidget {
  const MyTeamsScreen({super.key});

  @override
  ConsumerState<MyTeamsScreen> createState() => _MyTeamsScreenState();
}

class _MyTeamsScreenState extends ConsumerState<MyTeamsScreen> {
  bool _showInvitations = false;
  bool _showCreateTeamModal = false;
  bool _isLoadingInvitations = false;

  final _teamNameController = TextEditingController();
  final _teamTagController = TextEditingController();
  final _bioController = TextEditingController();
  String? _createTeamError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkUserTeamAndRedirect();
    });
  }

  void _checkUserTeamAndRedirect() {
    final profileState = ref.read(userProfileProvider);
    final userProfile = profileState.profile;

    if (userProfile?.team != null) {
      // User already has a team, navigate to team page
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) =>
              DetailedTeamScreen(teamId: userProfile!.team!.id),
        ),
      );
    }
  }

  @override
  void dispose() {
    _teamNameController.dispose();
    _teamTagController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _handleRefreshInvitations() async {
    setState(() => _isLoadingInvitations = true);

    try {
      await ref.read(teamProvider.notifier).fetchInvitations();
      setState(() => _showInvitations = true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invitations refreshed!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to fetch invitations'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      setState(() => _isLoadingInvitations = false);
    }
  }

  Future<void> _handleCreateTeam() async {
    final teamName = _teamNameController.text.trim();

    if (teamName.isEmpty) {
      setState(() => _createTeamError = 'Team name is required');
      return;
    }

    setState(() => _createTeamError = null);

    final team = await ref
        .read(teamProvider.notifier)
        .createTeam(
          teamName: teamName,
          teamTag: _teamTagController.text.trim().isEmpty
              ? null
              : _teamTagController.text.trim(),
          bio: _bioController.text.trim().isEmpty
              ? null
              : _bioController.text.trim(),
        );

    if (team != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Team "${team.teamName}" created successfully! 🎉'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );

      // Refresh user profile
      await ref.read(userProfileProvider.notifier).fetchAndCacheProfile();

      setState(() {
        _showCreateTeamModal = false;
        _teamNameController.clear();
        _teamTagController.clear();
        _bioController.clear();
      });

      // Navigate to team detail
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => DetailedTeamScreen(teamId: team.id),
          ),
        );
      }
    }
  }

  Future<void> _handleAcceptInvitation(String invitationId) async {
    final success = await ref
        .read(teamProvider.notifier)
        .acceptInvitation(invitationId);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invitation accepted successfully!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );

      await ref.read(userProfileProvider.notifier).fetchAndCacheProfile();
      await _handleRefreshInvitations();
    }
  }

  Future<void> _handleDeclineInvitation(String invitationId) async {
    final success = await ref
        .read(teamProvider.notifier)
        .declineInvitation(invitationId);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invitation declined'),
          backgroundColor: Color(0xFF71717A),
        ),
      );

      await _handleRefreshInvitations();
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(userProfileProvider);
    final userProfile = profileState.profile;

    // Show loading state
    if (profileState.isLoading && userProfile == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF09090B),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF06B6D4)),
                  strokeWidth: 4,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading your teams...',
                style: TextStyle(color: const Color(0xFF71717A), fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    // Show error state
    if (profileState.error != null && userProfile == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF09090B),
        body: Center(
          child: Text(
            'Error loading profile',
            style: TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    // Main content - watch team state here
    final teamState = ref.watch(teamProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: SafeArea(
        child: Column(
          children: [
            // Header with actions
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'My Teams',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Manage your esports journey',
                              style: TextStyle(
                                color: Color(0xFF71717A),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // Refresh Invitations Button
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoadingInvitations
                              ? null
                              : _handleRefreshInvitations,
                          icon: _isLoadingInvitations
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Icon(Icons.refresh, size: 20),
                          label: const Text('Invitations'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF27272A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: const BorderSide(color: Color(0xFF3F3F46)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Find Team Button
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // TODO: Navigate to opportunities screen
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Find Team feature coming soon!'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.search, size: 20),
                          label: const Text('Find Team'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF27272A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: const BorderSide(color: Color(0xFF3F3F46)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Create Team Button
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() => _showCreateTeamModal = true);
                          },
                          icon: const Icon(Icons.add, size: 20),
                          label: const Text('Create'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0891B2),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  // Invitations Section
                  if (_showInvitations && teamState.invitations.isNotEmpty) ...[
                    _buildInvitationsSection(teamState.invitations),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),

      // Create Team Modal
      bottomSheet: _showCreateTeamModal ? _buildCreateTeamModal() : null,
    );
  }

  Widget _buildInvitationsSection(List<TeamInvitation> invitations) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        border: Border.all(color: const Color(0xFF27272A)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.mail, color: Color(0xFF3B82F6), size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    'Team Invitations',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${invitations.length}',
                      style: const TextStyle(
                        color: Color(0xFF3B82F6),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Color(0xFF71717A)),
                onPressed: () {
                  setState(() => _showInvitations = false);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...invitations.map(
            (invitation) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TeamInvitationCard(
                invitation: invitation,
                onAccept: () => _handleAcceptInvitation(invitation.id),
                onDecline: () => _handleDeclineInvitation(invitation.id),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateTeamModal() {
    final teamState = ref.watch(teamProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF18181B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: Color(0xFF27272A))),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Create New Team',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF71717A)),
                  onPressed: () {
                    setState(() => _showCreateTeamModal = false);
                  },
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFF27272A), height: 1),

          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Error message
                  if (_createTeamError != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withOpacity(0.2),
                        border: Border.all(
                          color: const Color(0xFFEF4444).withOpacity(0.3),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _createTeamError!,
                        style: const TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Team Name
                  const Text(
                    'Team Name *',
                    style: TextStyle(
                      color: Color(0xFFD4D4D8),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _teamNameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Enter team name',
                      hintStyle: const TextStyle(color: Color(0xFF71717A)),
                      filled: true,
                      fillColor: const Color(0xFF27272A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF3F3F46)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF3F3F46)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF06B6D4)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Team Tag
                  const Text(
                    'Team Tag (Optional)',
                    style: TextStyle(
                      color: Color(0xFFD4D4D8),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _teamTagController,
                    maxLength: 5,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'e.g., ESP, PRO',
                      hintStyle: const TextStyle(color: Color(0xFF71717A)),
                      filled: true,
                      fillColor: const Color(0xFF27272A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF3F3F46)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF3F3F46)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF06B6D4)),
                      ),
                      counterStyle: const TextStyle(color: Color(0xFF71717A)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Primary Game (Display only)
                  const Text(
                    'Primary Game',
                    style: TextStyle(
                      color: Color(0xFFD4D4D8),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF27272A).withOpacity(0.5),
                      border: Border.all(color: const Color(0xFF3F3F46)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.videogame_asset,
                          color: Color(0xFF71717A),
                          size: 16,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'BGMI',
                          style: TextStyle(
                            color: Color(0xFF71717A),
                            fontSize: 16,
                          ),
                        ),
                        Spacer(),
                        Text(
                          '(Default)',
                          style: TextStyle(
                            color: Color(0xFF71717A),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Region (Display only)
                  const Text(
                    'Region',
                    style: TextStyle(
                      color: Color(0xFFD4D4D8),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF27272A).withOpacity(0.5),
                      border: Border.all(color: const Color(0xFF3F3F46)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Color(0xFF71717A),
                          size: 16,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'India',
                          style: TextStyle(
                            color: Color(0xFF71717A),
                            fontSize: 16,
                          ),
                        ),
                        Spacer(),
                        Text(
                          '(Default)',
                          style: TextStyle(
                            color: Color(0xFF71717A),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Team Bio
                  const Text(
                    'Team Bio (Optional)',
                    style: TextStyle(
                      color: Color(0xFFD4D4D8),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _bioController,
                    maxLength: 200,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Tell us about your team...',
                      hintStyle: const TextStyle(color: Color(0xFF71717A)),
                      filled: true,
                      fillColor: const Color(0xFF27272A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF3F3F46)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF3F3F46)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF06B6D4)),
                      ),
                      counterStyle: const TextStyle(color: Color(0xFF71717A)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() => _showCreateTeamModal = false);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Color(0xFF3F3F46)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: teamState.isLoading ? null : _handleCreateTeam,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0891B2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      disabledBackgroundColor: const Color(
                        0xFF0891B2,
                      ).withOpacity(0.5),
                    ),
                    child: teamState.isLoading
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              Text('Creating...'),
                            ],
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.emoji_events, size: 16),
                              SizedBox(width: 8),
                              Text('Create Team'),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
