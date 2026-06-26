import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/zonez_colors.dart';
import '../../core/theme/zonez_typography.dart';
import '../../models/device_rating.dart';
import '../../models/lounge_model.dart';
import '../../models/lounge_rating.dart';
import '../../providers/lounge_ratings_provider.dart';
import '../glass_container.dart';
import '../neon_gradient_button.dart';
import 'star_rating_row.dart';

/// Dedicated ratings section — hall + packages, stars only.
class LoungeRatingsBox extends StatefulWidget {
  const LoungeRatingsBox({super.key, required this.lounge});

  final LoungeModel lounge;

  @override
  State<LoungeRatingsBox> createState() => _LoungeRatingsBoxState();
}

class _LoungeRatingsBoxState extends State<LoungeRatingsBox> {
  late int _hallStars;
  late final Map<String, int> _packageStars;

  @override
  void initState() {
    super.initState();
    _hallStars = widget.lounge.userHallRating ?? 0;
    _packageStars = {
      for (final device in widget.lounge.devices)
        device.id: device.userRating ?? 0,
    };
  }

  Future<void> _submit() async {
    final provider = context.read<LoungeRatingsProvider>();
    final lounge = provider.loungeById(widget.lounge.id) ?? widget.lounge;

    final deviceInputs = _packageStars.entries
        .where((e) => e.value >= 1 && e.value <= 5)
        .map(
          (e) => DeviceRatingInput(
            device: lounge.deviceById(e.key)!,
            stars: e.value,
          ),
        )
        .toList();

    final hasHall = _hallStars >= 1 && _hallStars <= 5;
    if (!hasHall && deviceInputs.isEmpty) {
      _showSnack('يرجى اختيار نجمة واحدة على الأقل', isError: true);
      return;
    }

    final success = await provider.submitCombinedRatings(
      loungeId: lounge.id,
      generalRating: hasHall
          ? CategoryRatingInput(
              category: RatingCategory.general,
              stars: _hallStars,
            )
          : null,
      deviceRatings: deviceInputs,
    );

    if (!mounted) return;

    if (success) {
      final refreshed = provider.loungeById(lounge.id);
      if (refreshed != null) {
        setState(() {
          _hallStars = refreshed.userHallRating ?? 0;
          for (final device in refreshed.devices) {
            _packageStars[device.id] = device.userRating ?? 0;
          }
        });
      }
      _showSnack('تم إرسال التقييم بنجاح');
    } else if (provider.error != null) {
      _showSnack(provider.error!, isError: true);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: ZonezTypography.body(), textAlign: TextAlign.center),
        backgroundColor: isError ? ZonezColors.neonRed : ZonezColors.neonCyan,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LoungeRatingsProvider>();
    final lounge = provider.loungeById(widget.lounge.id) ?? widget.lounge;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(
          icon: Icons.star_outline,
          title: 'التقييمات',
          subtitle: 'قيّم الصالة والباقات بالنجوم',
        ),
        const SizedBox(height: 12),
        GlassContainer(
          padding: const EdgeInsets.all(16),
          borderColor: ZonezColors.neonPurple.withValues(alpha: 0.35),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(lounge.name, style: ZonezTypography.title(size: 16)),
              const SizedBox(height: 4),
              Row(
                children: [
                  RatingStarsDisplay(
                    rating: lounge.loungeAverageRating,
                    size: 14,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${lounge.reviewCount} تقييم',
                    style: ZonezTypography.caption(size: 11),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _PackageRatingRow(
                label: 'تقييم الصالة العامة',
                stars: _hallStars,
                averageRating: lounge.loungeAverageRating,
                onChanged: (v) => setState(() => _hallStars = v),
              ),
              if (lounge.devices.isNotEmpty)
                const Divider(color: ZonezColors.borderMuted, height: 24),
              ...lounge.devices.map(
                (device) => _PackageRatingRow(
                  label: device.nameAr,
                  icon: device.icon,
                  stars: _packageStars[device.id] ?? 0,
                  averageRating: device.averageRating,
                  ratingsCount: device.ratingsCount,
                  onChanged: (v) => setState(() => _packageStars[device.id] = v),
                ),
              ),
              const SizedBox(height: 12),
              provider.isSubmitting
                  ? const Center(
                      child: CircularProgressIndicator(color: ZonezColors.neonPurple),
                    )
                  : NeonGradientButton(
                      label: 'إرسال التقييم',
                      icon: Icons.send_rounded,
                      onPressed: _submit,
                    ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PackageRatingRow extends StatelessWidget {
  const _PackageRatingRow({
    required this.label,
    required this.stars,
    required this.onChanged,
    this.icon,
    this.averageRating = 0,
    this.ratingsCount = 0,
  });

  final String label;
  final IconData? icon;
  final int stars;
  final double averageRating;
  final int ratingsCount;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: ZonezColors.neonCyan, size: 20),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: ZonezTypography.title(size: 13)),
                if (averageRating > 0)
                  Row(
                    children: [
                      RatingStarsDisplay(rating: averageRating, size: 11, showValue: true),
                      if (ratingsCount > 0) ...[
                        const SizedBox(width: 4),
                        Text(
                          '($ratingsCount)',
                          style: ZonezTypography.caption(size: 10),
                        ),
                      ],
                    ],
                  ),
              ],
            ),
          ),
          StarRatingRow(
            rating: stars,
            onChanged: onChanged,
            starSize: 22,
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: ZonezColors.neonGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: ZonezTypography.title()),
              Text(subtitle, style: ZonezTypography.caption()),
            ],
          ),
        ),
      ],
    );
  }
}
