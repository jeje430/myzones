import 'package:flutter/material.dart';

import '../../../core/theme/zonez_colors.dart';
import '../../../models/lounge_model.dart';
import '../../../widgets/glass_container.dart';
import '../../../widgets/neon_gradient_button.dart';

class LoungeStationCard extends StatelessWidget {
  const LoungeStationCard({
    super.key,
    required this.lounge,
    required this.onViewTournaments,
  });

  final LoungeModel lounge;
  final VoidCallback onViewTournaments;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final muted = theme.brightness == Brightness.dark
        ? ZonezColors.textMuted
        : ZonezColors.lightTextMuted;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onViewTournaments,
        borderRadius: BorderRadius.circular(16),
        child: GlassContainer(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _LoungeThumbnail(lounge: lounge),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lounge.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: muted,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            lounge.location,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: muted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    NeonGradientButton(
                      label: 'عرض البطولات',
                      icon: Icons.emoji_events_outlined,
                      height: 42,
                      onPressed: onViewTournaments,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoungeThumbnail extends StatelessWidget {
  const _LoungeThumbnail({required this.lounge});

  final LoungeModel lounge;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              ZonezColors.neonPurple.withValues(alpha: 0.5),
              ZonezColors.neonCyan.withValues(alpha: 0.3),
            ],
          ),
        ),
        child: lounge.imageUrl != null
            ? Image.network(
                lounge.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(context),
              )
            : _placeholder(context),
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    return Center(
      child: Icon(
        Icons.sports_esports,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
        size: 32,
      ),
    );
  }
}
