import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/zonez_colors.dart';
import '../../core/theme/zonez_typography.dart';
import '../../models/lounge_model.dart';
import '../../providers/lounge_ratings_provider.dart';
import '../../widgets/circuit_background.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/neon_gradient_button.dart';
import '../../widgets/rating/device_rating_badges.dart';
import '../../widgets/rating/lounge_reviews_panel.dart';
import '../../widgets/rating/star_rating_row.dart';
import '../booking/lounge_booking_flow_screen.dart';

class LoungeDetailsScreen extends StatelessWidget {
  const LoungeDetailsScreen({
    super.key,
    required this.loungeId,
  });

  final String loungeId;

  @override
  Widget build(BuildContext context) {
    final ratingsProvider = context.watch<LoungeRatingsProvider>();
    final lounge = ratingsProvider.loungeById(loungeId);

    if (lounge == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('تفاصيل الصالة', style: ZonezTypography.title()),
        ),
        body: Center(
          child: Text(
            'الصالة غير موجودة',
            style: ZonezTypography.body(color: ZonezColors.textMuted),
          ),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(lounge.name, style: ZonezTypography.title(size: 17)),
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          const CircuitBackground(),
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 100, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _HeroImage(lounge: lounge),
                const SizedBox(height: 16),
                _LoungeRatingHeader(lounge: lounge),
                const SizedBox(height: 12),
                DeviceRatingBadges(devices: lounge.availableDevices),
                const SizedBox(height: 20),
                GlassContainer(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        lounge.description,
                        style: ZonezTypography.body(size: 14),
                      ),
                      const SizedBox(height: 14),
                      _InfoChip(
                        icon: Icons.location_on_outlined,
                        label: lounge.location,
                      ),
                      const SizedBox(height: 8),
                      _InfoChip(
                        icon: Icons.sports_esports_outlined,
                        label: '${lounge.totalDevices} جهاز متاح',
                      ),
                      const SizedBox(height: 8),
                      _InfoChip(
                        icon: Icons.payments_outlined,
                        label: 'يبدأ من ${lounge.startingPrice} د.ل / ساعة',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                LoungeReviewsPanel(lounge: lounge),
                const SizedBox(height: 28),
                NeonGradientButton(
                  label: 'احجز الآن',
                  icon: Icons.event_available,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            LoungeBookingFlowScreen(lounge: lounge),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage({required this.lounge});

  final LoungeModel lounge;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ZonezColors.neonPurple.withValues(alpha: 0.55),
              ZonezColors.neonCyan.withValues(alpha: 0.3),
            ],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (lounge.imageUrl != null)
              Image.network(
                lounge.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    ZonezColors.deepBlack.withValues(alpha: 0.6),
                  ],
                ),
              ),
            ),
            Center(
              child: Icon(
                Icons.sports_esports,
                size: 64,
                color: Colors.white.withValues(alpha: 0.25),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoungeRatingHeader extends StatelessWidget {
  const _LoungeRatingHeader({required this.lounge});

  final LoungeModel lounge;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lounge.name, style: ZonezTypography.display(size: 20)),
                Text(
                  '${lounge.reviewCount} تقييم',
                  style: ZonezTypography.caption(),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              RatingStarsDisplay(rating: lounge.loungeAverageRating, size: 18),
              Text(
                'تقييم الصالة العامة',
                style: ZonezTypography.caption(size: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: ZonezColors.neonCyan),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: ZonezTypography.body(size: 13)),
        ),
      ],
    );
  }
}
