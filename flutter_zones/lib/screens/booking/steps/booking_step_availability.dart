import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import 'package:provider/provider.dart';



import '../../../core/theme/zonez_colors.dart';

import '../../../providers/lounge_booking_provider.dart';

import '../../../widgets/booking/time_slot_card.dart';



class BookingStepAvailability extends StatelessWidget {

  const BookingStepAvailability({super.key});



  @override

  Widget build(BuildContext context) {

    final flow = context.watch<LoungeBookingProvider>();



    if (flow.isCheckingAvailability) {

      return const Center(

        child: Column(

          mainAxisAlignment: MainAxisAlignment.center,

          children: [

            CircularProgressIndicator(color: ZonezColors.neonPurple),

            SizedBox(height: 16),

            Text(

              'جاري التحقق من التوفر...',

              style: TextStyle(color: ZonezColors.textMuted),

            ),

          ],

        ),

      );

    }



    final result = flow.availabilityResult;



    if (result == null) {

      return Center(

        child: Text(

          'اضغط «التالي» للتحقق من التوفر',

          style: GoogleFonts.cairo(color: ZonezColors.textMuted),

        ),

      );

    }



    if (!result.isAvailable) {

      return _UnavailableState(

        message: result.message ?? 'نعتذر، لا يوجد جهاز متاح',

        onGoBack: flow.previousStep,

        onCancel: () => Navigator.pop(context),

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

                const Icon(Icons.check_circle, color: ZonezColors.neonCyan, size: 48),

                const SizedBox(height: 12),

                Text(

                  'يوجد مكان متاح!',

                  style: GoogleFonts.cairo(

                    fontSize: 20,

                    fontWeight: FontWeight.bold,

                    color: ZonezColors.neonCyan,

                  ),

                ),

              ],

            ),

          ),

          const SizedBox(height: 24),

          Text(

            'اختر ساعة واحدة',

            style: GoogleFonts.cairo(

              fontSize: 16,

              fontWeight: FontWeight.bold,

              color: Colors.white,

            ),

          ),

          const SizedBox(height: 12),

          ...result.slots.where((s) => s.isAvailable).map(

                (slot) => TimeSlotCard(

                  label: slot.label,

                  selected: flow.selectedSlot?.id == slot.id,

                  onTap: () => flow.selectSlot(slot),

                ),

              ),

          if (flow.selectedSlot != null) ...[

            const SizedBox(height: 24),

            _OrderSummary(flow: flow),

          ],

        ],

      ),

    );

  }

}



class _UnavailableState extends StatelessWidget {

  const _UnavailableState({

    required this.message,

    required this.onGoBack,

    required this.onCancel,

  });



  final String message;

  final VoidCallback onGoBack;

  final VoidCallback onCancel;



  @override

  Widget build(BuildContext context) {

    return Padding(

      padding: const EdgeInsets.all(24),

      child: Column(

        mainAxisAlignment: MainAxisAlignment.center,

        children: [

          const Icon(Icons.event_busy, color: ZonezColors.neonRed, size: 64),

          const SizedBox(height: 20),

          Text(

            message,

            textAlign: TextAlign.center,

            style: GoogleFonts.cairo(

              fontSize: 18,

              fontWeight: FontWeight.bold,

              color: Colors.white,

            ),

          ),

          const SizedBox(height: 32),

          SizedBox(

            width: double.infinity,

            child: OutlinedButton(

              onPressed: onGoBack,

              style: OutlinedButton.styleFrom(

                foregroundColor: ZonezColors.neonPurple,

                side: const BorderSide(color: ZonezColors.neonPurple),

                padding: const EdgeInsets.symmetric(vertical: 14),

              ),

              child: Text('رجوع', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),

            ),

          ),

          const SizedBox(height: 12),

          SizedBox(

            width: double.infinity,

            child: TextButton(

              onPressed: onCancel,

              child: Text(

                'إلغاء',

                style: GoogleFonts.cairo(color: ZonezColors.textMuted),

              ),

            ),

          ),

        ],

      ),

    );

  }

}



class _OrderSummary extends StatelessWidget {

  const _OrderSummary({required this.flow});



  final LoungeBookingProvider flow;



  @override

  Widget build(BuildContext context) {

    return Container(

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(

        color: ZonezColors.inputBg,

        borderRadius: BorderRadius.circular(16),

        border: Border.all(color: ZonezColors.neonCyan.withValues(alpha: 0.3)),

      ),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.stretch,

        children: [

          Text(

            'ملخص الطلب',

            style: GoogleFonts.cairo(

              fontSize: 15,

              fontWeight: FontWeight.bold,

              color: ZonezColors.neonCyan,

            ),

          ),

          const SizedBox(height: 12),

          _SummaryLine('الجهاز', flow.orderSummaryDevice),

          _SummaryLine('التاريخ', flow.formattedDate),

          _SummaryLine('الساعة', flow.formattedTime),

          _SummaryLine(

            'السعر',

            '${flow.totalPrice.toStringAsFixed(0)} د.ل',

            highlight: true,

          ),

          _SummaryLine(

            'نقاط الولاء',

            '+${(flow.totalPrice * 0.5).round()} نقطة',

            highlight: true,

          ),

        ],

      ),

    );

  }

}



class _SummaryLine extends StatelessWidget {

  const _SummaryLine(this.label, this.value, {this.highlight = false});



  final String label;

  final String value;

  final bool highlight;



  @override

  Widget build(BuildContext context) {

    return Padding(

      padding: const EdgeInsets.symmetric(vertical: 4),

      child: Row(

        mainAxisAlignment: MainAxisAlignment.spaceBetween,

        children: [

          Text(

            label,

            style: GoogleFonts.cairo(fontSize: 13, color: ZonezColors.textMuted),

          ),

          Text(

            value,

            style: GoogleFonts.cairo(

              fontSize: 13,

              fontWeight: FontWeight.bold,

              color: highlight ? ZonezColors.neonGold : Colors.white,

            ),

          ),

        ],

      ),

    );

  }

}


