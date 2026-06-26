import 'package:flutter/material.dart';

import '../../../models/lounge_model.dart';
import 'lounge_card.dart';

/// Shared lounge card — Home, Explore map, Search, Favorites.
class ZonezLoungeCard extends StatelessWidget {
  const ZonezLoungeCard({
    super.key,
    required this.lounge,
    required this.isFavorite,
    required this.onFavoriteTap,
    required this.onOpenDetails,
    this.compact = true,
    this.distanceLabel,
    this.openDetailsOnCardTap = true,
    this.removeOuterMargin = false,
  });

  final LoungeModel lounge;
  final bool isFavorite;
  final VoidCallback onFavoriteTap;
  final VoidCallback onOpenDetails;
  final bool compact;
  final String? distanceLabel;

  /// When false (Explore map pin), only the book button opens details.
  final bool openDetailsOnCardTap;
  final bool removeOuterMargin;

  @override
  Widget build(BuildContext context) {
    return LoungeCard(
      compact: compact,
      removeOuterMargin: removeOuterMargin,
      loungeId: lounge.id,
      name: lounge.name,
      rating: lounge.loungeAverageRating,
      reviews: lounge.reviewCount,
      location: lounge.location,
      devices: lounge.totalDevices,
      price: lounge.startingPrice,
      imageUrl: lounge.imageUrl,
      services: lounge.services,
      workHoursLabel: lounge.workHoursLabel,
      distanceLabel: distanceLabel,
      isFavorite: isFavorite,
      onFavoriteTap: onFavoriteTap,
      onTap: openDetailsOnCardTap ? onOpenDetails : null,
      onBookTap: onOpenDetails,
    );
  }
}
