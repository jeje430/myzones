import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/zonez_colors.dart';
import '../../models/zones_models.dart';
import '../../widgets/circuit_background.dart';
import '../../widgets/booking/booking_receipt_sheet.dart';
import '../../models/booking.dart';

/// Legacy success route — shows unified receipt sheet (no QR code).
class BookingSuccessScreen extends StatelessWidget {
  const BookingSuccessScreen({
    super.key,
    required this.bookingId,
    required this.loungeName,
    required this.offer,
    required this.timeSlot,
    required this.finalPrice,
    this.paymentStatus = PaymentStatus.paid,
    this.dateLabel,
    this.earnedPoints,
  });

  final String bookingId;
  final String loungeName;
  final OfferModel offer;
  final TimeSlotModel timeSlot;
  final double finalPrice;
  final PaymentStatus paymentStatus;
  final String? dateLabel;
  final int? earnedPoints;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!context.mounted) return;
      await showBookingReceiptSheet(
        context,
        data: BookingReceiptData(
          bookingId: bookingId,
          loungeName: loungeName,
          dateLabel: dateLabel ?? '—',
          timeLabel: timeSlot.timeRange,
          packageName: offer.title,
          finalPrice: finalPrice,
          earnedPoints: earnedPoints ?? (finalPrice * 0.5).round(),
          subtitle: offer.title,
        ),
        onClose: () {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.home,
            (route) => false,
          );
        },
      );
    });

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'تم الحجز بنجاح',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
      ),
      body: const Stack(
        children: [
          CircuitBackground(),
          Center(
            child: CircularProgressIndicator(color: ZonezColors.neonPurple),
          ),
        ],
      ),
    );
  }
}
