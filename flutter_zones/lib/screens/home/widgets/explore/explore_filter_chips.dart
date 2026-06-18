import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/zonez_colors.dart';

class ExploreFilterChips extends StatelessWidget {
  const ExploreFilterChips({
    super.key,
    required this.ps5Selected,
    required this.pcSelected,
    required this.openNowSelected,
    required this.onPs5Tap,
    required this.onPcTap,
    required this.onOpenNowTap,
  });

  final bool ps5Selected;
  final bool pcSelected;
  final bool openNowSelected;
  final VoidCallback onPs5Tap;
  final VoidCallback onPcTap;
  final VoidCallback onOpenNowTap;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _NeonFilterChip(
            label: 'مفتوح الآن',
            icon: Icons.schedule_rounded,
            selected: openNowSelected,
            accentColor: ZonezColors.neonCyan,
            onTap: onOpenNowTap,
          ),
          const SizedBox(width: 10),
          _NeonFilterChip(
            label: 'صالات PC',
            icon: Icons.computer_rounded,
            selected: pcSelected,
            accentColor: ZonezColors.neonPurple,
            onTap: onPcTap,
          ),
          const SizedBox(width: 10),
          _NeonFilterChip(
            label: 'صالات PS5',
            icon: Icons.videogame_asset_rounded,
            selected: ps5Selected,
            accentColor: ZonezColors.neonCyan,
            onTap: onPs5Tap,
          ),
        ],
      ),
    );
  }
}

class _NeonFilterChip extends StatelessWidget {
  const _NeonFilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.accentColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: selected
              ? LinearGradient(
                  colors: [
                    accentColor.withValues(alpha: 0.35),
                    ZonezColors.neonPurple.withValues(alpha: 0.25),
                  ],
                )
              : null,
          color: selected ? null : ZonezColors.cardDark.withValues(alpha: 0.72),
          border: Border.all(
            color: selected
                ? accentColor.withValues(alpha: 0.9)
                : ZonezColors.borderMuted.withValues(alpha: 0.6),
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.45),
                    blurRadius: 14,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? accentColor : ZonezColors.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                color: selected ? Colors.white : ZonezColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
