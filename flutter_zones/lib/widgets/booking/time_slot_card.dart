import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/zonez_colors.dart';
import 'neon_time_slot_icon.dart';

/// Shared time-slot card — lounge list row or offer grid tile.
class TimeSlotCard extends StatelessWidget {
  const TimeSlotCard({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: selected ? ZonezColors.neonGradient : null,
            color: selected ? null : ZonezColors.inputBg,
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : ZonezColors.neonPurple.withValues(alpha: 0.3),
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: ZonezColors.neonPurple.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              NeonTimeSlotIcon(selected: selected, size: 16),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: selected ? Colors.white : ZonezColors.textMuted,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: selected
            ? ZonezColors.neonPurple.withValues(alpha: 0.2)
            : ZonezColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? ZonezColors.neonPurple
                    : ZonezColors.neonPurple.withValues(alpha: 0.2),
                width: selected ? 2 : 1,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: ZonezColors.neonCyan.withValues(alpha: 0.2),
                        blurRadius: 16,
                        spreadRadius: 0,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                NeonTimeSlotIcon(selected: selected),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ),
                ),
                if (selected)
                  const Icon(Icons.check_circle, color: ZonezColors.neonPurple),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
