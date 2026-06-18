import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/zonez_colors.dart';
import '../../core/theme/zonez_typography.dart';
import '../glass_container.dart';
import '../neon_gradient_button.dart';

/// Unified booking receipt — lounge device bookings and promotional offers.
class BookingReceiptData {
  const BookingReceiptData({
    required this.bookingId,
    required this.loungeName,
    required this.dateLabel,
    required this.timeLabel,
    required this.packageName,
    required this.finalPrice,
    this.earnedPoints,
    this.subtitle,
  });

  final String bookingId;
  final String loungeName;
  final String dateLabel;
  final String timeLabel;
  final String packageName;
  final double finalPrice;
  final int? earnedPoints;
  final String? subtitle;
}

Future<void> showBookingReceiptSheet(
  BuildContext context, {
  required BookingReceiptData data,
  VoidCallback? onClose,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: false,
    enableDrag: false,
    builder: (ctx) => _BookingReceiptSheet(data: data, onClose: onClose),
  );
}

class _BookingReceiptSheet extends StatelessWidget {
  const _BookingReceiptSheet({
    required this.data,
    this.onClose,
  });

  final BookingReceiptData data;
  final VoidCallback? onClose;

  Future<void> _copyId(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: data.bookingId));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تم نسخ رقم الحجز',
          style: ZonezTypography.body(),
          textAlign: TextAlign.center,
        ),
        backgroundColor: ZonezColors.neonCyan,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final accent = Theme.of(context).brightness == Brightness.dark
        ? ZonezColors.neonCyan
        : ZonezColors.lightPrimary;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: GlassContainer(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? ZonezColors.textMuted
                      : ZonezColors.lightBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: Theme.of(context).brightness == Brightness.dark
                        ? ZonezColors.neonGradient
                        : ZonezColors.lightAccentGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.receipt_long,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'إيصال الحجز',
                        style: ZonezTypography.title(size: 17, color: onSurface),
                      ),
                      Text(
                        data.subtitle ?? data.packageName,
                        style: ZonezTypography.caption(size: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Center(
              child: Icon(
                Icons.check_circle_rounded,
                color: accent,
                size: 48,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'تم تأكيد حجزك بنجاح!',
              textAlign: TextAlign.center,
              style: ZonezTypography.title(size: 16, color: onSurface),
            ),
            const SizedBox(height: 16),
            _ReceiptRow('رقم الحجز', data.bookingId, highlight: true),
            _ReceiptRow('اسم الصالة', data.loungeName),
            _ReceiptRow('التاريخ', data.dateLabel),
            _ReceiptRow('الوقت', data.timeLabel),
            _ReceiptRow('الباقة / العرض', data.packageName),
            if (data.earnedPoints != null)
              _ReceiptRow('النقاط', '+${data.earnedPoints} نقطة'),
            _ReceiptRow(
              'السعر',
              '${data.finalPrice.toStringAsFixed(0)} د.ل',
              highlight: true,
            ),
            const SizedBox(height: 8),
            Text(
              'اعرض هذا الإيصال عند الوصول للصالة',
              textAlign: TextAlign.center,
              style: ZonezTypography.caption(size: 11),
            ),
            const SizedBox(height: 20),
            NeonGradientButton(
              label: 'نسخ رقم الحجز',
              icon: Icons.copy_rounded,
              height: 48,
              onPressed: () => _copyId(context),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                onClose?.call();
              },
              child: Text(
                'إغلاق',
                style: ZonezTypography.body(color: accent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow(this.label, this.value, {this.highlight = false});

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final accent = Theme.of(context).brightness == Brightness.dark
        ? ZonezColors.neonCyan
        : ZonezColors.lightPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: ZonezTypography.caption(size: 13)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: highlight
                  ? ZonezTypography.accent(
                      size: 14,
                      weight: FontWeight.bold,
                      color: accent,
                    )
                  : ZonezTypography.title(size: 14, color: onSurface),
            ),
          ),
        ],
      ),
    );
  }
}
