import 'package:flutter/material.dart';

import '../../core/theme/zonez_colors.dart';
import '../../core/theme/zonez_typography.dart';
import '../../models/device_rating.dart';
import '../../models/lounge_model.dart';
import 'star_rating_row.dart';

/// Compact package rating row — stars only, no comments.
class DeviceRatingStarsTile extends StatelessWidget {
  const DeviceRatingStarsTile({
    super.key,
    required this.device,
    required this.input,
    required this.onStarsChanged,
    this.showRatingsCount = true,
  });

  final DevicePackage device;
  final DeviceRatingInput input;
  final ValueChanged<int> onStarsChanged;
  final bool showRatingsCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ZonezColors.inputBg.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: input.stars > 0
              ? ZonezColors.neonPurple.withValues(alpha: 0.5)
              : ZonezColors.borderMuted.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(device.icon, color: ZonezColors.neonCyan, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(device.nameAr, style: ZonezTypography.title(size: 14)),
              ),
              if (device.averageRating > 0)
                RatingStarsDisplay(rating: device.averageRating, size: 12, showValue: true),
            ],
          ),
          if (showRatingsCount && device.ratingsCount > 0) ...[
            const SizedBox(height: 4),
            Text('${device.ratingsCount} تقييم', style: ZonezTypography.caption(size: 11)),
          ],
          const SizedBox(height: 10),
          StarRatingRow(
            rating: input.stars,
            onChanged: onStarsChanged,
            starSize: 28,
          ),
        ],
      ),
    );
  }
}

/// Compact inline star row for device selection cards.
class DeviceInlineStarRating extends StatelessWidget {
  const DeviceInlineStarRating({
    super.key,
    required this.rating,
    required this.onChanged,
    this.starSize = 18,
  });

  final int rating;
  final ValueChanged<int> onChanged;
  final double starSize;

  @override
  Widget build(BuildContext context) {
    return StarRatingRow(
      rating: rating,
      onChanged: onChanged,
      starSize: starSize,
    );
  }
}
