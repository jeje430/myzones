import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../controllers/payment_controller.dart';
import '../../../core/theme/zonez_colors.dart';
import '../../../providers/app_state_provider.dart';
import '../../../providers/lounge_booking_provider.dart';
import '../../../widgets/booking/booking_checkout_summary.dart';
import '../../../models/booking.dart';

class BookingStepPayment extends StatelessWidget {
  const BookingStepPayment({super.key});

  @override
  Widget build(BuildContext context) {
    final flow = context.watch<LoungeBookingProvider>();
    final appState = context.watch<AppStateProvider>();
    final canPayWithPoints = PaymentController.canPayWithPoints(appState);
    final method = PaymentController.sanitizePaymentMethod(
      method: flow.paymentMethod,
      canPayWithPoints: canPayWithPoints,
    );
    if (method != flow.paymentMethod) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        flow.setPaymentMethod(method);
      });
    }
    final checkoutPrice = PaymentController.checkoutPrice(
      basePrice: flow.totalPrice,
      method: method,
    );
    final earnedPoints = PaymentController.checkoutEarnedPoints(
      basePrice: flow.totalPrice,
      method: method,
    );

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
            finalPrice: checkoutPrice,
            earnedPoints: earnedPoints,
            originalPrice:
                method == PaymentStatus.payWithPoints ? flow.totalPrice : null,
          ),
          const SizedBox(height: 24),
          BookingPaymentMethodPicker(
            selected: method,
            canPayWithPoints: canPayWithPoints,
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
