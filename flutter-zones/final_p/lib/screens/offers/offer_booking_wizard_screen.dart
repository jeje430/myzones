import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import 'package:provider/provider.dart';



import '../../controllers/payment_controller.dart';
import '../../core/theme/zonez_colors.dart';
import '../../core/theme/zonez_typography.dart';
import '../../models/booking.dart';
import '../../models/zones_models.dart';

import '../../providers/app_state_provider.dart';

import '../../providers/offer_booking_provider.dart';

import '../../services/booking_notification_service.dart';

import '../../screens/payment/plutu_payment_webview_screen.dart';

import '../../services/plutu_payment_service.dart';

import '../../utils/date_format_utils.dart';

import '../../widgets/booking/booking_checkout_summary.dart';

import '../../services/booking_receipt_service.dart';

import '../../widgets/neon_gradient_button.dart';

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

        elevation: 0,

        scrolledUnderElevation: 0,

      ),

      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            const CircuitBackground(),
            Column(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _StepIndicator(currentStep: flow.currentStep),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: _buildStep(flow),
                        ),
                      ),
                    ],
                  ),
                ),
                if (flow.currentStep != OfferBookingStep.confirmation)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _BottomNavBar(flow: flow),
                  ),
              ],
            ),
          ],
        ),
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

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final first = flow.offer.promoStart.isAfter(todayDate)
        ? flow.offer.promoStart
        : todayDate;
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

              initialDate: flow.selectedDate ?? first,

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

                  'لا توجد حجوزات متاحة',

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

                  label: slot.label,

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
    final method = flow.paymentMethod;

    final original = flow.originalTotalPrice;
    final discount = flow.discountPercent;

    final checkoutPrice = PaymentController.checkoutPrice(
      basePrice: flow.checkoutBasePrice,
      method: method,
    );
    final earnedPoints = PaymentController.checkoutEarnedPoints(
      basePrice: flow.checkoutBasePrice,
      method: method,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BookingCheckoutSummary(
            loungeName: flow.loungeName,
            packageName: flow.offer.packageName.isNotEmpty
                ? flow.offer.packageName
                : flow.offer.title,
            dateLabel: flow.formattedDate,
            timeLabel: flow.formattedTime,
            finalPrice: checkoutPrice,
            earnedPoints: earnedPoints,
            originalPrice: original,
            discountPercent: discount,
            deviceName: flow.selectedDeviceName,
          ),
          const SizedBox(height: 24),
          BookingPaymentMethodPicker(
            selected: method,
            canPayWithPoints: false,
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

  bool _isDownloading = false;

  bool _notified = false;



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

    appState.syncBookingsFromApi();

    PaymentController.applySuccessfulCheckout(
      appState,
      method: flow.paymentMethod,
    );

    setState(() => _saved = true);
  }

  Future<void> _handleDone() async {
    final flow = widget.flow;
    final appState = context.read<AppStateProvider>();

    await appState.syncBookingsFromApi();

    if (!_notified && flow.confirmedBookingId != null) {
      final booking = appState.getBookingById(flow.confirmedBookingId!);
      if (booking != null) {
        BookingNotificationService.instance.notifyBookingSuccess(
          appState,
          booking: booking,
          isOffer: true,
        );
        _notified = true;
      }
    }

    if (!mounted) return;
    Navigator.of(context).pop();
  }



  String _paymentLabel(PaymentStatus method) {

    switch (method) {

      case PaymentStatus.electronic:

        return 'الدفع الإلكتروني';

      case PaymentStatus.payOnArrival:

        return 'دفع عند الوصول';

      default:

        return 'مدفوع';

    }

  }



  Future<void> _openReceiptViewer() async {

    final confirmation = widget.flow.confirmation;

    if (confirmation?.numericId == null) return;

    BookingReceiptService.instance.openReceiptViewer(

      context,

      bookingId: confirmation!.numericId!,

      bookingNumber: confirmation.bookingNumber,

    );

  }



  Future<void> _downloadReceiptPdf() async {

    final bookingId = widget.flow.confirmation?.numericId;

    if (bookingId == null) return;

    setState(() => _isDownloading = true);

    try {

      await BookingReceiptService.instance.openReceipt(bookingId);

    } catch (e) {

      if (mounted) {

        ScaffoldMessenger.of(context).showSnackBar(

          SnackBar(

            content: Text(

              e.toString().replaceFirst('Exception: ', ''),

              style: GoogleFonts.cairo(),

            ),

            backgroundColor: ZonezColors.neonRed,

          ),

        );

      }

    } finally {

      if (mounted) setState(() => _isDownloading = false);

    }

  }



  @override

  Widget build(BuildContext context) {

    final flow = widget.flow;

    final confirmation = flow.confirmation;



    if (confirmation == null) {

      return Center(

        child: Column(

          mainAxisAlignment: MainAxisAlignment.center,

          children: [

            const CircularProgressIndicator(color: ZonezColors.neonPurple),

            const SizedBox(height: 16),

            Text(

              'جاري تحميل الإيصال...',

              style: ZonezTypography.body(color: ZonezColors.textMuted),

            ),

          ],

        ),

      );

    }



    final checkoutPrice = PaymentController.checkoutPrice(

      basePrice: flow.checkoutBasePrice,

      method: flow.paymentMethod,

    );

    final packageLabel = flow.offer.packageName.isNotEmpty

        ? flow.offer.packageName

        : flow.offer.title;



    return SingleChildScrollView(

      padding: const EdgeInsets.all(20),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.stretch,

        children: [

          Container(

            padding: const EdgeInsets.all(20),

            decoration: BoxDecoration(

              color: ZonezColors.neonCyan.withValues(alpha: 0.1),

              borderRadius: BorderRadius.circular(16),

              border: Border.all(

                color: ZonezColors.neonCyan.withValues(alpha: 0.4),

              ),

            ),

            child: Column(

              children: [

                const Icon(

                  Icons.check_circle,

                  color: ZonezColors.neonCyan,

                  size: 56,

                ),

                const SizedBox(height: 12),

                Text(

                  'تم إكمال الحجز بنجاح',

                  style: GoogleFonts.cairo(

                    fontSize: 22,

                    fontWeight: FontWeight.bold,

                    color: ZonezColors.neonCyan,

                  ),

                  textAlign: TextAlign.center,

                ),

                const SizedBox(height: 6),

                Text(

                  'Reservation completed successfully',

                  style: GoogleFonts.cairo(

                    color: ZonezColors.textMuted,

                    fontSize: 13,

                  ),

                  textAlign: TextAlign.center,

                ),

              ],

            ),

          ),

          const SizedBox(height: 20),

          GlassContainer(

            padding: const EdgeInsets.all(18),

            child: Column(

              crossAxisAlignment: CrossAxisAlignment.stretch,

              children: [

                Text(

                  'إيصال حجز',

                  style: ZonezTypography.title(size: 16),

                  textAlign: TextAlign.center,

                ),

                const SizedBox(height: 16),

                _OfferReceiptRow('رقم الحجز', confirmation.bookingNumber),

                _OfferReceiptRow('الصالة', flow.loungeName),

                _OfferReceiptRow('الباقة', packageLabel),

                if (flow.selectedDeviceName != null)

                  _OfferReceiptRow('الجهاز', flow.selectedDeviceName!),

                _OfferReceiptRow('التاريخ', flow.formattedDate),

                _OfferReceiptRow('الوقت', flow.formattedTime),

                _OfferReceiptRow(

                  'طريقة الدفع',

                  _paymentLabel(flow.paymentMethod),

                ),

                if (flow.discountPercent != null && flow.discountPercent! > 0)

                  _OfferReceiptRow(

                    'الخصم',

                    '${flow.discountPercent}%',

                  ),

                _OfferReceiptRow(

                  'الإجمالي',

                  '${checkoutPrice.toStringAsFixed(0)} د.ل',

                  highlight: true,

                ),

              ],

            ),

          ),

          const SizedBox(height: 20),

          NeonGradientButton(

            label: 'عرض',

            icon: Icons.visibility_outlined,

            onPressed: confirmation.numericId == null ? null : _openReceiptViewer,

          ),

          const SizedBox(height: 12),

          OutlinedButton.icon(

            onPressed: _isDownloading || confirmation.numericId == null

                ? null

                : _downloadReceiptPdf,

            icon: _isDownloading

                ? const SizedBox(

                    width: 18,

                    height: 18,

                    child: CircularProgressIndicator(strokeWidth: 2),

                  )

                : const Icon(Icons.download_outlined, size: 18),

            label: Text(

              'تنزيل PDF',

              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),

            ),

            style: OutlinedButton.styleFrom(

              foregroundColor: ZonezColors.neonPurple,

              side: const BorderSide(color: ZonezColors.neonPurple),

              padding: const EdgeInsets.symmetric(vertical: 14),

              shape: RoundedRectangleBorder(

                borderRadius: BorderRadius.circular(14),

              ),

            ),

          ),

          const SizedBox(height: 16),

          NeonGradientButton(
            label: 'تم',
            icon: Icons.check_rounded,
            onPressed: _handleDone,
          ),

        ],

      ),

    );

  }

}



