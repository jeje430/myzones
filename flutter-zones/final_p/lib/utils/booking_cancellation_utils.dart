import '../models/booking.dart';

/// Returns true when cancellation is still allowed (strictly more than 30 minutes before start).
bool canCancelBooking(Booking booking) {
  if (!booking.isActive || booking.isCancelled) return false;

  final start = booking.startDateTime;
  if (start == null) return true;

  return start.difference(DateTime.now()) >= const Duration(minutes: 30);
}

String cancellationBlockedMessage() =>
    'لا يمكن الإلغاء خلال 30 دقيقة من موعد الحجز — ولا يُسترد المبلغ المدفوع';
