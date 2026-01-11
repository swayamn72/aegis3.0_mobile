import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/team_model.dart';
import '../providers/team_provider.dart';
import '../providers/user_profile_provider.dart';
import '../widgets/team_widgets.dart';

class DetailedTeamScreen extends ConsumerStatefulWidget {
  final String teamId;

  const DetailedTeamScreen({super.key, required this.teamId});

  @override
  ConsumerState<DetailedTeamScreen> createState() => _DetailedTeamScreenState();
}

class _DetailedTeamScreenState extends ConsumerState<DetailedTeamScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showEditLogoModal = false;
  bool _showInviteModal = false;
  File? _selectedFile;
  String _searchQuery = '';
  String _inviteMessage = '';
  Player? _selectedPlayer;
  bool _showKickConfirm = false;
  Map<String, String>? _kickPlayerData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Fetch team data on init
    Future.microtask(() {
      ref.read(teamProvider.notifier).fetchTeam(widget.teamId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final teamState = ref.watch(teamProvider);
    final userProfile = ref.watch(userProfileProvider).profile;
    final searchState = ref.watch(searchProvider);

    final team = teamState.team;
    final isCaptain =
        userProfile != null &&
        team != null &&
        team.captain?.id == userProfile.id;

    // Handle loading state
    if (teamState.isLoading && team == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF09090B),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF06B6D4)),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading team information...',
                style: TextStyle(color: Colors.grey[400]),
              ),
            ],
          ),
        ),
      );
    }

    // Handle error state (private team, not found, etc.)
    if (teamState.error != null && team == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF09090B),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF18181B),
                      border: Border.all(color: const Color(0xFF27272A)),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: const Icon(
                      Icons.lock_outline,
                      size: 40,
                      color: Color(0xFF52525B),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Team Not Available',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    teamState.error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF06B6D4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (team == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF09090B),
        body: Center(
          child: Text(
            'Team not found',
            style: TextStyle(color: Colors.grey[400], fontSize: 18),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              backgroundColor: const Color(0xFF09090B),
              floating: true,
              pinned: true,
              title: const Text(
                'Team Profile',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              actions: isCaptain
                  ? [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white),
                        onPressed: () {
                          setState(() => _showEditLogoModal = true);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.person_add, color: Colors.white),
                        onPressed: () {
                          setState(() => _showInviteModal = true);
                        },
                      ),
                    ]
                  : null,
            ),

            // Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Team Header Card
                    _buildTeamHeader(team, isCaptain),
                    const SizedBox(height: 16),

                    // Stats Grid
                    _buildStatsGrid(team),
                    const SizedBox(height: 16),

                    // Tabs
                    _buildTabs(),
                    const SizedBox(height: 16),

                    // Tab Content
                    _buildTabContent(team, userProfile, isCaptain),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // Modals
      bottomSheet: _buildModals(context, searchState, isCaptain, team),
    );
  }

  Widget _buildTeamHeader(Team team, bool isCaptain) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        border: Border.all(color: const Color(0xFF27272A)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0x3306B6D4), Color(0x33A855F7)],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield, color: Color(0xFF06B6D4), size: 20),
                const SizedBox(width: 8),
                const Text(
                  'TEAM PROFILE',
                  style: TextStyle(
                    color: Color(0xFF06B6D4),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (team.captain?.verified ?? false)
                  Row(
                    children: [
                      const Icon(
                        Icons.verified,
                        color: Color(0xFF06B6D4),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Verified',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Team Info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF27272A)),
                  ),
                  child: team.logo != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            team.logo!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.shield,
                              size: 40,
                              color: Color(0xFF52525B),
                            ),
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF06B6D4), Color(0xFFA855F7)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.shield,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                ),
                const SizedBox(width: 16),

                // Team Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              team.teamName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (team.teamTag != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0x3306B6D4),
                                border: Border.all(
                                  color: const Color(0x4D06B6D4),
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '[${team.teamTag}]',
                                style: const TextStyle(
                                  color: Color(0xFF06B6D4),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Meta Info Grid
                      Row(
                        children: [
                          _buildInfoChip(
                            Icons.games,
                            team.primaryGame,
                            const Color(0xFF3B82F6),
                          ),
                          const SizedBox(width: 8),
                          _buildInfoChip(
                            Icons.people,
                            '${team.players?.length ?? 0}/5',
                            const Color(0xFF10B981),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildInfoChip(
                            Icons.emoji_events,
                            team.captain?.username ?? 'TBD',
                            const Color(0xFFF59E0B),
                          ),
                          const SizedBox(width: 8),
                          _buildInfoChip(
                            Icons.location_on,
                            team.region,
                            const Color(0xFFA855F7),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bio
          if (team.bio != null && team.bio!.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0x1A27272A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                team.bio!,
                style: TextStyle(color: Colors.grey[300], fontSize: 14),
              ),
            ),

          // Social Links
          if (team.socials != null) _buildSocialLinks(team.socials!),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x1A27272A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialLinks(Socials socials) {
    final links = <Widget>[];

    if (socials.discord?.isNotEmpty ?? false) {
      links.add(_buildSocialButton('Discord', Colors.indigo, Icons.discord));
    }
    if (socials.twitter?.isNotEmpty ?? false) {
      links.add(_buildSocialButton('Twitter', Colors.blue, Icons.flutter_dash));
    }
    if (socials.youtube?.isNotEmpty ?? false) {
      links.add(
        _buildSocialButton('YouTube', Colors.red, Icons.youtube_searched_for),
      );
    }
    if (socials.twitch?.isNotEmpty ?? false) {
      links.add(_buildSocialButton('Twitch', Colors.purple, Icons.tv));
    }

    if (links.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Wrap(spacing: 8, runSpacing: 8, children: links),
    );
  }

  Widget _buildSocialButton(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(Team team) {
    return Row(
      children: [
        Expanded(
          child: StatBox(
            icon: Icons.attach_money,
            label: 'Earnings',
            value: '₹${(team.totalEarnings / 100000).toStringAsFixed(1)}L',
            color: const Color(0xFF10B981),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatBox(
            icon: Icons.stars,
            label: 'Rating',
            value: '${team.aegisRating.toInt()}',
            color: const Color(0xFF06B6D4),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatBox(
            icon: Icons.people,
            label: 'Players',
            value: '${team.players?.length ?? 0}',
            color: const Color(0xFF3B82F6),
          ),
        ),
      ],
    );
  }

  Widget _buildTabs() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        border: Border.all(color: const Color(0xFF27272A)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: const Color(0xFF06B6D4),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[500],
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Roster'),
          Tab(text: 'Achievements'),
        ],
      ),
    );
  }

  Widget _buildTabContent(Team team, dynamic userProfile, bool isCaptain) {
    return SizedBox(
      height: 500,
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(team),
          _buildRosterTab(team, userProfile, isCaptain),
          _buildAchievementsTab(team),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(Team team) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        border: Border.all(color: const Color(0xFF27272A)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.trending_up, color: Color(0xFF06B6D4), size: 24),
              SizedBox(width: 12),
              Text(
                'Team Statistics',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                '₹${(team.totalEarnings / 100000).toStringAsFixed(1)}L',
                'Total Earnings',
                const Color(0xFF10B981),
              ),
              _buildStatItem(
                '${team.aegisRating.toInt()}',
                'Aegis Rating',
                const Color(0xFF06B6D4),
              ),
              _buildStatItem(
                '${team.players?.length ?? 0}',
                'Active Players',
                const Color(0xFF3B82F6),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
      ],
    );
  }

  Widget _buildRosterTab(Team team, dynamic userProfile, bool isCaptain) {
    final players = team.players ?? [];

    if (players.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.people_outline,
              size: 64,
              color: Color(0xFF52525B),
            ),
            const SizedBox(height: 16),
            Text(
              'No players yet',
              style: TextStyle(color: Colors.grey[400], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: players.length,
      itemBuilder: (context, index) {
        final player = players[index];
        return PlayerCard(
          player: player,
          isCaptain: team.captain?.id == player.id,
          showActions: isCaptain && player.id != userProfile?.id,
          onKick: () {
            setState(() {
              _kickPlayerData = {
                'teamId': team.id,
                'playerId': player.id,
                'username': player.username,
              };
              _showKickConfirm = true;
            });
          },
        );
      },
    );
  }

  Widget _buildAchievementsTab(Team team) {
    final achievements = team.qualifiedEvents ?? [];

    if (achievements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.emoji_events_outlined,
              size: 64,
              color: Color(0xFF52525B),
            ),
            const SizedBox(height: 16),
            Text(
              'No achievements yet',
              style: TextStyle(color: Colors.grey[400], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        final achievement = achievements[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0x1AF59E0B),
            border: Border.all(color: const Color(0x4DF59E0B)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.emoji_events, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      achievement.eventName ?? 'Achievement',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Qualified Event',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget? _buildModals(
    BuildContext context,
    dynamic searchState,
    bool isCaptain,
    Team team,
  ) {
    if (_showEditLogoModal) {
      return _buildEditLogoModal(context, team);
    }
    if (_showInviteModal) {
      return _buildInviteModal(context, searchState, team);
    }
    if (_showKickConfirm) {
      return _buildKickConfirmModal(context);
    }
    return null;
  }

  Widget _buildEditLogoModal(BuildContext context, Team team) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF18181B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Edit Team Logo',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _showEditLogoModal = false;
                    _selectedFile = null;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_selectedFile != null)
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: FileImage(_selectedFile!),
                  fit: BoxFit.cover,
                ),
              ),
            )
          else
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF27272A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.upload_file,
                size: 40,
                color: Color(0xFF52525B),
              ),
            ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () async {
              final picker = ImagePicker();
              final pickedFile = await picker.pickImage(
                source: ImageSource.gallery,
              );
              if (pickedFile != null) {
                setState(() {
                  _selectedFile = File(pickedFile.path);
                });
              }
            },
            icon: const Icon(Icons.photo_library),
            label: const Text('Choose Image'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF27272A),
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _showEditLogoModal = false;
                      _selectedFile = null;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF27272A)),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _selectedFile == null
                      ? null
                      : () async {
                          final success = await ref
                              .read(teamProvider.notifier)
                              .uploadLogo(
                                teamId: team.id,
                                logoFile: _selectedFile!,
                              );
                          if (success && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Logo uploaded successfully!'),
                                backgroundColor: Color(0xFF10B981),
                              ),
                            );
                            setState(() {
                              _showEditLogoModal = false;
                              _selectedFile = null;
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF06B6D4),
                  ),
                  child: const Text('Upload'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInviteModal(
    BuildContext context,
    dynamic searchState,
    Team team,
  ) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF18181B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Invite Players',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _showInviteModal = false;
                    _searchQuery = '';
                    _selectedPlayer = null;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            onChanged: (value) {
              setState(() => _searchQuery = value);
              if (value.length >= 2) {
                ref
                    .read(searchProvider.notifier)
                    .search(query: value, searchType: 'players');
              }
            },
            decoration: InputDecoration(
              hintText: 'Search players...',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF52525B)),
              filled: true,
              fillColor: const Color(0xFF27272A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: searchState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : searchState.results?.players.isEmpty ?? true
                ? Center(
                    child: Text(
                      _searchQuery.isEmpty
                          ? 'Start typing to search'
                          : 'No players found',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  )
                : ListView.builder(
                    itemCount: searchState.results?.players.length ?? 0,
                    itemBuilder: (context, index) {
                      final player = searchState.results!.players[index];
                      final isSelected = _selectedPlayer?.id == player.id;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedPlayer = player);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0x3306B6D4)
                                : const Color(0x1A27272A),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF06B6D4)
                                  : const Color(0xFF27272A),
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundImage: player.profilePicture != null
                                    ? NetworkImage(player.profilePicture!)
                                    : null,
                                child: player.profilePicture == null
                                    ? Text(player.username[0].toUpperCase())
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      player.username,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (player.realName != null)
                                      Text(
                                        player.realName!,
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 12,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Text(
                                'Rating: ${player.aegisRating?.toInt() ?? 0}',
                                style: const TextStyle(
                                  color: Color(0xFF06B6D4),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (_selectedPlayer != null) ...[
            const SizedBox(height: 16),
            TextField(
              onChanged: (value) => _inviteMessage = value,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Custom message (optional)...',
                filled: true,
                fillColor: const Color(0xFF27272A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final success = await ref
                      .read(teamProvider.notifier)
                      .sendInvitation(
                        teamId: team.id,
                        playerId: _selectedPlayer!.id,
                        message: _inviteMessage.isEmpty ? null : _inviteMessage,
                      );
                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Invitation sent!'),
                        backgroundColor: Color(0xFF10B981),
                      ),
                    );
                    setState(() {
                      _showInviteModal = false;
                      _searchQuery = '';
                      _selectedPlayer = null;
                      _inviteMessage = '';
                    });
                  }
                },
                icon: const Icon(Icons.send),
                label: const Text('Send Invitation'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF06B6D4),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildKickConfirmModal(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF18181B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFEF4444),
                size: 32,
              ),
              SizedBox(width: 12),
              Text(
                'Kick Player',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0x1AEF4444),
              border: Border.all(color: const Color(0x4DEF4444)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Are you sure you want to kick ${_kickPlayerData?['username']} from the team? This action cannot be undone.',
              style: TextStyle(color: Colors.grey[300]),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _showKickConfirm = false;
                      _kickPlayerData = null;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF27272A)),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    final success = await ref
                        .read(teamProvider.notifier)
                        .removePlayer(
                          teamId: _kickPlayerData!['teamId']!,
                          playerId: _kickPlayerData!['playerId']!,
                        );
                    if (success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${_kickPlayerData!['username']} kicked from team',
                          ),
                          backgroundColor: const Color(0xFF10B981),
                        ),
                      );
                      setState(() {
                        _showKickConfirm = false;
                        _kickPlayerData = null;
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                  ),
                  child: const Text('Kick Player'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
