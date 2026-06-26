import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import 'package:provider/provider.dart';



import '../../../core/theme/zonez_colors.dart';

import '../../../core/theme/zonez_typography.dart';

import '../../../providers/app_state_provider.dart';
import '../../../providers/lounge_booking_provider.dart';

import '../../../screens/payment/plutu_payment_webview_screen.dart';

import '../../../services/plutu_payment_service.dart';

import '../../../widgets/booking/booking_checkout_summary.dart';

import '../../../models/booking.dart';



class BookingStepPayment extends StatefulWidget {

  const BookingStepPayment({super.key});



  @override

  State<BookingStepPayment> createState() => _BookingStepPaymentState();

}



class _BookingStepPaymentState extends State<BookingStepPayment> {

  bool _isProcessing = false;



  Future<void> _handlePayOnline(LoungeBookingProvider flow) async {

    flow.setPaymentMethod(PaymentStatus.electronic);

    setState(() => _isProcessing = true);

    flow.errorMessage = null;



    try {

      final pending = await flow.createBookingOnServer(paymentMethod: 'online');

      if (pending == null || pending.numericId == null) {

        throw Exception('تعذر إنشاء الحجز');

      }



      if (!mounted) return;



      final session = await PlutuPaymentService.instance.createPayment(

        amount: pending.finalPrice,

        bookingId: pending.numericId,

      );



      if (!mounted) return;



      final outcome = await Navigator.push<PlutuPaymentWebViewResult>(

        context,

        MaterialPageRoute(

          builder: (_) => PlutuPaymentWebViewScreen(

            paymentUrl: session.paymentUrl,

            expectedInvoiceNo: session.invoiceNo,

          ),

        ),

      );



      if (!mounted) return;



      if (outcome?.outcome == PlutuPaymentOutcome.success) {

        final callbackParams = Map<String, String>.from(outcome!.callbackParams);

        callbackParams.putIfAbsent('approved', () => '1');



        final ok = await flow.refreshConfirmationAfterPayment(

          pending.numericId!,

          invoiceNo: outcome.invoiceNo ?? session.invoiceNo,

          callbackParams: callbackParams,

        );



        if (!ok && mounted && flow.errorMessage != null) {

          _showMessage(flow.errorMessage!, ZonezColors.neonRed);

        }

      } else if (outcome?.outcome == PlutuPaymentOutcome.canceled) {

        _showMessage('تم إلغاء الدفع', ZonezColors.neonGold);

      }

    } catch (e) {

      if (mounted) {

        final message = e.toString().replaceFirst('ApiException: ', '');

        _showMessage(message, ZonezColors.neonRed);

      }

    } finally {

      if (mounted) setState(() => _isProcessing = false);

    }

  }



  Future<void> _handlePayOnArrival(LoungeBookingProvider flow) async {

    flow.setPaymentMethod(PaymentStatus.payOnArrival);

    setState(() => _isProcessing = true);

    final ok = await flow.confirmBooking(paymentMethod: 'cash');

    if (!mounted) return;

    setState(() => _isProcessing = false);

    if (!ok && flow.errorMessage != null) {

      _showMessage(flow.errorMessage!, ZonezColors.neonRed);

    }

  }

  Future<void> _handleLoyaltyReward(LoungeBookingProvider flow) async {
    flow.setPaymentMethod(PaymentStatus.payWithPoints);
    setState(() => _isProcessing = true);

    final ok = await flow.confirmBooking(paymentMethod: 'loyalty_reward');

    if (!mounted) return;

    setState(() => _isProcessing = false);

    if (ok) {
      await context.read<AppStateProvider>().syncLoyaltyFromApi();
    } else if (flow.errorMessage != null) {
      _showMessage(flow.errorMessage!, ZonezColors.neonRed);
    }
  }



  void _showMessage(String text, Color color) {

    final bottomInset = MediaQuery.paddingOf(context).bottom;

    ScaffoldMessenger.of(context).showSnackBar(

      SnackBar(

        content: Text(text, style: GoogleFonts.cairo()),

        backgroundColor: color,

        behavior: SnackBarBehavior.floating,

        margin: EdgeInsets.fromLTRB(16, 0, 16, bottomInset + 16),

      ),

    );

  }



  @override

