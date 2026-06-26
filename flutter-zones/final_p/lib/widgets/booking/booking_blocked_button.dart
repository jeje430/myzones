import 'package:flutter/material.dart';

import '../../core/theme/zonez_colors.dart';
import '../../core/theme/zonez_typography.dart';

/// Red disabled booking CTA when emergency stop is active.
class BookingBlockedButton extends StatelessWidget {
  const BookingBlockedButton({
    super.key,
    required this.label,
    this.message,
    this.icon = Icons.block,
  });

  final String label;
  final String? message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (message != null && message!.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ZonezColors.neonRed.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ZonezColors.neonRed.withValues(alpha: 0.35)),
            ),
            child: Text(
              message!,
              textAlign: TextAlign.center,
              style: ZonezTypography.caption(
                size: 12,
                color: ZonezColors.neonRed,
                weight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        Container(
          height: 54,
          decoration: BoxDecoration(
            color: ZonezColors.neonRed.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: ZonezColors.neonRed.withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: ZonezTypography.title(size: 15, color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