class _OfferReceiptRow extends StatelessWidget {

  const _OfferReceiptRow(this.label, this.value, {this.highlight = false});



  final String label;

  final String value;

  final bool highlight;



  @override

  Widget build(BuildContext context) {

    return Padding(

      padding: const EdgeInsets.symmetric(vertical: 6),

      child: Row(

        mainAxisAlignment: MainAxisAlignment.spaceBetween,

        children: [

          Text(

            label,

            style: GoogleFonts.cairo(

              fontSize: 13,

              color: ZonezColors.textMuted,

            ),

          ),

          Flexible(

            child: Text(

              value,

              textAlign: TextAlign.end,

              style: GoogleFonts.cairo(

                fontSize: 13,

                fontWeight: FontWeight.bold,

                color: highlight ? ZonezColors.neonGold : null,

              ),

            ),

          ),

        ],

      ),

    );

  }

}



class _BottomNavBar extends StatefulWidget {

  const _BottomNavBar({required this.flow});



  final OfferBookingProvider flow;

  @override
  State<_BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<_BottomNavBar> {
  bool _isProcessingPayment = false;

  OfferBookingProvider get flow => widget.flow;



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
      if (flow.paymentMethod == PaymentStatus.electronic) {
        await _handlePayOnline(context);
        return;
      }

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

  Future<void> _handlePayOnline(BuildContext context) async {
    flow.setPaymentMethod(PaymentStatus.electronic);
    setState(() => _isProcessingPayment = true);
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
        final ok = await flow.refreshConfirmationAfterPayment(
          pending.numericId!,
          invoiceNo: session.invoiceNo,
          callbackParams: outcome?.callbackParams,
        );
        if (!ok && flow.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(flow.errorMessage!, style: GoogleFonts.cairo()),
              backgroundColor: ZonezColors.neonRed,
            ),
          );
        }
      } else if (outcome?.outcome == PlutuPaymentOutcome.canceled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم إلغاء الدفع', style: GoogleFonts.cairo()),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceFirst('Exception: ', ''),
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: ZonezColors.neonRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessingPayment = false);
    }
  }



  @override

  Widget build(BuildContext context) {

    final isFirst = flow.currentStep == OfferBookingStep.dateSelection;

    final isPayment = flow.currentStep == OfferBookingStep.payment;

    final canProceed = _canProceed();

    final isBusy = flow.isConfirming ||
        flow.isCheckingAvailability ||
        _isProcessingPayment;



    return GlassContainer(

      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),

      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),

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


