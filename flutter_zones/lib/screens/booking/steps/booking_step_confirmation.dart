import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/zonez_colors.dart';
import '../../../core/theme/zonez_typography.dart';
import '../../../providers/app_state_provider.dart';
import '../../../providers/lounge_booking_provider.dart';
import '../../../services/booking_notification_service.dart';
import '../../../widgets/booking/booking_receipt_sheet.dart';

class BookingStepConfirmation extends StatefulWidget {
  const BookingStepConfirmation({super.key});

  @override
  State<BookingStepConfirmation> createState() => _BookingStepConfirmationState();
}

class _BookingStepConfirmationState extends State<BookingStepConfirmation> {
  bool _savedToAppState = false;
  bool _receiptShown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_savedToAppState) {
      _persistBooking();
    }
  }

  void _persistBooking() {
    final flow = context.read<LoungeBookingProvider>();
    final confirmation = flow.confirmation;
    if (confirmation == null ||
        flow.lounge == null ||
        flow.selectedSlot == null) {
      return;
    }

    final appState = context.read<AppStateProvider>();
    appState.addBooking(
      id: confirmation.bookingId,
      title: flow.selectedDevice!.nameAr,
      day: flow.formattedDate,
      time: flow.formattedTime,
      price: confirmation.finalPrice,
      loungeName: flow.lounge!.name,
      deviceName: flow.selectedDevice!.nameAr,
      deviceType: flow.selectedDevice!.type,
      paymentStatus: flow.paymentMethod,
      startDateTime: flow.selectedSlot!.startDateTime,
      earnedPoints: confirmation.earnedPoints,
    );

    final booking = appState.getBookingById(confirmation.bookingId);
    if (booking != null) {
      BookingNotificationService.instance.notifyBookingSuccess(
        appState,
        booking: booking,
      );
    }

    setState(() => _savedToAppState = true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _showReceipt());
  }

  Future<void> _showReceipt() async {
    if (_receiptShown || !mounted) return;
    _receiptShown = true;

    final flow = context.read<LoungeBookingProvider>();
    final confirmation = flow.confirmation;
    if (confirmation == null) return;

    await showBookingReceiptSheet(
      context,
      data: BookingReceiptData(
        bookingId: confirmation.bookingId,
        loungeName: flow.lounge!.name,
        dateLabel: flow.formattedDate,
        timeLabel: flow.formattedTime,
        packageName: flow.selectedDevice!.nameAr,
        finalPrice: confirmation.finalPrice,
        earnedPoints: confirmation.earnedPoints,
        subtitle: flow.lounge!.name,
      ),
      onClose: () {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.home,
          (route) => false,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final confirmation = context.watch<LoungeBookingProvider>().confirmation;

    if (confirmation == null) {
      return Center(
        child: Text(
          'جاري تحميل الإيصال...',
          style: ZonezTypography.body(color: ZonezColors.textMuted),
        ),
      );
    }

    return const Center(
      child: CircularProgressIndicator(color: ZonezColors.neonPurple),
    );
  }
}
