import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/theme/zonez_colors.dart';
import '../models/notification_model.dart';
import '../providers/app_state_provider.dart';
import '../screens/booking/booking_detail_screen.dart';
import '../screens/home/home_screen.dart';

/// In-app push notification box (FR-45).
class NotificationBanner extends StatelessWidget {
  const NotificationBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final notification =
        context.watch<AppStateProvider>().latestBannerNotification;
    if (notification == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Material(
        elevation: isDark ? 0 : 4,
        shadowColor: ZonezColors.lightPrimary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(14),
        color: isDark ? ZonezColors.cardDark : ZonezColors.lightSurface,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            final appState = context.read<AppStateProvider>();
            appState.markNotificationRead(notification.id);
            appState.dismissBannerNotification();

            if (notification.type == NotificationType.offerBooking) {
              appState.setBottomNavIndex(HomeNavIndex.bookings);
              return;
            }

            if (notification.bookingId != null) {
              final booking = appState.getBookingById(notification.bookingId!);
              if (booking != null && context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BookingDetailScreen(booking: booking),
                  ),
                );
              }
            }
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: notification.color.withValues(alpha: 0.5),
              ),
              boxShadow: isDark
                  ? [
                      BoxShadow(
                        color: notification.color.withValues(alpha: 0.15),
                        blurRadius: 12,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: notification.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(notification.icon, color: notification.color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        notification.body,
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: ZonezColors.textMuted,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  color: ZonezColors.textMuted,
                  onPressed: () {
                    context.read<AppStateProvider>().dismissBannerNotification();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
