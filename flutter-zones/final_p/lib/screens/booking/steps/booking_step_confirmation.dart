import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import 'package:provider/provider.dart';



import '../../../controllers/payment_controller.dart';

import '../../../core/routes/app_routes.dart';

import '../../../core/theme/zonez_colors.dart';

import '../../../core/theme/zonez_typography.dart';

import '../../../models/booking.dart';

import '../../../providers/app_state_provider.dart';

import '../../../providers/lounge_booking_provider.dart';

import '../../../services/booking_notification_service.dart';

import '../../../services/booking_receipt_service.dart';

import '../../../widgets/glass_container.dart';

import '../../../widgets/neon_gradient_button.dart';



class BookingStepConfirmation extends StatefulWidget {

  const BookingStepConfirmation({super.key});



  @override

  State<BookingStepConfirmation> createState() => _BookingStepConfirmationState();

}



class _BookingStepConfirmationState extends State<BookingStepConfirmation> {

  bool _savedToAppState = false;

  bool _isDownloading = false;



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

      deviceName: flow.assignedDeviceLabel,

      deviceType: flow.selectedDevice!.type,

      paymentStatus: flow.paymentMethod,

      startDateTime: flow.selectedSlot!.startDateTime,

      earnedPoints: confirmation.earnedPoints,

      serverId: confirmation.numericId,

      receiptPdfUrl: confirmation.receiptPdfUrl,

    );



    PaymentController.applySuccessfulCheckout(

      appState,

      method: flow.paymentMethod,

    );



    appState.syncBookingsFromApi();



    final booking = appState.getBookingById(confirmation.bookingId);

    if (booking != null) {

      BookingNotificationService.instance.notifyBookingSuccess(

        appState,

        booking: booking,

      );

    }



    setState(() => _savedToAppState = true);

  }



  Future<void> _openReceiptViewer(int? bookingId, String bookingNumber) async {

    if (bookingId == null) return;

    BookingReceiptService.instance.openReceiptViewer(

      context,

      bookingId: bookingId,

      bookingNumber: bookingNumber,

    );

  }



  Future<void> _downloadReceipt(int? bookingId) async {

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



  void _finish(BuildContext context) {

    Navigator.pushNamedAndRemoveUntil(

      context,

      AppRoutes.home,

      (route) => false,

    );

  }



  @override

  Widget build(BuildContext context) {

    final flow = context.watch<LoungeBookingProvider>();

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

              border: Border.all(color: ZonezColors.neonCyan.withValues(alpha: 0.4)),

            ),

            child: Column(

              children: [

                const Icon(Icons.check_circle, color: ZonezColors.neonCyan, size: 56),

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

                const SizedBox(height: 6),

                Text(

                  'يمكنك عرض الحجز من «حجوزاتي»',

                  style: GoogleFonts.cairo(color: ZonezColors.textMuted, fontSize: 13),

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

                  'إيصال الحجز',

                  style: ZonezTypography.title(size: 16),

                  textAlign: TextAlign.center,

                ),

                const SizedBox(height: 16),

                _ReceiptRow('رقم الحجز', confirmation.bookingNumber),

                _ReceiptRow('الصالة', flow.lounge!.name),

                _ReceiptRow('الباقة', flow.selectedDevice!.nameAr),

                _ReceiptRow('الجهاز', flow.assignedDeviceLabel),

                _ReceiptRow('التاريخ', flow.formattedDate),

                _ReceiptRow('الوقت', flow.formattedTime),

                _ReceiptRow('طريقة الدفع', _paymentLabel(flow.paymentMethod)),

                _ReceiptRow(

                  'الإجمالي',

                  '${confirmation.finalPrice.toStringAsFixed(0)} د.ل',

                  highlight: true,

                ),

                if (confirmation.earnedPoints > 0)

                  _ReceiptRow(

                    'نقاط الولاء',

                    '+${confirmation.earnedPoints}',

                    highlight: true,

                  ),

              ],

            ),

          ),

          const SizedBox(height: 20),

          NeonGradientButton(

            label: 'عرض الإيصال',

            icon: Icons.visibility_outlined,

            onPressed: confirmation.numericId == null

                ? null

                : () => _openReceiptViewer(

                      confirmation.numericId,

                      confirmation.bookingNumber,

                    ),

          ),

          const SizedBox(height: 12),

          OutlinedButton.icon(

            onPressed: _isDownloading || confirmation.numericId == null

                ? null

                : () => _downloadReceipt(confirmation.numericId),

            icon: _isDownloading

                ? const SizedBox(

                    width: 18,

                    height: 18,

                    child: CircularProgressIndicator(strokeWidth: 2),

                  )

                : const Icon(Icons.download_outlined, size: 18),

            label: Text(

              'تحميل PDF',

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

            onPressed: () => _finish(context),

          ),

        ],

      ),

    );

  }

}



class _ReceiptRow extends StatelessWidget {

  const _ReceiptRow(this.label, this.value, {this.highlight = false});



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

            style: GoogleFonts.cairo(fontSize: 13, color: ZonezColors.textMuted),

          ),

          Flexible(

            child: Text(

              value,

              textAlign: TextAlign.end,

              style: GoogleFonts.cairo(

                fontSize: 13,

                fontWeight: FontWeight.bold,

                color: highlight ? ZonezColors.neonGold : Colors.white,

              ),

            ),

          ),

        ],

      ),

    );

  }

}

