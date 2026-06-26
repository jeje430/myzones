import 'package:flutter/material.dart';

import '../../../../core/theme/zonez_colors.dart';
import '../../../../models/lounge_model.dart';
import '../../../../models/map_lounge.dart';
import '../lounge_card.dart';
import '../zonez_lounge_card.dart';

/// Single lounge card item in the Explore map bottom carousel.
class ExploreMapBottomCard extends StatelessWidget {
  const ExploreMapBottomCard({
    super.key,
    required this.mapLounge,
    required this.lounge,
    required this.distanceLabel,
    required this.isFavorite,
    required this.onFavoriteTap,
    required this.onOpenDetails,
  });

  final MapLounge mapLounge;
  final LoungeModel? lounge;
  final String? distanceLabel;
  final bool isFavorite;
  final VoidCallback onFavoriteTap;
  final VoidCallback onOpenDetails;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: ZonezColors.neonPurple.withValues(alpha: 0.38),
            blurRadius: 22,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: lounge != null
          ? ZonezLoungeCard(
              lounge: lounge!,
              distanceLabel: distanceLabel,
              isFavorite: isFavorite,
              onFavoriteTap: onFavoriteTap,
              onOpenDetails: onOpenDetails,
              removeOuterMargin: true,
            )
          : LoungeCard(
              compact: true,
              removeOuterMargin: true,
              loungeId: mapLounge.id,
              name: mapLounge.name,
              rating: mapLounge.rating,
              reviews: mapLounge.reviews,
              location: mapLounge.locationLabel,
              devices: mapLounge.devices,
              price: mapLounge.price,
              imageUrl: mapLounge.imageUrl,
              services: mapLounge.services,
              workHoursLabel: mapLounge.workHoursLabel,
              distanceLabel: distanceLabel,
              isFavorite: isFavorite,
              onFavoriteTap: onFavoriteTap,
              onTap: onOpenDetails,
              onBookTap: onOpenDetails,
            ),
    );
  }
}
