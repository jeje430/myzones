import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/zonez_colors.dart';
import '../../models/lounge_model.dart';
import 'star_rating_row.dart';

class DeviceRatingBadges extends StatelessWidget {
  const DeviceRatingBadges({
    super.key,
    required this.devices,
  });

  final List<DevicePackage> devices;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: devices.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final device = devices[index];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: ZonezColors.inputBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: ZonezColors.neonPurple.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(device.icon, size: 14, color: ZonezColors.neonCyan),
                const SizedBox(width: 6),
                Text(
                  device.nameAr,
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                RatingStarsDisplay(
                  rating: device.averageRating,
                  size: 11,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class DeviceRatingBadge extends StatelessWidget {
  const DeviceRatingBadge({
    super.key,
    required this.rating,
    this.compact = false,
  });

  final double rating;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: ZonezColors.neonGold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: ZonezColors.neonGold.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, color: ZonezColors.neonGold, size: 14),
          const SizedBox(width: 3),
          Text(
            rating.toStringAsFixed(1),
            style: GoogleFonts.cairo(
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.bold,
              color: ZonezColors.neonGold,
            ),
          ),
        ],
      ),
    );
  }
}
