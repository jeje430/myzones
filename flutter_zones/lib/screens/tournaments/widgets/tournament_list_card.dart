import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/zonez_colors.dart';
import '../../../core/theme/zonez_typography.dart';
import '../../../models/tournament.dart';
import '../../../providers/tournament_provider.dart';
import '../../../widgets/glass_container.dart';
import '../../../widgets/neon_gradient_button.dart';

class TournamentListCard extends StatelessWidget {
  const TournamentListCard({
    super.key,
    required this.tournament,
    required this.action,
    required this.formattedDate,
    required this.onAction,
  });

  final Tournament tournament;
  final TournamentAction action;
  final String formattedDate;
  final VoidCallback onAction;

  String get _actionLabel {
    switch (action) {
      case TournamentAction.join:
        return 'عرض التفاصيل';
      case TournamentAction.viewDetails:
        return 'عرض التفاصيل';
      case TournamentAction.viewResults:
        return 'عرض النتائج';
    }
  }

  IconData get _actionIcon {
    switch (action) {
      case TournamentAction.join:
      case TournamentAction.viewDetails:
        return Icons.info_outline;
      case TournamentAction.viewResults:
        return Icons.leaderboard_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TournamentProvider>();
    final live = provider.getTournament(tournament.id) ?? tournament;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final muted = Theme.of(context).brightness == Brightness.dark
        ? ZonezColors.textMuted
        : ZonezColors.lightTextMuted;
    final primary = Theme.of(context).brightness == Brightness.dark
        ? ZonezColors.neonPurple
        : ZonezColors.lightPrimary;

    return GestureDetector(
      onTap: onAction,
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              live.title,
              style: ZonezTypography.title(size: 16, color: onSurface),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  live.gameEmoji,
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(width: 8),
                Text(
                  live.gameName,
                  style: ZonezTypography.accent(
                    size: 13,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? ZonezColors.neonCyan
                        : ZonezColors.lightPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _InfoLine(
              icon: Icons.calendar_today_outlined,
              label: formattedDate,
              muted: muted,
            ),
            const SizedBox(height: 6),
            _InfoLine(
              icon: Icons.people_outline,
              label: '👥 ${live.participantCapacityLabel}',
              color: primary,
              muted: muted,
            ),
            const SizedBox(height: 6),
            _InfoLine(
              icon: Icons.emoji_events_outlined,
              label: live.prizeSummary,
              color: ZonezColors.neonGold,
              muted: muted,
            ),
            const SizedBox(height: 14),
            NeonGradientButton(
              label: _actionLabel,
              icon: _actionIcon,
              height: 44,
              onPressed: onAction,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.icon,
    required this.label,
    required this.muted,
    this.color,
  });

  final IconData icon;
  final String label;
  final Color muted;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: color ?? muted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: ZonezTypography.caption(
              size: 13,
              color: color ?? muted,
            ),
          ),
        ),
      ],
    );
  }
}

enum TournamentAction { join, viewDetails, viewResults }
