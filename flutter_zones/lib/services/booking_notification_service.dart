import 'dart:async';

import 'package:flutter/material.dart';

import '../models/booking.dart';
import '../models/notification_model.dart';
import '../providers/app_state_provider.dart';

/// Immediate confirmation + exact 2-hour-before reminders for lounge/offer bookings.
class BookingNotificationService {
  BookingNotificationService._();
  static final BookingNotificationService instance = BookingNotificationService._();

  final Map<String, Timer> _reminderTimers = {};

  void notifyBookingSuccess(
    AppStateProvider appState, {
    required Booking booking,
    bool isOffer = false,
  }) {
    final loungeLabel = booking.loungeName ?? 'الصالة';
    final confirmId = 'booking-success-${booking.id}';
    if (!appState.hasNotification(confirmId)) {
      appState.pushNotification(
        AppNotification(
          id: confirmId,
          title: 'تم الحجز بنجاح!',
          body: isOffer
              ? 'تم تأكيد حجز العرض «${booking.title}» في $loungeLabel.'
              : 'تم تأكيد حجزك في $loungeLabel — ${booking.time}',
          createdAt: DateTime.now(),
          icon: Icons.check_circle_rounded,
          color: const Color(0xFF06B6D4),
          bookingId: booking.id,
          type: NotificationType.general,
        ),
      );
    }
    _scheduleTwoHourReminder(appState, booking);
  }

  void _scheduleTwoHourReminder(AppStateProvider appState, Booking booking) {
    if (!appState.bookingRemindersEnabled) return;
    final start = booking.startDateTime;
    if (start == null) return;

    _reminderTimers.remove(booking.id)?.cancel();

    final reminderAt = start.subtract(const Duration(hours: 2));
    final delay = reminderAt.difference(DateTime.now());
    if (delay.isNegative) return;

    _reminderTimers[booking.id] = Timer(delay, () {
      final notifId = 'reminder-2h-${booking.id}';
      if (appState.hasNotification(notifId)) return;

      appState.pushNotification(
        AppNotification(
          id: notifId,
          title: 'تذكير الحجز',
          body:
              'تنبيه: متبقي ساعتان على موعد حجزك في ${booking.loungeName ?? "الصالة"} — ${booking.time}',
          createdAt: DateTime.now(),
          icon: Icons.notifications_active_outlined,
          color: const Color(0xFF06B6D4),
          bookingId: booking.id,
          type: NotificationType.bookingReminder,
        ),
      );
      _reminderTimers.remove(booking.id);
    });
  }

  void cancelReminder(String bookingId) {
    _reminderTimers.remove(bookingId)?.cancel();
  }

  /// Re-schedule 2h reminders after app restart for active future bookings.
  void restoreRemindersForBookings(AppStateProvider appState) {
    if (!appState.bookingRemindersEnabled) return;
    for (final booking in appState.currentBookings) {
      if (booking.isCancelled || booking.startDateTime == null) continue;
      if (booking.startDateTime!.isBefore(DateTime.now())) continue;
      _scheduleTwoHourReminder(appState, booking);
    }
  }

  void dispose() {
    for (final timer in _reminderTimers.values) {
      timer.cancel();
    }
    _reminderTimers.clear();
  }
}
