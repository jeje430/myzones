import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/zonez_colors.dart';
import '../../core/theme/zonez_typography.dart';
import '../../models/booking.dart';
import '../glass_container.dart';

/// Shared checkout summary — offer bookings and lounge device bookings.
class BookingCheckoutSummary extends StatelessWidget {
  const BookingCheckoutSummary({
    super.key,
    required this.loungeName,
    required this.packageName,
    required this.dateLabel,
    required this.timeLabel,
    required this.finalPrice,
    this.earnedPoints,
    this.originalPrice,
    this.discountPercent,
    this.isPaymentStep = true,
  });

  final String loungeName;
  final String packageName;
  final String dateLabel;
  final String timeLabel;
  final double finalPrice;
  final int? earnedPoints;
  final double? originalPrice;
  final int? discountPercent;
  final bool isPaymentStep;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? ZonezColors.neonCyan : ZonezColors.lightPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isPaymentStep) ...[
          Text(
            'الدفع والتأكيد',
            style: GoogleFonts.cairo(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'راجع تفاصيل حجزك قبل التأكيد',
            style: GoogleFonts.cairo(fontSize: 13, color: ZonezColors.textMuted),
          ),
          const SizedBox(height: 16),
        ] else
          Text(
            'ملخص الحجز',
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: onSurface,
            ),
          ),
        if (!isPaymentStep) const SizedBox(height: 14),
        GlassContainer(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
                decoration: BoxDecoration(
                  gradient: isDark
                      ? ZonezColors.neonGradient
                      : ZonezColors.lightAccentGradient,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.sports_esports, color: Colors.white, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        packageName,
                        style: ZonezTypography.title(size: 15, color: Colors.white),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (discountPercent != null && discountPercent! > 0)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white54),
                        ),
                        child: Text(
                          '-$discountPercent%',
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
                child: Column(
                  children: [
                    _SummaryRow('اسم الصالة', loungeName),
                    _SummaryRow('التاريخ', dateLabel),
                    _SummaryRow('الوقت', timeLabel),
                    if (earnedPoints != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: ZonezColors.neonGold.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: ZonezColors.neonGold.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: ZonezColors.neonGold.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.stars_rounded,
                                color: ZonezColors.neonGold,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'نقاط الولاء',
                                    style: GoogleFonts.cairo(
                                      fontSize: 12,
                                      color: ZonezColors.textMuted,
                                    ),
                                  ),
                                  Text(
                                    '+$earnedPoints نقطة',
                                    style: GoogleFonts.cairo(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: ZonezColors.neonGold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    if (originalPrice != null && originalPrice! > finalPrice) ...[
                      _SummaryRow(
                        'السعر الأصلي',
                        '${originalPrice!.toStringAsFixed(0)} د.ل',
                        muted: true,
                        strike: true,
                      ),
                      const SizedBox(height: 4),
                    ],
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            accent.withValues(alpha: 0.15),
                            ZonezColors.neonPurple.withValues(alpha: 0.12),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'السعر الإجمالي',
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: onSurface,
                            ),
                          ),
                          Text(
                            '${finalPrice.toStringAsFixed(0)} د.ل',
                            style: GoogleFonts.cairo(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class BookingPaymentMethodPicker extends StatelessWidget {
  const BookingPaymentMethodPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final PaymentStatus selected;
  final ValueChanged<PaymentStatus> onChanged;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'طريقة الدفع',
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: onSurface,
          ),
        ),
        const SizedBox(height: 12),
        _MethodTile(
          title: 'دفع الآن',
          subtitle: 'مدفوع — تأكيد فوري',
          icon: Icons.payment_rounded,
          selected: selected == PaymentStatus.paid,
          onTap: () => onChanged(PaymentStatus.paid),
        ),
        const SizedBox(height: 10),
        _MethodTile(
          title: 'دفع عند الوصول',
          subtitle: 'غير مدفوع — ادفع في الصالة',
          icon: Icons.storefront_outlined,
          selected: selected == PaymentStatus.payOnArrival,
          onTap: () => onChanged(PaymentStatus.payOnArrival),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(
    this.label,
    this.value, {
    this.muted = false,
    this.strike = false,
  });

  final String label;
  final String value;
  final bool muted;
  final bool strike;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 13,
              color: ZonezColors.textMuted,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: muted
                    ? ZonezColors.textMuted
                    : Theme.of(context).colorScheme.onSurface,
                decoration: strike ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  const _MethodTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? ZonezColors.cardDark : ZonezColors.lightSurface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? ZonezColors.neonPurple
                  : ZonezColors.neonPurple.withValues(alpha: 0.25),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: selected ? ZonezColors.neonPurple : ZonezColors.textMuted,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        color: ZonezColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle, color: ZonezColors.neonPurple),
            ],
          ),
        ),
      ),
    );
  }
}
