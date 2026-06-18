import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/zonez_colors.dart';
import '../../core/theme/zonez_typography.dart';
import '../../models/tournament.dart';
import '../glass_container.dart';
import '../neon_gradient_button.dart';

/// In-app tournament receipt — no file download required.
Future<void> showTournamentReceiptSheet(
  BuildContext context, {
  required TournamentRegistration registration,
  required String gameName,
  required String formattedDate,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _TournamentReceiptSheet(
      registration: registration,
      gameName: gameName,
      formattedDate: formattedDate,
    ),
  );
}

class _TournamentReceiptSheet extends StatelessWidget {
  const _TournamentReceiptSheet({
    required this.registration,
    required this.gameName,
    required this.formattedDate,
  });

  final TournamentRegistration registration;
  final String gameName;
  final String formattedDate;

  Future<void> _copyId(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: registration.id));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تم نسخ رقم التسجيل',
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
                        'إيصال الاشتراك',
                        style: ZonezTypography.title(size: 17, color: onSurface),
                      ),
                      Text(
                        registration.tournamentTitle,
                        style: ZonezTypography.caption(size: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _ReceiptRow('رقم التسجيل', registration.id, highlight: true),
            _ReceiptRow('اللاعب', registration.playerName),
            _ReceiptRow('اللعبة', gameName),
            _ReceiptRow('الصالة', registration.loungeName),
            _ReceiptRow('التاريخ', formattedDate),
            const SizedBox(height: 8),
            Text(
              'اعرض هذا الإيصال عند الوصول للصالة',
              textAlign: TextAlign.center,
              style: ZonezTypography.caption(size: 11),
            ),
            const SizedBox(height: 20),
            NeonGradientButton(
              label: 'نسخ رقم التسجيل',
              icon: Icons.copy_rounded,
              height: 48,
              onPressed: () => _copyId(context),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(context),
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
