import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/zonez_colors.dart';
import '../../../core/theme/zonez_typography.dart';
import '../../../models/device_rating.dart';
import '../../../models/lounge_model.dart';
import '../../../providers/lounge_booking_provider.dart';
import '../../../providers/lounge_ratings_provider.dart';
import '../../../widgets/neon_gradient_button.dart';
import '../../../widgets/rating/device_rating_badges.dart';
import '../../../widgets/rating/device_rating_tile.dart';

class BookingStepPackage extends StatefulWidget {
  const BookingStepPackage({super.key, required this.lounge});

  final LoungeModel lounge;

  @override
  State<BookingStepPackage> createState() => _BookingStepPackageState();
}

class _BookingStepPackageState extends State<BookingStepPackage> {
  final Map<String, int> _pendingRatings = {};
  bool _showRatingPanel = false;
  bool _isSubmittingRatings = false;

  LoungeModel get lounge {
    final provider = context.watch<LoungeRatingsProvider>();
    return provider.loungeById(widget.lounge.id) ?? widget.lounge;
  }

  List<DevicePackage> get bookable => lounge.catalogPackages;

  Future<void> _submitRatings() async {
    final ratings = _pendingRatings.entries
        .where((e) => e.value >= 1 && e.value <= 5)
        .map(
          (e) => DeviceRatingInput(
            device: lounge.deviceById(e.key)!,
            stars: e.value,
          ),
        )
        .toList();

    if (ratings.isEmpty) return;

    setState(() => _isSubmittingRatings = true);

    final provider = context.read<LoungeRatingsProvider>();
    final success = await provider.submitCombinedRatings(
      loungeId: lounge.id,
      deviceRatings: ratings,
    );

    if (!mounted) return;

    setState(() {
      _isSubmittingRatings = false;
      if (success) {
        _pendingRatings.clear();
        _showRatingPanel = false;
      }
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم إرسال التقييم بنجاح',
            style: ZonezTypography.body(),
            textAlign: TextAlign.center,
          ),
          backgroundColor: ZonezColors.neonCyan,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final flow = context.watch<LoungeBookingProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'اختيار الباقة',
            style: ZonezTypography.title(),
          ),
          const SizedBox(height: 8),
          Text(
            'اختر نوع الجهاز — الأسعار بالساعة',
            style: ZonezTypography.caption(size: 13),
          ),
          const SizedBox(height: 16),
          DeviceRatingBadges(devices: bookable),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => setState(() => _showRatingPanel = !_showRatingPanel),
            icon: Icon(
              _showRatingPanel ? Icons.expand_less : Icons.star_outline,
              color: ZonezColors.neonCyan,
            ),
            label: Text(
              _showRatingPanel ? 'إخفاء التقييم' : 'قيّم الأجهزة',
              style: ZonezTypography.accent(size: 13),
            ),
          ),
          if (_showRatingPanel) ...[
            const SizedBox(height: 8),
            ...bookable.map(
              (device) => DeviceRatingStarsTile(
                device: device,
                input: DeviceRatingInput(
                  device: device,
                  stars: _pendingRatings[device.id] ?? device.userRating ?? 0,
                ),
                onStarsChanged: (stars) {
                  setState(() => _pendingRatings[device.id] = stars);
                },
              ),
            ),
            if (_pendingRatings.values.any((s) => s >= 1))
              _isSubmittingRatings
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          color: ZonezColors.neonPurple,
                        ),
                      ),
                    )
                  : NeonGradientButton(
                      label: 'إرسال التقييم',
                      icon: Icons.send_rounded,
                      onPressed: _submitRatings,
                    ),
            const SizedBox(height: 16),
          ],
          if (bookable.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'لا توجد باقات متاحة حالياً',
                  style: ZonezTypography.caption(),
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.82,
              ),
              itemCount: bookable.length,
              itemBuilder: (context, index) {
                final device = bookable[index];
                final selected = flow.selectedDevice?.id == device.id;
                final pendingStars =
                    _pendingRatings[device.id] ?? device.userRating ?? 0;

                return _DeviceCard(
                  device: device,
                  selected: selected,
                  pendingStars: pendingStars,
                  onTap: () => flow.selectDevice(device),
                  onStarsChanged: (stars) {
                    setState(() => _pendingRatings[device.id] = stars);
                  },
                );
              },
            ),
          if (_pendingRatings.values.any((s) => s >= 1) && !_showRatingPanel) ...[
            const SizedBox(height: 16),
            _isSubmittingRatings
                ? const Center(
                    child: CircularProgressIndicator(color: ZonezColors.neonPurple),
                  )
                : NeonGradientButton(
                    label: 'إرسال التقييم',
                    icon: Icons.send_rounded,
                    onPressed: _submitRatings,
                  ),
          ],
        ],
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({
    required this.device,
    required this.selected,
    required this.pendingStars,
    required this.onTap,
    required this.onStarsChanged,
  });

  final DevicePackage device;
  final bool selected;
  final int pendingStars;
  final VoidCallback onTap;
  final ValueChanged<int> onStarsChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? ZonezColors.neonPurple.withValues(alpha: 0.15)
          : ZonezColors.cardDark,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? ZonezColors.neonPurple
                  : ZonezColors.neonPurple.withValues(alpha: 0.2),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(device.icon, color: ZonezColors.neonCyan, size: 28),
              const SizedBox(height: 6),
              Text(
                device.nameAr,
                style: ZonezTypography.title(size: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (device.specs != null) ...[
                const SizedBox(height: 2),
                Text(
                  device.specs!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ZonezTypography.caption(size: 9),
                ),
              ],
              const Spacer(),
              Text(
                '${device.hourlyRate.toStringAsFixed(0)} د.ل/ساعة',
                style: ZonezTypography.accent(size: 11),
              ),
              const SizedBox(height: 4),
              DeviceRatingBadge(
                rating: device.averageRating,
                compact: true,
                ratingsCount: device.ratingsCount,
              ),
              const SizedBox(height: 6),
              DeviceInlineStarRating(
                rating: pendingStars,
                onChanged: onStarsChanged,
                starSize: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
