import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/zonez_colors.dart';
import '../../../core/theme/zonez_typography.dart';
import '../../../models/booking.dart';
import '../../../providers/app_state_provider.dart';
import '../../../providers/lounge_ratings_provider.dart';
import '../../../providers/tournament_provider.dart';
import '../../../services/booking_notification_service.dart';
import '../../../utils/booking_cancellation_utils.dart';
import '../../../widgets/booking/booking_receipt_sheet.dart';
import '../../../widgets/glass_container.dart';
import '../../../widgets/neon_gradient_button.dart';
import '../../../widgets/tournament/tournament_receipt_sheet.dart';
import '../../tournaments/tournament_details_screen.dart';

class BookingsTab extends StatefulWidget {
  const BookingsTab({super.key});

  @override
  State<BookingsTab> createState() => _BookingsTabState();
}

class _BookingsTabState extends State<BookingsTab>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  Timer? _cancelPolicyTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cancelPolicyTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) {
        if (mounted) setState(() {});
      },
    );
  }

  @override
  void dispose() {
    _cancelPolicyTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? ZonezColors.neonCyan : ZonezColors.lightAccent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Text(
            'حجوزاتي',
            style: ZonezTypography.display(size: 22, color: onSurface),
          ),
        ),
        const SizedBox(height: 12),
        TabBar(
          controller: _tabController,
          labelStyle: ZonezTypography.caption(size: 13, weight: FontWeight.bold),
          unselectedLabelStyle: ZonezTypography.caption(size: 13),
          labelColor: accent,
          unselectedLabelColor: ZonezColors.textMuted,
          indicatorColor:
              isDark ? ZonezColors.neonPurple : ZonezColors.lightPrimary,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'الحجوزات الحالية'),
            Tab(text: 'الحجوزات السابقة'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _BookingList(
                bookings: appState.currentBookings,
                emptyMessage: 'لا توجد حجوزات حالية',
                isActive: true,
              ),
              _BookingList(
                bookings: appState.pastBookings,
                emptyMessage: 'لا توجد حجوزات سابقة',
                isActive: false,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BookingList extends StatelessWidget {
  const _BookingList({
    required this.bookings,
    required this.emptyMessage,
    required this.isActive,
  });

  final List<Booking> bookings;
  final String emptyMessage;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: ZonezTypography.body(size: 15, color: ZonezColors.textMuted),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _BookingCard(
        booking: bookings[i],
        isActive: isActive,
      ),
    );
  }
}

class _BookingCard extends StatefulWidget {
  const _BookingCard({
    required this.booking,
    required this.isActive,
  });

  final Booking booking;
  final bool isActive;

  @override
  State<_BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends State<_BookingCard> {
  Future<void> _confirmCancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('إلغاء الحجز', style: ZonezTypography.title()),
        content: Text(
          'هل أنت متأكد من إلغاء هذا الحجز؟',
          style: ZonezTypography.body(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('لا', style: ZonezTypography.body()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'نعم، إلغاء',
              style: ZonezTypography.body(color: ZonezColors.neonRed),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      context.read<AppStateProvider>().cancelBooking(widget.booking.id);
      BookingNotificationService.instance
          .cancelReminder(widget.booking.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم إلغاء الحجز',
            style: ZonezTypography.body(),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
  }

  void _showLoungeReceipt() {
    final b = widget.booking;
    showBookingReceiptSheet(
      context,
      data: BookingReceiptData(
        bookingId: b.id,
        loungeName: b.loungeName ?? b.title,
        dateLabel: b.day,
        timeLabel: b.time,
        packageName: b.deviceName ?? b.title,
        finalPrice: b.price,
        earnedPoints: b.earnedPoints,
      ),
    );
  }

  void _showTournamentReceipt() {
    final booking = widget.booking;
    if (booking.tournamentId == null) return;

    final provider = context.read<TournamentProvider>();
    final registration = provider.activeRegistration(booking.tournamentId!);
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

  void _openTournamentDetails({required bool showResults}) {
    final booking = widget.booking;
    final lounge = context
        .read<LoungeRatingsProvider>()
        .loungeById(booking.loungeId ?? '');
    if (lounge == null || booking.tournamentId == null) return;

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
    final booking = widget.booking;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isTournament = booking.isTournament;
    final canCancel =
        widget.isActive && !isTournament && canCancelBooking(booking);
    final showCancelBlocked = widget.isActive &&
        !isTournament &&
        !canCancelBooking(booking) &&
        !booking.isCancelled;

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
                child: Icon(
                  isTournament ? Icons.emoji_events : Icons.sports_esports,
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
                      isTournament
                          ? booking.title
                          : (booking.loungeName ?? booking.title),
                      style: ZonezTypography.title(size: 15, color: onSurface),
                    ),
                    if (isTournament && booking.loungeName != null)
                      Text(
                        booking.loungeName!,
                        style: ZonezTypography.caption(size: 12),
                      )
                    else if (booking.deviceName != null)
                      Text(
                        booking.deviceName!,
                        style: ZonezTypography.accent(size: 12),
                      ),
                    if (isTournament && booking.gameName != null)
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
          if (!isTournament) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: booking.paymentStatus == PaymentStatus.paid ||
                        booking.paymentStatus == PaymentStatus.electronic
                    ? ZonezColors.neonCyan.withValues(alpha: 0.15)
                    : ZonezColors.neonGold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                booking.paymentStatusLabel,
                style: ZonezTypography.caption(
                  size: 11,
                  weight: FontWeight.w600,
                  color: booking.paymentStatus == PaymentStatus.paid ||
                          booking.paymentStatus == PaymentStatus.electronic
                      ? ZonezColors.neonCyan
                      : ZonezColors.neonGold,
                ),
              ),
            ),
          ],
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
          if (widget.isActive && !booking.isCancelled) ...[
            const SizedBox(height: 14),
            if (isTournament) ...[
              NeonGradientButton(
                label: 'عرض التفاصيل',
                icon: Icons.account_tree_outlined,
                height: 44,
                onPressed: () => _openTournamentDetails(showResults: false),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _showTournamentReceipt,
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
            ] else ...[
              OutlinedButton.icon(
                onPressed: () => _showLoungeReceipt(),
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
              const SizedBox(height: 10),
              if (canCancel) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _confirmCancel,
                    icon: const Icon(
                      Icons.cancel_outlined,
                      size: 18,
                      color: ZonezColors.neonRed,
                    ),
                    label: Text(
                      'إلغاء الحجز',
                      style: ZonezTypography.title(
                        size: 14,
                        color: ZonezColors.neonRed,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ZonezColors.neonRed,
                      side: const BorderSide(color: ZonezColors.neonRed),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
              if (showCancelBlocked) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: ZonezColors.neonRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: ZonezColors.neonRed.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    cancellationBlockedMessage(),
                    textAlign: TextAlign.center,
                    style: ZonezTypography.caption(
                      size: 11,
                      color: ZonezColors.neonRed,
                    ),
                  ),
                ),
              ],
            ],
          ],
          if (!widget.isActive && isTournament && !booking.isCancelled) ...[
            const SizedBox(height: 14),
            NeonGradientButton(
              label: 'عرض النتائج',
              icon: Icons.leaderboard_outlined,
              height: 44,
              onPressed: () => _openTournamentDetails(showResults: true),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _showTournamentReceipt,
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
