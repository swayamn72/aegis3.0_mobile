import 'package:flutter/material.dart';
import '../models/team_model.dart';

// ============================================================================
// Stat Box Widget
// ============================================================================
class StatBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const StatBox({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x1A18181B),
        border: Border.all(color: const Color(0xFF27272A)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Player Card Widget
// ============================================================================
class PlayerCard extends StatelessWidget {
  final Player player;
  final bool isCaptain;
  final bool showActions;
  final VoidCallback? onKick;

  const PlayerCard({
    super.key,
    required this.player,
    this.isCaptain = false,
    this.showActions = false,
    this.onKick,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x80000000),
        border: Border.all(color: const Color(0xFF27272A)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              // Profile Picture
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF27272A), width: 2),
                ),
                child: player.profilePicture != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.network(
                          player.profilePicture!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF06B6D4), Color(0xFFA855F7)],
                              ),
                            ),
                            child: Center(
                              child: Text(
                                player.username[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    : Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF06B6D4), Color(0xFFA855F7)],
                          ),
                        ),
                        child: Center(
                          child: Text(
                            player.username[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 12),

              // Player Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            player.inGameName ?? player.username,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (isCaptain) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.stars,
                            color: Color(0xFFF59E0B),
                            size: 16,
                          ),
                        ],
                        if (player.verified ?? false) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.verified,
                            color: Color(0xFF06B6D4),
                            size: 16,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      player.realName ?? player.username,
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  ],
                ),
              ),

              // Actions
              if (showActions && onKick != null)
                OutlinedButton(
                  onPressed: onKick,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0x4DEF4444)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                  ),
                  child: const Text(
                    'Kick',
                    style: TextStyle(color: Color(0xFFEF4444), fontSize: 12),
                  ),
                )
              else if (isCaptain)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0x1AF59E0B),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Captain',
                    style: TextStyle(
                      color: Color(0xFFF59E0B),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Stats Grid
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0x1A27272A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Role',
                        style: TextStyle(color: Colors.grey[400], fontSize: 10),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        player.inGameRole?.join(', ') ?? 'Player',
                        style: const TextStyle(
                          color: Color(0xFF06B6D4),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0x1A27272A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Rating',
                        style: TextStyle(color: Colors.grey[400], fontSize: 10),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${player.aegisRating?.toInt() ?? 0}',
                        style: const TextStyle(
                          color: Color(0xFF06B6D4),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Additional Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                Icons.emoji_events,
                '${player.tournamentsPlayed ?? 0}',
                'Tournaments',
                const Color(0xFFF59E0B),
              ),
              _buildStatItem(
                Icons.track_changes,
                '${player.matchesPlayed ?? 0}',
                'Matches',
                const Color(0xFF10B981),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Text(value, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 10)),
      ],
    );
  }
}

// ============================================================================
// Team Invitation Card Widget
// ============================================================================
class TeamInvitationCard extends StatelessWidget {
  final TeamInvitation invitation;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  final bool isLoading;

  const TeamInvitationCard({
    super.key,
    required this.invitation,
    this.onAccept,
    this.onDecline,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x1A18181B),
        border: Border.all(color: const Color(0xFF27272A)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Team Logo
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF27272A)),
                ),
                child: invitation.team?.logo != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          invitation.team!.logo!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.shield,
                            color: Color(0xFF3B82F6),
                          ),
                        ),
                      )
                    : Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF3B82F6), Color(0xFF1E40AF)],
                          ),
                        ),
                        child: const Icon(Icons.shield, color: Colors.white),
                      ),
              ),
              const SizedBox(width: 12),

              // Team Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invitation.team?.teamName ?? 'Unknown Team',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'From ${invitation.fromPlayer?.username ?? 'Unknown'}',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (invitation.message != null && invitation.message!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0x1A27272A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                invitation.message!,
                style: TextStyle(color: Colors.grey[300], fontSize: 14),
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : onAccept,
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Accept'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isLoading ? null : onDecline,
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Decline'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF27272A)),
                    foregroundColor: Colors.grey[400],
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Empty State Widget
// ============================================================================
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
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
              child: Icon(icon, size: 40, color: const Color(0xFF52525B)),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
            if (action != null) ...[const SizedBox(height: 24), action!],
          ],
        ),
      ),
    );
  }
}
