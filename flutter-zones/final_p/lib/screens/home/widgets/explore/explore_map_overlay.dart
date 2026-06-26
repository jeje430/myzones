import 'package:flutter/material.dart';

import '../../../../core/theme/zonez_colors.dart';

/// Gradient overlays so the map matches ZONEZ dark neon screens.
class ExploreMapOverlay extends StatelessWidget {
  const ExploreMapOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  ZonezColors.darkNavy.withValues(alpha: 0.82),
                  Colors.transparent,
                  Colors.transparent,
                  ZonezColors.deepBlack.withValues(alpha: 0.55),
                ],
                stops: const [0, 0.22, 0.72, 1],
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 140,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    ZonezColors.neonPurple.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pin legend matching map marker colors.
class ExplorePinLegend extends StatelessWidget {
  const ExplorePinLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: ZonezColors.cardDark.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: ZonezColors.neonPurple.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: ZonezColors.neonPurple.withValues(alpha: 0.18),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          _LegendDot(color: ZonezColors.neonCyan, label: 'PS5'),
          SizedBox(width: 10),
          _LegendDot(color: ZonezColors.neonPurple, label: 'PC'),
          SizedBox(width: 10),
          _LegendDot(color: ZonezColors.neonGold, label: 'Mixed'),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.65),
                blurRadius: 6,
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: ZonezColors.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
