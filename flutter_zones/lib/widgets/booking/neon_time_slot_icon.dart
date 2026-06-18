import 'package:flutter/material.dart';

import '../../core/theme/zonez_colors.dart';

/// Glowing neon clock icon for time-slot cards (cyberpunk aesthetic).
class NeonTimeSlotIcon extends StatelessWidget {
  const NeonTimeSlotIcon({
    super.key,
    this.selected = false,
    this.size = 22,
  });

  final bool selected;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = selected ? ZonezColors.neonCyan : ZonezColors.neonPurple;

    return Container(
      width: size + 14,
      height: size + 14,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: selected ? 0.22 : 0.12),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: selected ? 0.55 : 0.35),
            blurRadius: selected ? 14 : 10,
            spreadRadius: selected ? 1 : 0,
          ),
        ],
        border: Border.all(
          color: color.withValues(alpha: selected ? 0.85 : 0.45),
          width: 1.5,
        ),
      ),
      child: Icon(
        Icons.access_time_filled_rounded,
        size: size,
        color: color,
      ),
    );
  }
}
