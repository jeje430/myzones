import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/zonez_colors.dart';
import '../../../providers/lounge_booking_provider.dart';
import '../../../widgets/booking/booking_checkout_summary.dart';

class BookingStepPayment extends StatelessWidget {
  const BookingStepPayment({super.key});

  @override
  Widget build(BuildContext context) {
    final flow = context.watch<LoungeBookingProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BookingCheckoutSummary(
            loungeName: flow.lounge!.name,
            packageName: flow.orderSummaryDevice,
            dateLabel: flow.formattedDate,
            timeLabel: flow.formattedTime,
            finalPrice: flow.totalPrice,
            earnedPoints: (flow.totalPrice * 0.5).round(),
          ),
          const SizedBox(height: 24),
          BookingPaymentMethodPicker(
            selected: flow.paymentMethod,
            onChanged: flow.setPaymentMethod,
          ),
          if (flow.errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              flow.errorMessage!,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(color: ZonezColors.neonRed),
            ),
          ],
        ],
      ),
    );
  }
}
