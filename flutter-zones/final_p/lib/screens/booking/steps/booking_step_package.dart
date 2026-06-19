import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/zonez_colors.dart';
import '../../../core/theme/zonez_typography.dart';
import '../../../models/lounge_model.dart';
import '../../../providers/lounge_booking_provider.dart';
import '../../../widgets/rating/device_rating_badges.dart';

class BookingStepPackage extends StatelessWidget {
  const BookingStepPackage({super.key, required this.lounge});

  final LoungeModel lounge;

  @override
  Widget build(BuildContext context) {
    final flow = context.watch<LoungeBookingProvider>();

    final bookable = lounge.availableDevices;

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
          const SizedBox(height: 20),
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
                childAspectRatio: 0.88,
              ),
              itemCount: bookable.length,
              itemBuilder: (context, index) {
                final device = bookable[index];
                final selected = flow.selectedDevice?.type == device.type;

                return _DeviceCard(
                  device: device,
                  selected: selected,
                  onTap: () => flow.selectDevice(device),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({
    required this.device,
    required this.selected,
    required this.onTap,
  });

  final DevicePackage device;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? ZonezColors.neonPurple.withValues(alpha: 0.15) : ZonezColors.cardDark,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
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
              Icon(device.icon, color: ZonezColors.neonCyan, size: 32),
              const Spacer(),
              Text(
                device.nameAr,
                style: ZonezTypography.title(size: 13),
              ),
              if (device.specs != null) ...[
                const SizedBox(height: 2),
                Text(
                  device.specs!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: ZonezTypography.caption(size: 10),
                ),
              ],
              const SizedBox(height: 4),
              Text(
                '${device.hourlyRate.toStringAsFixed(0)} د.ل/ساعة',
                style: ZonezTypography.accent(size: 12),
              ),
              const SizedBox(height: 6),
              DeviceRatingBadge(rating: device.averageRating, compact: true),
            ],
          ),
        ),
      ),
    );
  }
}
