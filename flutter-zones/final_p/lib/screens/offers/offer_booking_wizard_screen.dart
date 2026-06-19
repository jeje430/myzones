import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import 'package:provider/provider.dart';



import '../../controllers/payment_controller.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/zonez_colors.dart';
import '../../core/theme/zonez_typography.dart';
import '../../models/booking.dart';
import '../../models/zones_models.dart';

import '../../providers/app_state_provider.dart';

import '../../providers/offer_booking_provider.dart';

import '../../services/booking_notification_service.dart';

import '../../utils/date_format_utils.dart';

import '../../widgets/booking/booking_checkout_summary.dart';

import '../../widgets/booking/booking_receipt_sheet.dart';

import '../../widgets/booking/time_slot_card.dart';

import '../../widgets/circuit_background.dart';

import '../../widgets/glass_container.dart';



class OfferBookingWizardScreen extends StatelessWidget {

  const OfferBookingWizardScreen({

    super.key,

    required this.offer,

    required this.loungeName,

    required this.finalPrice,

  });



  final OfferModel offer;

  final String loungeName;

  final double finalPrice;



  @override

  Widget build(BuildContext context) {

    return ChangeNotifierProvider(

      create: (_) => OfferBookingProvider(

        offer: offer,

        loungeName: loungeName,

        finalPrice: finalPrice,

      ),

      child: const _OfferBookingWizardBody(),

    );

  }

}



class _OfferBookingWizardBody extends StatelessWidget {

  const _OfferBookingWizardBody();



  @override

  Widget build(BuildContext context) {

    final flow = context.watch<OfferBookingProvider>();



    return Scaffold(

      extendBodyBehindAppBar: true,

      appBar: AppBar(

        leading: IconButton(

          icon: const Icon(Icons.arrow_back),

          onPressed: () => Navigator.pop(context),

        ),

        title: Column(

          children: [

            Text('احجز الآن', style: ZonezTypography.title(size: 16)),

            Text(

              flow.loungeName,

              style: ZonezTypography.caption(size: 11),

            ),

          ],

        ),

        backgroundColor: Colors.transparent,

      ),

      body: Stack(

        children: [

          const CircuitBackground(),

          Column(

            children: [

              SizedBox(

                height: MediaQuery.paddingOf(context).top + kToolbarHeight,

              ),

              _StepIndicator(currentStep: flow.currentStep),

              Expanded(

                child: AnimatedSwitcher(

                  duration: const Duration(milliseconds: 250),

                  child: _buildStep(flow),

                ),

              ),

              if (flow.currentStep != OfferBookingStep.confirmation)

                _BottomNavBar(flow: flow),

            ],

          ),

        ],

      ),

    );

  }



  Widget _buildStep(OfferBookingProvider flow) {

    switch (flow.currentStep) {

      case OfferBookingStep.dateSelection:

        return _DateStep(key: const ValueKey('date'), flow: flow);

      case OfferBookingStep.verification:

        return _VerificationStep(key: const ValueKey('verify'), flow: flow);

      case OfferBookingStep.payment:

        return _PaymentStep(key: const ValueKey('pay'), flow: flow);

      case OfferBookingStep.confirmation:

        return _ConfirmationStep(key: const ValueKey('confirm'), flow: flow);

    }

  }

}



class _StepIndicator extends StatelessWidget {

  const _StepIndicator({required this.currentStep});



  final OfferBookingStep currentStep;



  @override

  Widget build(BuildContext context) {

    final stepIndex = currentStep.index;

    final labels = OfferBookingProvider.stepLabels;

    final offset = OfferBookingProvider.stepDisplayOffset;



    return Padding(

      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),

      child: GlassContainer(

        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),

        child: Row(

          children: List.generate(labels.length, (i) {

            final isCompleted = i < stepIndex;

            final isActive = i == stepIndex;

            final isLast = i == labels.length - 1;



            return Expanded(

              child: Row(

                children: [

                  Expanded(

                    child: Column(

                      children: [

                        _StepCircle(

                          index: i + offset,

                          isCompleted: isCompleted,

                          isActive: isActive,

                        ),

                        const SizedBox(height: 6),

                        Text(

                          labels[i],

                          textAlign: TextAlign.center,

                          maxLines: 2,

                          overflow: TextOverflow.ellipsis,

                          style: ZonezTypography.caption(

                            size: 9,

                            weight: isActive || isCompleted

                                ? FontWeight.bold

                                : FontWeight.normal,

                            color: isActive || isCompleted

                                ? ZonezColors.neonCyan

                                : ZonezColors.textMuted,

                          ),

                        ),

                      ],

                    ),

                  ),

                  if (!isLast)

                    Expanded(

                      child: Padding(

                        padding: const EdgeInsets.only(bottom: 22),

                        child: Container(

                          height: 2,

                          margin: const EdgeInsets.symmetric(horizontal: 2),

                          decoration: BoxDecoration(

                            gradient:

                                isCompleted ? ZonezColors.neonGradient : null,

                            color: isCompleted

                                ? null

                                : ZonezColors.borderMuted,

                            borderRadius: BorderRadius.circular(1),

                          ),

                        ),

                      ),

                    ),

                ],

              ),

            );

          }),

        ),

      ),

    );

  }

}



