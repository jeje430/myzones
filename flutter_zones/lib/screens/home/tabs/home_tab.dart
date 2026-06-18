import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/zonez_colors.dart';
import '../../../providers/app_state_provider.dart';
import '../../../providers/lounge_ratings_provider.dart';
import '../../../providers/zones_data_provider.dart';
import '../../../widgets/zonez_logo.dart';
import '../../lounge/lounge_details_screen.dart';
import '../widgets/lounge_card.dart';
import '../widgets/offers_carousel.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({
    super.key,
    required this.onOpenDrawer,
    required this.onFavoriteTap,
  });

  final VoidCallback onOpenDrawer;
  final void Function(String loungeName) onFavoriteTap;

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ZonesDataProvider>().loadOffers();
      context.read<LoungeRatingsProvider>().refreshLounges();
    });
  }

  void _openLoungeDetails(String loungeId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LoungeDetailsScreen(loungeId: loungeId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final zonesData = context.watch<ZonesDataProvider>();
    final lounges = context.watch<LoungeRatingsProvider>().lounges;
    final defaultLounge =
        lounges.isNotEmpty ? lounges.first.name : 'Game Zone Arena';
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final muted = Theme.of(context).brightness == Brightness.dark
        ? ZonezColors.textMuted
        : ZonezColors.lightTextMuted;

    return Column(
      children: [
        _buildHeader(widget.onOpenDrawer, onSurface, muted),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (zonesData.isLoadingOffers)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: ZonezColors.neonPurple,
                      ),
                    ),
                  )
                else if (zonesData.offersError != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      zonesData.offersError!,
                      style: GoogleFonts.cairo(color: ZonezColors.neonRed),
                    ),
                  )
                else
                  OffersCarousel(
                    offers: zonesData.activeOffers,
                    loungeName: defaultLounge,
                  ),
                const SizedBox(height: 16),
                _buildSectionTitle(context),
                const SizedBox(height: 10),
                if (lounges.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'لا توجد صالات متاحة حالياً',
                        style: GoogleFonts.cairo(color: muted, fontSize: 14),
                      ),
                    ),
                  )
                else
                  ...lounges.map(
                    (l) => LoungeCard(
                      compact: true,
                      loungeId: l.id,
                      name: l.name,
                      rating: l.loungeAverageRating,
                      reviews: l.reviewCount,
                      location: l.location,
                      devices: l.totalDevices,
                      price: l.startingPrice,
                      isFavorite: appState.isFavorite(l.name),
                      onFavoriteTap: () => widget.onFavoriteTap(l.name),
                      onTap: () => _openLoungeDetails(l.id),
                      onBookTap: () => _openLoungeDetails(l.id),
                    ),
                  ),
                const SizedBox(height: 72),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(VoidCallback onOpenDrawer, Color onSurface, Color muted) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: onOpenDrawer,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? ZonezColors.neonPurple.withValues(alpha: 0.4)
                          : ZonezColors.lightPrimary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Icon(Icons.menu, color: onSurface),
                ),
              ),
              const SizedBox(width: 44),
            ],
          ),
          const SizedBox(height: 8),
          const ZonezLogo(size: 96, imageOnly: true, showText: false),
          const SizedBox(height: 6),
          Text(
            'ZONEZ',
            style: GoogleFonts.orbitron(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: onSurface,
              letterSpacing: 8,
              shadows: [
                Shadow(
                  color: ZonezColors.neonCyan.withValues(alpha: 0.55),
                  blurRadius: 14,
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'اكتشف أفضل الصالات القريبة منك',
            style: GoogleFonts.cairo(fontSize: 13, color: muted),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.sports_esports,
          color: Theme.of(context).brightness == Brightness.dark
              ? ZonezColors.neonPurple
              : ZonezColors.lightPrimary,
          size: 20,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            'صالات الألعاب',
            style: GoogleFonts.cairo(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