  Widget build(BuildContext context) {

    final flow = context.watch<LoungeBookingProvider>();
    final appState = context.watch<AppStateProvider>();

    final checkoutPrice = flow.totalPrice;

    final earnedPoints = appState.loyaltyStatus?.pointsPerCompletedSession ?? 0;

    final isBusy = _isProcessing || flow.isConfirming;



    return SafeArea(

      top: false,

      child: SingleChildScrollView(

        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),

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

            ),

            const SizedBox(height: 28),

            Text(

              'اختر طريقة الدفع',

              style: GoogleFonts.cairo(

                fontSize: 16,

                fontWeight: FontWeight.bold,

                color: Theme.of(context).colorScheme.onSurface,

              ),

            ),

            const SizedBox(height: 16),

            if (isBusy)

              const Center(

                child: Padding(

                  padding: EdgeInsets.symmetric(vertical: 32),

                  child: Column(

                    children: [

                      CircularProgressIndicator(color: ZonezColors.neonPurple),

                      SizedBox(height: 12),

                      Text(

                        'جاري تأكيد الدفع وإنشاء الحجز...',

                        textAlign: TextAlign.center,

                        style: TextStyle(color: ZonezColors.textMuted),

                      ),

                    ],

                  ),

                ),

              )

            else ...[

              _PaymentActionCard(

                icon: Icons.credit_card_rounded,

                title: 'الدفع الإلكتروني',

                subtitle: 'ادفع الآن ببطاقتك البنكية عبر Plutu',

                accent: ZonezColors.neonPurple,

                onTap: () => _handlePayOnline(flow),

              ),

              const SizedBox(height: 12),

              _PaymentActionCard(

                icon: Icons.storefront_outlined,

                title: 'دفع عند الوصول',

                subtitle: 'ادفع نقداً عند الحضور للصالة',

                accent: ZonezColors.neonCyan,

                onTap: () => _handlePayOnArrival(flow),

              ),

              if (appState.canPayWithPoints) ...[
                const SizedBox(height: 12),
                _PaymentActionCard(
                  icon: Icons.card_giftcard_rounded,
                  title: 'مكافأة ولاء',
                  subtitle: 'حجز مجاني باستخدام نقاط الولاء',
                  accent: ZonezColors.neonGold,
                  onTap: () => _handleLoyaltyReward(flow),
                ),
              ],

            ],

            if (flow.errorMessage != null && !isBusy) ...[

              const SizedBox(height: 12),

              Text(

                flow.errorMessage!,

                textAlign: TextAlign.center,

                style: GoogleFonts.cairo(color: ZonezColors.neonRed),

              ),

            ],

            const SizedBox(height: 16),

            if (!isBusy)

              OutlinedButton.icon(

                onPressed: flow.previousStep,

                icon: const Icon(Icons.arrow_back, size: 18),

                label: Text('رجوع', style: GoogleFonts.cairo()),

                style: OutlinedButton.styleFrom(

                  foregroundColor: ZonezColors.textMuted,

                  side: const BorderSide(color: ZonezColors.borderMuted),

                  padding: const EdgeInsets.symmetric(vertical: 14),

                  shape: RoundedRectangleBorder(

                    borderRadius: BorderRadius.circular(14),

                  ),

                ),

              ),

          ],

        ),

      ),

    );

  }

}



class _PaymentActionCard extends StatelessWidget {

  const _PaymentActionCard({

    required this.icon,

    required this.title,

    required this.subtitle,

    required this.accent,

    required this.onTap,

  });



  final IconData icon;

  final String title;

  final String subtitle;

  final Color accent;

  final VoidCallback onTap;



  @override

  Widget build(BuildContext context) {

    final isDark = Theme.of(context).brightness == Brightness.dark;



    return Material(

      color: isDark ? ZonezColors.cardDark : ZonezColors.lightSurface,

      borderRadius: BorderRadius.circular(14),

      child: InkWell(

        borderRadius: BorderRadius.circular(14),

        onTap: onTap,

        child: Container(

          padding: const EdgeInsets.all(16),

          decoration: BoxDecoration(

            borderRadius: BorderRadius.circular(14),

            border: Border.all(color: accent.withValues(alpha: 0.5), width: 1.5),

          ),

          child: Row(

            children: [

              Container(

                width: 48,

                height: 48,

                decoration: BoxDecoration(

                  shape: BoxShape.circle,

                  color: accent.withValues(alpha: 0.12),

                  border: Border.all(color: accent.withValues(alpha: 0.35)),

                ),

                child: Icon(icon, color: accent, size: 24),

              ),

              const SizedBox(width: 14),

              Expanded(

                child: Column(

                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    Text(

                      title,

                      style: ZonezTypography.title(size: 14, color: accent),

                    ),

                    Text(

                      subtitle,

                      style: ZonezTypography.caption(size: 11),

                    ),

                  ],

                ),

              ),

              Icon(Icons.arrow_forward_ios, size: 14, color: accent.withValues(alpha: 0.6)),

            ],

          ),

        ),

      ),

    );

  }

}

