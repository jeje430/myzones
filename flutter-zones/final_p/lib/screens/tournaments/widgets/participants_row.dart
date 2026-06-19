import 'package:flutter/material.dart';

import '../../../core/theme/zonez_colors.dart';
import '../../../core/theme/zonez_typography.dart';
import '../../../models/tournament.dart';

class ParticipantsRow extends StatelessWidget {
  const ParticipantsRow({super.key, required this.participants});

  final List<TournamentParticipant> participants;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).brightness == Brightness.dark
        ? ZonezColors.textMuted
        : ZonezColors.lightTextMuted;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (participants.isEmpty) {
      return Text(
        'لا يوجد مشاركون بعد',
        style: ZonezTypography.caption(color: muted),
      );
    }

    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: participants.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final participant = participants[index];
          return Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isDark
                      ? ZonezColors.neonGradient
                      : ZonezColors.lightAccentGradient,
                  border: Border.all(
                    color: isDark
                        ? ZonezColors.neonCyan.withValues(alpha: 0.4)
                        : ZonezColors.lightPrimary.withValues(alpha: 0.3),
                  ),
                ),
                child: Center(
                  child: Text(
                    participant.name.isNotEmpty
                        ? participant.name[0]
                        : '?',
                    style: ZonezTypography.title(
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: 72,
                child: Text(
                  participant.name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ZonezTypography.caption(
                    size: 10,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