class _StepCircle extends StatelessWidget {

  const _StepCircle({

    required this.index,

    required this.isCompleted,

    required this.isActive,

  });



  final int index;

  final bool isCompleted;

  final bool isActive;



  @override

  Widget build(BuildContext context) {

    final active = isActive || isCompleted;



    return AnimatedContainer(

      duration: const Duration(milliseconds: 250),

      width: 32,

      height: 32,

      decoration: BoxDecoration(

        shape: BoxShape.circle,

        gradient: active ? ZonezColors.neonGradient : null,

        color: active ? null : ZonezColors.inputBg,

        border: Border.all(

          color: active ? Colors.transparent : ZonezColors.borderMuted,

          width: 1.5,

        ),

        boxShadow: isActive

            ? [

                BoxShadow(

                  color: ZonezColors.neonPurple.withValues(alpha: 0.4),

                  blurRadius: 8,

                ),

              ]

            : null,

      ),

      child: Center(

        child: isCompleted

            ? const Icon(Icons.check, color: Colors.white, size: 16)

            : Text(

                '$index',

                style: ZonezTypography.caption(

                  size: 13,

                  weight: FontWeight.bold,

                  color: active ? Colors.white : ZonezColors.textMuted,

                ),

              ),

      ),

    );

  }

}



class _DateStep extends StatelessWidget {

  const _DateStep({super.key, required this.flow});



  final OfferBookingProvider flow;



  @override

  Widget build(BuildContext context) {

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final initial = flow.selectedDate ?? flow.offer.promoStart;

    final first = flow.offer.promoStart;

    final last = flow.offer.promoEnd;



    return SingleChildScrollView(

      padding: const EdgeInsets.all(20),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.stretch,

        children: [

          Text(

            'اختر تاريخ الحجز',

            style: GoogleFonts.cairo(

              fontSize: 18,

              fontWeight: FontWeight.bold,

              color: Theme.of(context).colorScheme.onSurface,

            ),

          ),

          const SizedBox(height: 8),

          Container(

            padding: const EdgeInsets.all(12),

            decoration: BoxDecoration(

              color: ZonezColors.neonGold.withValues(alpha: 0.1),

              borderRadius: BorderRadius.circular(12),

              border: Border.all(

                color: ZonezColors.neonGold.withValues(alpha: 0.35),

              ),

            ),

            child: Text(

              flow.offer.validityRangeLabel,

              textAlign: TextAlign.center,

              style: GoogleFonts.cairo(

                fontSize: 13,

                fontWeight: FontWeight.w600,

                color: ZonezColors.neonGold,

              ),

            ),

          ),

          const SizedBox(height: 20),

          Container(

            decoration: BoxDecoration(

              color: isDark ? ZonezColors.cardDark : Colors.white,

              borderRadius: BorderRadius.circular(16),

              border: Border.all(

                color: ZonezColors.neonPurple.withValues(alpha: 0.25),

              ),

            ),

            child: CalendarDatePicker(

              initialDate: initial.isBefore(first)

                  ? first

                  : (initial.isAfter(last) ? last : initial),

              firstDate: first,

              lastDate: last,

              currentDate: DateTime.now(),

              onDateChanged: flow.selectDate,

            ),

          ),

          if (flow.selectedDate != null) ...[

            const SizedBox(height: 12),

            Text(

              'التاريخ المختار: ${formatArabicDate(flow.selectedDate!)}',

              textAlign: TextAlign.center,

              style: GoogleFonts.cairo(

                fontWeight: FontWeight.bold,

                color: ZonezColors.neonCyan,

              ),

            ),

          ],

          if (flow.isCheckingAvailability) ...[

            const SizedBox(height: 24),

            const Center(

              child: CircularProgressIndicator(color: ZonezColors.neonPurple),

            ),

          ],

          if (flow.availabilityMessage != null && !flow.isAvailable) ...[

            const SizedBox(height: 16),

            Text(

              flow.availabilityMessage!,

              textAlign: TextAlign.center,

              style: GoogleFonts.cairo(color: ZonezColors.neonRed),

            ),

          ],

        ],

      ),

    );

  }

}



class _VerificationStep extends StatelessWidget {

  const _VerificationStep({super.key, required this.flow});



  final OfferBookingProvider flow;



  @override

