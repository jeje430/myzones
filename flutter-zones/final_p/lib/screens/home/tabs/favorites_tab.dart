import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/zonez_colors.dart';
import '../../../providers/app_state_provider.dart';
import '../../../providers/lounge_ratings_provider.dart';
import '../../lounge/lounge_details_screen.dart';
import '../widgets/lounge_card.dart';

class FavoritesTab extends StatelessWidget {
  const FavoritesTab({super.key, required this.onFavoriteTap});

  final void Function(String loungeName) onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final allLounges = context.watch<LoungeRatingsProvider>().lounges;
    final favorites =
        allLounges.where((l) => appState.isFavorite(l.name)).toList();
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              const Icon(Icons.favorite, color: ZonezColors.neonPurple),
              const SizedBox(width: 8),
              Text(
                'المفضلة',
                style: GoogleFonts.cairo(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: onSurface,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: favorites.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.favorite_border,
                        size: 64,
                        color: ZonezColors.textMuted.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'لا توجد صالات مفضلة بعد',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          color: ZonezColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'اضغط على القلب في بطاقة الصالة لإضافتها',
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          color: ZonezColors.textMuted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    ...favorites.map(
                      (l) => LoungeCard(
                        loungeId: l.id,
                        name: l.name,
                        rating: l.loungeAverageRating,
                        reviews: l.reviewCount,
                        location: l.location,
                        devices: l.totalDevices,
                        price: l.startingPrice,
                        isFavorite: true,
                        onFavoriteTap: () => onFavoriteTap(l.name),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  LoungeDetailsScreen(loungeId: l.id),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
        ),
      ],
    );
  }
}
