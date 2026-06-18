import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/theme/zonez_colors.dart';
import '../../providers/app_state_provider.dart';
import '../../screens/booking/booking_detail_screen.dart';
import '../../widgets/circuit_background.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final notifications = appState.notifications;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'الإشعارات',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          const CircuitBackground(),
          notifications.isEmpty
              ? Center(
                  child: Text(
                    'لا توجد إشعارات',
                    style: GoogleFonts.cairo(color: ZonezColors.textMuted),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: notifications.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final item = notifications[i];
                    return GestureDetector(
                      onTap: () {
                        appState.markNotificationRead(item.id);
                        if (item.bookingId != null) {
                          final booking =
                              appState.getBookingById(item.bookingId!);
                          if (booking != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    BookingDetailScreen(booking: booking),
                              ),
                            );
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? ZonezColors.cardDark
                              : ZonezColors.lightSurface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: item.isUnread
                                ? ZonezColors.neonPurple.withValues(alpha: 0.4)
                                : ZonezColors.borderMuted.withValues(alpha: 0.3),
                          ),
                          boxShadow: isDark
                              ? null
                              : [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 8,
                                  ),
                                ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: item.color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(item.icon, color: item.color, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.title,
                                          style: GoogleFonts.cairo(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface,
                                          ),
                                        ),
                                      ),
                                      if (item.isUnread)
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: ZonezColors.neonCyan,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.body,
                                    style: GoogleFonts.cairo(
                                      fontSize: 12,
                                      color: ZonezColors.textMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    item.timeAgo,
                                    style: GoogleFonts.cairo(
                                      fontSize: 11,
                                      color: ZonezColors.neonPurple,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}
