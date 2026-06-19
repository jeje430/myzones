import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/zonez_colors.dart';
import '../../core/theme/zonez_typography.dart';
import '../../models/booking.dart';
import '../../providers/lounge_ratings_provider.dart';
import '../../providers/tournament_provider.dart';
import '../../screens/tournaments/tournament_details_screen.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/neon_gradient_button.dart';
import 'tournament_receipt_sheet.dart';

/// Tournament participation row — used in «سجل البطولات» tabs.
class TournamentParticipationCard extends StatelessWidget {
  const TournamentParticipationCard({
    super.key,
    required this.booking,
    required this.isActive,
  });

  final Booking booking;
  final bool isActive;

  void _showReceipt(BuildContext context) {
    if (booking.tournamentId == null) return;

    final provider = context.read<TournamentProvider>();
    final registration = provider.activeRegistration(booking.tournamentId!) ??
        provider.registrationById(booking.id);

    if (registration == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('لا يوجد إيصال متاح', style: ZonezTypography.body()),
          backgroundColor: ZonezColors.neonRed,
        ),
      );
      return;
    }

    showTournamentReceiptSheet(
      context,
      registration: registration,
      gameName: booking.gameName ?? '',
      formattedDate: booking.day,
    );
  }

  void _openDetails(BuildContext context, {required bool showResults}) {
    if (booking.tournamentId == null || booking.loungeId == null) return;

    final lounge = context
        .read<LoungeRatingsProvider>()
        .loungeById(booking.loungeId!);
    if (lounge == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TournamentDetailsScreen(
          lounge: lounge,
          tournamentId: booking.tournamentId!,
          showResults: showResults,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return GlassContainer(
      padding: const EdgeInsets.all(16),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [
                ZonezColors.cardDark.withValues(alpha: 0.9),
                ZonezColors.inputBg.withValues(alpha: 0.8),
              ]
            : [
                ZonezColors.lightSurface.withValues(alpha: 0.95),
                ZonezColors.lightSurfaceAlt.withValues(alpha: 0.9),
              ],
      ),
      borderColor: ZonezColors.neonPurple.withValues(alpha: 0.25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: ZonezColors.neonGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.emoji_events,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.title,
                      style: ZonezTypography.title(size: 15, color: onSurface),
                    ),
                    if (booking.loungeName != null)
                      Text(
                        booking.loungeName!,
                        style: ZonezTypography.caption(size: 12),
                      ),
                    if (booking.gameName != null)
                      Text(
                        booking.gameName!,
                        style: ZonezTypography.accent(size: 12),
                      ),
                  ],
                ),
              ),
              Text(
                '${booking.price.toStringAsFixed(0)} د.ل',
                style: ZonezTypography.accent(
                  size: 15,
                  weight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _DetailRow(icon: Icons.calendar_today, text: booking.day),
          const SizedBox(height: 6),
          _DetailRow(icon: Icons.access_time, text: booking.time),
          if (booking.isCancelled) ...[
            const SizedBox(height: 10),
            Text(
              'ملغى',
              style: ZonezTypography.caption(
                size: 12,
                color: ZonezColors.neonRed,
                weight: FontWeight.bold,
              ),
            ),
          ],
          if (isActive && !booking.isCancelled) ...[
            const SizedBox(height: 14),
            NeonGradientButton(
              label: 'عرض التفاصيل',
              icon: Icons.account_tree_outlined,
              height: 44,
              onPressed: () => _openDetails(context, showResults: false),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => _showReceipt(context),
              icon: const Icon(Icons.receipt_long, size: 18),
              label: Text(
                'عرض الإيصال',
                style: ZonezTypography.body(size: 13),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: ZonezColors.neonCyan,
                side: const BorderSide(color: ZonezColors.neonCyan),
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
          if (!isActive && !booking.isCancelled) ...[
            const SizedBox(height: 14),
            NeonGradientButton(
              label: 'عرض النتائج',
              icon: Icons.leaderboard_outlined,
              height: 44,
              onPressed: () => _openDetails(context, showResults: true),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => _showReceipt(context),
              icon: const Icon(Icons.receipt_long, size: 18),
              label: Text(
                'عرض الإيصال',
                style: ZonezTypography.body(size: 13),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: ZonezColors.neonCyan,
                side: const BorderSide(color: ZonezColors.neonCyan),
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: ZonezColors.neonPurple),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: ZonezTypography.caption(size: 13)),
        ),
      ],
    );
  }
}