  Widget build(BuildContext context) {

    final slots = flow.availableTimeSlots;



    return SingleChildScrollView(

      padding: const EdgeInsets.all(20),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.stretch,

        children: [

          Container(

            padding: const EdgeInsets.all(16),

            decoration: BoxDecoration(

              color: ZonezColors.neonCyan.withValues(alpha: 0.1),

              borderRadius: BorderRadius.circular(14),

              border: Border.all(

                color: ZonezColors.neonCyan.withValues(alpha: 0.35),

              ),

            ),

            child: Row(

              mainAxisAlignment: MainAxisAlignment.center,

              children: [

                const Icon(Icons.check_circle, color: ZonezColors.neonCyan),

                const SizedBox(width: 8),

                Text(

                  flow.availabilityMessage ?? 'يوجد مكان متاح!',

                  style: GoogleFonts.cairo(

                    fontWeight: FontWeight.bold,

                    color: ZonezColors.neonCyan,

                  ),

                ),

              ],

            ),

          ),

          const SizedBox(height: 20),

          Text(

            'اختر ساعة الحجز',

            style: GoogleFonts.cairo(

              fontSize: 16,

              fontWeight: FontWeight.bold,

              color: Theme.of(context).colorScheme.onSurface,

            ),

          ),

          const SizedBox(height: 12),

          if (slots.isEmpty)

            Center(

              child: Padding(

                padding: const EdgeInsets.all(24),

                child: Text(

                  'لا توجد أوقات متاحة',

                  style: GoogleFonts.cairo(color: ZonezColors.textMuted),

                ),

              ),

            )

          else

            GridView.builder(

              shrinkWrap: true,

              physics: const NeverScrollableScrollPhysics(),

              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(

                crossAxisCount: 2,

                mainAxisSpacing: 10,

                crossAxisSpacing: 10,

                childAspectRatio: 2.3,

              ),

              itemCount: slots.length,

              itemBuilder: (context, index) {

                final slot = slots[index];

                final selected = flow.selectedSlot?.id == slot.id;

                return TimeSlotCard(

                  label: slot.timeRange,

                  selected: selected,

                  onTap: () => flow.selectSlot(slot),

                  compact: true,

                );

              },

            ),

        ],

      ),

    );

  }

}



class _PaymentStep extends StatelessWidget {
  const _PaymentStep({super.key, required this.flow});

  final OfferBookingProvider flow;

