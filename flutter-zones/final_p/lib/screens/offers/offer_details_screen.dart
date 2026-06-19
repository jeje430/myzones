import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/zonez_colors.dart';
import '../../models/zones_models.dart';
import '../../widgets/circuit_background.dart';
import '../../widgets/neon_gradient_button.dart';
import 'offer_booking_wizard_screen.dart';

/// Offer landing page — details first; wizard starts only via «احجز الآن».
class OfferDetailsScreen extends StatefulWidget {
  const OfferDetailsScreen({
    super.key,
    required this.offer,
    required this.loungeName,
    required this.finalPrice,
  });

  final OfferModel offer;
  final String loungeName;
  final double finalPrice;

  @override
  State<OfferDetailsScreen> createState() => _OfferDetailsScreenState();
}

class _OfferDetailsScreenState extends State<OfferDetailsScreen> {
  Timer? _expiryTimer;
  String _countdownText = '';
  bool _termsExpanded = false;

  @override
  void initState() {
    super.initState();
    _updateCountdown();
    _expiryTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateCountdown();
    });
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    super.dispose();
  }

  void _updateCountdown() {
    if (!mounted) return;
    final label = widget.offer.countdownLabel;
    setState(() => _countdownText = label);
    if (widget.offer.isExpired) {
      Navigator.pop(context);
    }
  }

  void _startBooking() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OfferBookingWizardScreen(
          offer: widget.offer,
          loungeName: widget.loungeName,
          finalPrice: widget.finalPrice,
        ),
      ),
    );
  }

  int? get _discountPercent {
    final original = widget.offer.originalPrice;
    if (original == null || original <= 0) return null;
    return ((1 - widget.finalPrice / original) * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? ZonezColors.neonCyan : ZonezColors.lightAccent;
    final original = widget.offer.originalPrice;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'تفاصيل العرض',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          const CircuitBackground(),
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: AspectRatio(
                              aspectRatio: 16 / 9,
                              child: Image.network(
                                widget.offer.offerImage,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  color: ZonezColors.inputBg,
                                  child: Icon(
                                    Icons.local_offer,
                                    size: 56,
                                    color: accent.withValues(alpha: 0.4),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (_discountPercent != null)
                            Positioned(
                              top: 12,
                              left: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  gradient: ZonezColors.neonGradient,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: ZonezColors.neonPurple
                                          .withValues(alpha: 0.5),
                                      blurRadius: 12,
                                    ),
                                  ],
                                ),
                                child: Text(
                                  'خصم $_discountPercent%',
                                  style: GoogleFonts.cairo(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        widget.offer.title,
                        style: GoogleFonts.cairo(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.loungeName,
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          color: ZonezColors.textMuted,
                        ),
                      ),
                      if (_countdownText.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: ZonezColors.neonGold.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: ZonezColors.neonGold.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Text(
                            _countdownText,
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: ZonezColors.neonGold,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Text(
                        widget.offer.description,
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          color: ZonezColors.textMuted,
                          height: 1.55,
                        ),
                      ),
                      if (original != null) ...[
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? ZonezColors.cardDark
                                : ZonezColors.lightSurface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: ZonezColors.neonPurple.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'السعر الأصلي: ${original.toStringAsFixed(0)} د.ل',
                                style: GoogleFonts.cairo(
                                  fontSize: 14,
                                  color: ZonezColors.textMuted,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'سعر العرض: ${widget.finalPrice.toStringAsFixed(0)} د.ل',
                                style: GoogleFonts.cairo(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: accent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: ZonezColors.neonGold.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: ZonezColors.neonGold.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          widget.offer.validityRangeLabel,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: ZonezColors.neonGold,
                          ),
                        ),
                      ),
                      if (widget.offer.terms.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Material(
                          color: isDark
                              ? ZonezColors.cardDark
                              : ZonezColors.lightSurface,
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () =>
                                setState(() => _termsExpanded = !_termsExpanded),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: ZonezColors.neonPurple
                                      .withValues(alpha: 0.2),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'شروط العرض',
                                          style: GoogleFonts.cairo(
                                            fontWeight: FontWeight.bold,
                                            color: onSurface,
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        _termsExpanded
                                            ? Icons.keyboard_arrow_up
                                            : Icons.keyboard_arrow_down,
                                        color: ZonezColors.textMuted,
                                      ),
                                    ],
                                  ),
                                  if (_termsExpanded) ...[
                                    const SizedBox(height: 10),
                                    ...widget.offer.terms.map(
                                      (t) => Padding(
                                        padding: const EdgeInsets.only(bottom: 6),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text('• ',
                                                style: GoogleFonts.cairo(
                                                    color: ZonezColors.textMuted)),
                                            Expanded(
                                              child: Text(
                                                t,
                                                style: GoogleFonts.cairo(
                                                  fontSize: 12,
                                                  color: ZonezColors.textMuted,
                                                  height: 1.4,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                decoration: BoxDecoration(
                  color: isDark ? ZonezColors.cardDark : ZonezColors.lightSurface,
                  border: Border(
                    top: BorderSide(
                      color: ZonezColors.neonPurple.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                child: NeonGradientButton(
                  label: 'احجز الآن',
                  icon: Icons.event_available_rounded,
                  onPressed: _startBooking,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
