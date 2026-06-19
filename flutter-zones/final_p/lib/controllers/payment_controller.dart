import '../models/booking.dart';
import '../providers/app_state_provider.dart';

/// Checkout payment rules — points redemption, pricing, post-booking resets.
class PaymentController {
  PaymentController._();

  static bool canPayWithPoints(AppStateProvider appState) =>
      appState.canPayWithPoints;

  static double checkoutPrice({
    required double basePrice,
    required PaymentStatus method,
  }) {
    if (method == PaymentStatus.payWithPoints) return 0;
    return basePrice;
  }

  static int checkoutEarnedPoints({
    required double basePrice,
    required PaymentStatus method,
  }) {
    if (method == PaymentStatus.payWithPoints) return 0;
    return (basePrice * 0.5).round();
  }

  static void applySuccessfulCheckout(
    AppStateProvider appState, {
    required PaymentStatus method,
  }) {
    if (method == PaymentStatus.payWithPoints) {
      appState.resetLoyaltyPointsAfterRedemption();
    }
  }

  static PaymentStatus sanitizePaymentMethod({
    required PaymentStatus method,
    required bool canPayWithPoints,
  }) {
    if (method == PaymentStatus.payWithPoints && !canPayWithPoints) {
      return PaymentStatus.payOnArrival;
    }
    return method;
  }
}
