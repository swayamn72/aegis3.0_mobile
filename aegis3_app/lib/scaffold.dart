import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/login_screen.dart';
import 'providers/user_profile_provider.dart';
import 'providers/core_providers.dart';
import 'services/auth_service.dart';
import 'widgets/profile_avatar.dart';
import 'screens/myprofile_screen';

// Main Navigation Scaffold
class AegisMainScaffold extends ConsumerStatefulWidget {
  const AegisMainScaffold({super.key});

  @override
  ConsumerState<AegisMainScaffold> createState() => _AegisMainScaffoldState();
}

class _AegisMainScaffoldState extends ConsumerState<AegisMainScaffold> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();

    // Initialize screens once to prevent memory leaks
    _screens = [
      const PlaceholderScreen(title: 'Feed'),
      const PlaceholderScreen(title: 'Tournaments'),
      const PlaceholderScreen(title: 'TeamUp'),
      const PlaceholderScreen(title: 'Messages'),
      const AegisMyProfileScreen(),
    ];

    // Load cached profile when scaffold opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final logger = ref.read(loggerProvider);
      logger.d('Loading profile in post frame callback...');
      ref.read(userProfileProvider.notifier).loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF09090b),
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: _screens[_currentIndex],
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF18181b),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: Colors.white),
        onPressed: () {
          _scaffoldKey.currentState?.openDrawer();
        },
      ),
      title: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [Color(0xFF06b6d4), Color(0xFF7c3aed)],
        ).createShader(bounds),
        child: const Text(
          'Aegis',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Colors.white),
          onPressed: () {
            // TODO: Implement search
          },
        ),
        Stack(
          children: [
            IconButton(
              icon: const Icon(
                Icons.notifications_outlined,
                color: Colors.white,
              ),
              onPressed: () {
                // TODO: Implement notifications
              },
            ),
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFFef4444),
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: const Text(
                  '3',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF18181b),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Feed',
                index: 0,
              ),
              _buildNavItem(
                icon: Icons.emoji_events_outlined,
                activeIcon: Icons.emoji_events,
                label: 'Tournaments',
                index: 1,
              ),
              _buildNavItem(
                icon: Icons.group_outlined,
                activeIcon: Icons.group,
                label: 'TeamUp',
                index: 2,
              ),
              _buildNavItem(
                icon: Icons.chat_bubble_outline,
                activeIcon: Icons.chat_bubble,
                label: 'Messages',
                index: 3,
              ),
              _buildNavItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'Profile',
                index: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final isActive = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(
                  colors: [Color(0xFF06b6d4), Color(0xFF7c3aed)],
                )
              : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? Colors.white : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF18181b),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Consumer(
                    builder: (context, ref, child) {
                      final profileState = ref.watch(userProfileProvider);
                      final profile = profileState.profile;

                      return ProfileAvatar(
                        imageUrl: profile?.profilePicture,
                        fallbackText: profile?.inGameName ?? profile?.username,
                        size: 70,
                        borderWidth: 2,
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Consumer(
                    builder: (context, ref, child) {
                      final profileState = ref.watch(userProfileProvider);
                      final profile = profileState.profile;

                      return Column(
                        children: [
                          Text(
                            profile?.inGameName ??
                                profile?.username ??
                                'Player',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (profile?.realName != null)
                            Text(
                              profile!.realName!,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.monetization_on,
                          color: Colors.amber.shade300,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          '0',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildDrawerItem(
                    icon: Icons.emoji_events,
                    title: 'Rewards & Coins',
                    color: const Color(0xFFf59e0b),
                    onTap: () {
                      // TODO: Implement rewards navigation
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.groups,
                    title: 'Team Management',
                    color: const Color(0xFF7c3aed),
                    onTap: () {
                      // TODO: Implement team management navigation
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.leaderboard,
                    title: 'Leaderboards',
                    color: const Color(0xFF06b6d4),
                    onTap: () {
                      // TODO: Implement leaderboards navigation
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.notifications,
                    title: 'Notifications',
                    color: const Color(0xFFef4444),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFef4444),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        '3',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    onTap: () {
                      // TODO: Implement notifications navigation
                    },
                  ),
                  const Divider(
                    color: Color(0xFF27272a),
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                  ),
                  _buildDrawerItem(
                    icon: Icons.settings,
                    title: 'Settings',
                    color: Colors.grey,
                    onTap: () {
                      // TODO: Implement settings navigation
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                    color: Colors.grey,
                    onTap: () {
                      // TODO: Implement help navigation
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.policy_outlined,
                    title: 'Community Guidelines',
                    color: Colors.grey,
                    onTap: () {
                      // TODO: Implement guidelines navigation
                    },
                  ),
                  const Divider(
                    color: Color(0xFF27272a),
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                  ),
                  _buildDrawerItem(
                    icon: Icons.logout,
                    title: 'Logout',
                    color: const Color(0xFFef4444),
                    onTap: () async {
                      // Show confirmation dialog before logout
                      final shouldLogout = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: const Color(0xFF18181b),
                          title: const Text(
                            'Confirm Logout',
                            style: TextStyle(color: Colors.white),
                          ),
                          content: const Text(
                            'Are you sure you want to logout?',
                            style: TextStyle(color: Colors.white),
                          ),
                          actions: [
                            TextButton(
                              child: const Text(
                                'Cancel',
                                style: TextStyle(color: Colors.grey),
                              ),
                              onPressed: () => Navigator.of(context).pop(false),
                            ),
                            TextButton(
                              child: const Text(
                                'Logout',
                                style: TextStyle(color: Color(0xFFef4444)),
                              ),
                              onPressed: () => Navigator.of(context).pop(true),
                            ),
                          ],
                        ),
                      );
                      if (shouldLogout == true) {
                        final authService = ref.read(authServiceProvider);
                        await authService.logout();
                        // Clear profile state
                        ref.read(userProfileProvider.notifier).clearProfile();
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                            (route) => false,
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Version 1.0.0',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required Color color,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}

// Placeholder screen widget - replace with your actual screens
class PlaceholderScreen extends StatelessWidget {
  final String title;

  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction, size: 64, color: Colors.grey.shade700),
          const SizedBox(height: 16),
          Text(
            '$title Screen',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'TODO: Implement $title functionality',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