  @override
  Widget build(BuildContext context) {
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

    final original = flow.offer.originalPrice;
    int? discount;
    if (original != null && original > 0 && original > flow.finalPrice) {
      discount = ((1 - flow.finalPrice / original) * 100).round();
    }

    final checkoutPrice = PaymentController.checkoutPrice(
      basePrice: flow.finalPrice,
      method: method,
    );
    final earnedPoints = PaymentController.checkoutEarnedPoints(
      basePrice: flow.finalPrice,
      method: method,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BookingCheckoutSummary(
            loungeName: flow.loungeName,
            packageName: flow.offer.title,
            dateLabel: flow.formattedDate,
            timeLabel: flow.formattedTime,
            finalPrice: checkoutPrice,
            earnedPoints: earnedPoints,
            originalPrice: method == PaymentStatus.payWithPoints
                ? flow.finalPrice
                : original,
            discountPercent: discount,
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



class _ConfirmationStep extends StatefulWidget {

  const _ConfirmationStep({super.key, required this.flow});



  final OfferBookingProvider flow;



  @override

  State<_ConfirmationStep> createState() => _ConfirmationStepState();

}



class _ConfirmationStepState extends State<_ConfirmationStep> {

  bool _saved = false;

  bool _receiptShown = false;



  @override

  void didChangeDependencies() {

    super.didChangeDependencies();

    if (!_saved) _persistAndNotify();

  }



  void _persistAndNotify() {

    final flow = widget.flow;

    final bookingId = flow.confirmedBookingId;

    if (bookingId == null) return;



    final appState = context.read<AppStateProvider>();

    final checkoutPrice = PaymentController.checkoutPrice(
      basePrice: flow.finalPrice,
      method: flow.paymentMethod,
    );
    final earnedPoints = PaymentController.checkoutEarnedPoints(
      basePrice: flow.finalPrice,
      method: flow.paymentMethod,
    );

    appState.addBooking(
      id: bookingId,
      title: flow.offer.title,
      day: flow.formattedDate,
      time: flow.formattedTime,
      price: checkoutPrice,
      loungeName: flow.loungeName,
      paymentStatus: flow.paymentMethod,
      startDateTime: flow.slotStartDateTime,
      earnedPoints: earnedPoints,
    );

    PaymentController.applySuccessfulCheckout(
      appState,
      method: flow.paymentMethod,
    );



    final booking = appState.getBookingById(bookingId);

    if (booking != null) {

      BookingNotificationService.instance.notifyBookingSuccess(

        appState,

        booking: booking,

        isOffer: true,

      );

    }



    setState(() => _saved = true);

    WidgetsBinding.instance.addPostFrameCallback((_) => _showReceipt());

  }



  Future<void> _showReceipt() async {

    if (_receiptShown || !mounted) return;

    _receiptShown = true;



    final flow = widget.flow;

    final bookingId = flow.confirmedBookingId;

    if (bookingId == null) return;



    await showBookingReceiptSheet(

      context,

      data: BookingReceiptData(

        bookingId: bookingId,

        loungeName: flow.loungeName,

        dateLabel: flow.formattedDate,

        timeLabel: flow.formattedTime,

        packageName: flow.offer.title,

        finalPrice: PaymentController.checkoutPrice(
          basePrice: flow.finalPrice,
          method: flow.paymentMethod,
        ),

        earnedPoints: PaymentController.checkoutEarnedPoints(
          basePrice: flow.finalPrice,
          method: flow.paymentMethod,
        ),

        subtitle: flow.offer.title,

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

    if (widget.flow.confirmedBookingId == null) {

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



class _BottomNavBar extends StatelessWidget {

  const _BottomNavBar({required this.flow});



  final OfferBookingProvider flow;



  bool _canProceed() {

    switch (flow.currentStep) {

      case OfferBookingStep.dateSelection:

        return flow.canProceedFromDate;

      case OfferBookingStep.verification:

        return flow.canProceedFromVerification;

      case OfferBookingStep.payment:

        return flow.canProceedFromPayment;

      case OfferBookingStep.confirmation:

        return false;

    }

  }



  Future<void> _onPrimary(BuildContext context) async {

    final isPayment = flow.currentStep == OfferBookingStep.payment;



    if (isPayment) {

      final ok = await flow.confirmAndAdvance();

      if (!context.mounted) return;

      if (!ok && flow.errorMessage != null) {

        ScaffoldMessenger.of(context).showSnackBar(

          SnackBar(

            content: Text(flow.errorMessage!, style: GoogleFonts.cairo()),

            backgroundColor: ZonezColors.neonRed,

          ),

        );

      }

      return;

    }



    await flow.nextStep();

  }



  @override

  Widget build(BuildContext context) {

    final isFirst = flow.currentStep == OfferBookingStep.dateSelection;

    final isPayment = flow.currentStep == OfferBookingStep.payment;

    final canProceed = _canProceed();

    final isBusy = flow.isConfirming || flow.isCheckingAvailability;



    return GlassContainer(

      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),

      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),

      child: Row(

        children: [

          if (!isFirst)

            Expanded(

              child: OutlinedButton.icon(

                onPressed: isBusy ? null : flow.previousStep,

                icon: const Icon(Icons.arrow_back, size: 18),

                label: Text('السابق', style: ZonezTypography.body(size: 13)),

                style: OutlinedButton.styleFrom(

                  foregroundColor: ZonezColors.neonPurple,

                  side: const BorderSide(color: ZonezColors.neonPurple),

                  padding: const EdgeInsets.symmetric(vertical: 14),

                  shape: RoundedRectangleBorder(

                    borderRadius: BorderRadius.circular(16),

                  ),

                ),

              ),

            ),

          if (!isFirst) const SizedBox(width: 12),

          Expanded(

            flex: 2,

            child: DecoratedBox(

              decoration: BoxDecoration(

                gradient: canProceed && !isBusy ? ZonezColors.neonGradient : null,

                color: canProceed && !isBusy ? null : ZonezColors.borderMuted,

                borderRadius: BorderRadius.circular(16),

              ),

              child: ElevatedButton(

                onPressed: canProceed && !isBusy ? () => _onPrimary(context) : null,

                style: ElevatedButton.styleFrom(

                  backgroundColor: Colors.transparent,

                  shadowColor: Colors.transparent,

                  disabledBackgroundColor: Colors.transparent,

                  padding: const EdgeInsets.symmetric(vertical: 14),

                  shape: RoundedRectangleBorder(

                    borderRadius: BorderRadius.circular(16),

                  ),

                ),

                child: isBusy

                    ? const SizedBox(

                        width: 22,

                        height: 22,

                        child: CircularProgressIndicator(

                          strokeWidth: 2,

                          color: Colors.white,

                        ),

                      )

                    : Row(

                        mainAxisAlignment: MainAxisAlignment.center,

                        children: [

                          Text(

                            isPayment ? 'تأكيد الحجز' : 'التالي',

                            style: ZonezTypography.title(

                              size: 14,

                              color: Colors.white,

                            ),

                          ),

                          if (!isPayment) ...[

                            const SizedBox(width: 4),

                            const Icon(

                              Icons.arrow_forward,

                              color: Colors.white,

                              size: 18,

                            ),

                          ],

                        ],

                      ),

              ),

            ),

          ),

        ],

      ),

    );

  }

}


