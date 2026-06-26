import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/zonez_colors.dart';
import '../../../../models/map_lounge.dart';
import '../../../../providers/app_state_provider.dart';
import '../../../../providers/lounge_ratings_provider.dart';
import 'explore_map_bottom_card.dart';

/// Fixed panel below the map — cards scroll horizontally, not over the map.
class ExploreMapBottomCarousel extends StatelessWidget {
  const ExploreMapBottomCarousel({
    super.key,
    required this.lounges,
    required this.pageController,
    required this.loungeProvider,
    required this.appState,
    required this.onFavoriteTap,
    required this.onOpenDetails,
    required this.distanceLabelFor,
    required this.onPageChanged,
  });

  final List<MapLounge> lounges;
  final PageController pageController;
  final LoungeRatingsProvider loungeProvider;
  final AppStateProvider appState;
  final void Function(String loungeName) onFavoriteTap;
  final void Function(String loungeId) onOpenDetails;
  final String? Function(MapLounge lounge) distanceLabelFor;
  final ValueChanged<int> onPageChanged;

  /// Enough height for compact LoungeCard without overflow.
  static const _carouselHeight = 292.0;

  @override
  Widget build(BuildContext context) {
    if (lounges.isEmpty) return const SizedBox.shrink();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: ZonezColors.cardDark,
        border: Border(
          top: BorderSide(
            color: ZonezColors.neonPurple.withValues(alpha: 0.45),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: ZonezColors.neonPurple.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ZonezColors.textMuted.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            if (lounges.length > 1) ...[
              const SizedBox(height: 6),
              Text(
                'اسحب لاستكشاف الصالات القريبة',
                style: GoogleFonts.cairo(
                  fontSize: 11,
                  color: ZonezColors.neonCyan.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 8),
            SizedBox(
              height: _carouselHeight,
              child: PageView.builder(
                controller: pageController,
                onPageChanged: onPageChanged,
                itemCount: lounges.length,
                padEnds: false,
                itemBuilder: (context, index) {
                  final mapLounge = lounges[index];
                  final loungeModel = loungeProvider.loungeById(mapLounge.id);
                  final favoriteName = loungeModel?.name ?? mapLounge.name;

                  return Padding(
                    padding: EdgeInsets.only(
                      left: index == 0 ? 12 : 6,
                      right: index == lounges.length - 1 ? 12 : 6,
                      bottom: 8,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: ExploreMapBottomCard(
                        mapLounge: mapLounge,
                        lounge: loungeModel,
                        distanceLabel: distanceLabelFor(mapLounge),
                        isFavorite: appState.isFavorite(favoriteName),
                        onFavoriteTap: () => onFavoriteTap(favoriteName),
                        onOpenDetails: () => onOpenDetails(mapLounge.id),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
