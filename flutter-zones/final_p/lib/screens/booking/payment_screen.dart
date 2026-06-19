import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import 'package:provider/provider.dart';

import '../../core/theme/zonez_colors.dart';

import '../../models/booking.dart';

import '../../models/zones_models.dart';

import '../../providers/app_state_provider.dart';

import '../../providers/zones_data_provider.dart';

import '../../utils/booking_time_utils.dart';

import '../../widgets/circuit_background.dart';

import '../../widgets/neon_gradient_button.dart';

import 'booking_success_screen.dart';



class PaymentScreen extends StatefulWidget {

  const PaymentScreen({

    super.key,

    required this.loungeName,

    required this.offer,

    required this.timeSlot,

    required this.finalPrice,

  });



  final String loungeName;

  final OfferModel offer;

  final TimeSlotModel timeSlot;

  final double finalPrice;



  @override

  State<PaymentScreen> createState() => _PaymentScreenState();

}



class _PaymentScreenState extends State<PaymentScreen> {

  bool _isConfirming = false;

  PaymentStatus _paymentStatus = PaymentStatus.paid;



  Future<void> _confirmBooking() async {

    setState(() => _isConfirming = true);



    final zonesData = context.read<ZonesDataProvider>();

    final appState = context.read<AppStateProvider>();



    try {

      final confirmation = await zonesData.confirmBooking(

        offerId: widget.offer.id,

        timeSlotId: widget.timeSlot.id,

        loungeName: widget.loungeName,

      );



      if (!mounted) return;



      final startDateTime =

          parseSlotStartDateTime(widget.timeSlot.timeRange) ??

              DateTime.now().add(const Duration(hours: 1));



      appState.addBooking(

        id: confirmation.bookingId,

        title: widget.offer.title,

        day: _formatDay(startDateTime),

        time: widget.timeSlot.timeRange,

        price: confirmation.finalPrice,

        loungeName: widget.loungeName,

        paymentStatus: _paymentStatus,

        startDateTime: startDateTime,

      );



      Navigator.pushReplacement(

        context,

        MaterialPageRoute(

          builder: (_) => BookingSuccessScreen(

            bookingId: confirmation.bookingId,

            loungeName: widget.loungeName,

            offer: widget.offer,

            timeSlot: widget.timeSlot,

            finalPrice: confirmation.finalPrice,

            paymentStatus: _paymentStatus,

          ),

        ),

      );

    } catch (e) {

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(

          content: Text(

            e.toString().replaceFirst('Exception: ', ''),

            style: GoogleFonts.cairo(),

            textAlign: TextAlign.center,

          ),

          backgroundColor: ZonezColors.neonRed,

        ),

      );

    } finally {

      if (mounted) setState(() => _isConfirming = false);

    }

  }



  String _formatDay(DateTime dt) {

    const days = [

      'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس',

      'الجمعة', 'السبت', 'الأحد',

    ];

    return days[dt.weekday - 1];

  }



  @override

  Widget build(BuildContext context) {

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final onSurface = Theme.of(context).colorScheme.onSurface;



    return Scaffold(

      appBar: AppBar(

        leading: IconButton(

          icon: const Icon(Icons.arrow_back),

          onPressed: () => Navigator.pop(context),

        ),

        title: Text(

          'الدفع',

          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),

        ),

      ),

      body: Stack(

        children: [

          const CircuitBackground(),

          Column(

            children: [

              Expanded(

                child: SingleChildScrollView(

                  padding: const EdgeInsets.all(20),

                  child: Column(

                    crossAxisAlignment: CrossAxisAlignment.stretch,

                    children: [

                      Text(

                        'ملخص الحجز',

                        style: GoogleFonts.cairo(

                          fontSize: 18,

                          fontWeight: FontWeight.bold,

                          color: isDark ? ZonezColors.neonCyan : ZonezColors.lightAccent,

                        ),

                      ),

                      const SizedBox(height: 16),

                      _SummaryCard(

                        rows: [

                          _SummaryRow(label: 'الصالة', value: widget.loungeName),

                          _SummaryRow(label: 'العرض', value: widget.offer.title),

                          _SummaryRow(

                            label: 'وقت الحجز',

                            value: widget.timeSlot.timeRange,

                          ),

                          _SummaryRow(

                            label: 'السعر النهائي',

                            value: '${widget.finalPrice.toStringAsFixed(0)} د.ل',

                            valueColor: isDark ? ZonezColors.neonCyan : ZonezColors.lightAccent,

                          ),

                        ],

                      ),

                      const SizedBox(height: 24),

                      Text(

                        'طريقة الدفع',

                        style: GoogleFonts.cairo(

                          fontSize: 16,

                          fontWeight: FontWeight.bold,

                          color: onSurface,

                        ),

                      ),

                      const SizedBox(height: 12),

                      _PaymentMethodTile(

                        title: 'دفع الآن',

                        subtitle: 'مدفوع — تأكيد فوري',

                        icon: Icons.payment,

                        selected: _paymentStatus == PaymentStatus.paid,

                        onTap: () =>

                            setState(() => _paymentStatus = PaymentStatus.paid),

                      ),

                      const SizedBox(height: 10),

                      _PaymentMethodTile(

                        title: 'دفع عند الوصول',

                        subtitle: 'غير مدفوع — ادفع في الصالة',

                        icon: Icons.store,

                        selected: _paymentStatus == PaymentStatus.payOnArrival,

                        onTap: () => setState(

                          () => _paymentStatus = PaymentStatus.payOnArrival,

                        ),

                      ),

                    ],

                  ),

                ),

              ),

              Container(

                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),

                decoration: BoxDecoration(

                  color: isDark ? ZonezColors.cardDark : ZonezColors.lightSurface,

                  border: Border(

                    top: BorderSide(

                      color: ZonezColors.neonPurple.withValues(alpha: 0.3),

                    ),

                  ),

                ),

                child: _isConfirming

                    ? const Center(

                        child: CircularProgressIndicator(

                          color: ZonezColors.neonPurple,

                        ),

                      )

                    : NeonGradientButton(

                        label: 'تأكيد الحجز',

                        onPressed: _confirmBooking,

                      ),

              ),

            ],

          ),

        ],

      ),

    );

  }

}



class _PaymentMethodTile extends StatelessWidget {

  const _PaymentMethodTile({

    required this.title,

    required this.subtitle,

    required this.icon,

    required this.selected,

    required this.onTap,

  });



  final String title;

  final String subtitle;

  final IconData icon;

  final bool selected;

  final VoidCallback onTap;



  @override

  Widget build(BuildContext context) {

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final onSurface = Theme.of(context).colorScheme.onSurface;



    return Material(

      color: isDark ? ZonezColors.cardDark : ZonezColors.lightSurface,

      borderRadius: BorderRadius.circular(14),

      child: InkWell(

        borderRadius: BorderRadius.circular(14),

        onTap: onTap,

        child: Container(

          padding: const EdgeInsets.all(14),

          decoration: BoxDecoration(

            borderRadius: BorderRadius.circular(14),

            border: Border.all(

              color: selected

                  ? ZonezColors.neonPurple

                  : ZonezColors.neonPurple.withValues(alpha: 0.2),

              width: selected ? 2 : 1,

            ),

          ),

          child: Row(

            children: [

              Icon(

                icon,

                color: selected

                    ? ZonezColors.neonPurple

                    : ZonezColors.textMuted,

              ),

              const SizedBox(width: 12),

              Expanded(

                child: Column(

                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    Text(

                      title,

                      style: GoogleFonts.cairo(

                        fontSize: 14,

                        fontWeight: FontWeight.bold,

                        color: onSurface,

                      ),

                    ),

                    Text(

                      subtitle,

                      style: GoogleFonts.cairo(

                        fontSize: 12,

                        color: ZonezColors.textMuted,

                      ),

                    ),

                  ],

                ),

              ),

              if (selected)

                const Icon(Icons.check_circle, color: ZonezColors.neonPurple),

            ],

          ),

        ),

      ),

    );

  }

}



class _SummaryCard extends StatelessWidget {

  const _SummaryCard({required this.rows});



  final List<_SummaryRow> rows;



  @override

  Widget build(BuildContext context) {

    final isDark = Theme.of(context).brightness == Brightness.dark;



    return Container(

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(

        color: isDark ? ZonezColors.cardDark : ZonezColors.lightSurface,

        borderRadius: BorderRadius.circular(16),

        border: Border.all(

          color: ZonezColors.neonPurple.withValues(alpha: 0.3),

        ),

        boxShadow: isDark

            ? null

            : [

                BoxShadow(

                  color: Colors.black.withValues(alpha: 0.05),

                  blurRadius: 10,

                  offset: const Offset(0, 4),

                ),

              ],

      ),

      child: Column(

        children: [

          for (var i = 0; i < rows.length; i++) ...[

            rows[i],

            if (i < rows.length - 1) const SizedBox(height: 14),

          ],

        ],

      ),

    );

  }

}



class _SummaryRow extends StatelessWidget {

  const _SummaryRow({

    required this.label,

    required this.value,

    this.valueColor,

  });



  final String label;

  final String value;

  final Color? valueColor;



  @override

  Widget build(BuildContext context) {

    final onSurface = Theme.of(context).colorScheme.onSurface;



    return Row(

      mainAxisAlignment: MainAxisAlignment.spaceBetween,

      children: [

        Text(

          label,

          style: GoogleFonts.cairo(

            fontSize: 14,

            color: ZonezColors.textMuted,

          ),

        ),

        Flexible(

          child: Text(

            value,

            textAlign: TextAlign.end,

            style: GoogleFonts.cairo(

              fontSize: 14,

              fontWeight: FontWeight.bold,

              color: valueColor ?? onSurface,

            ),

          ),

        ),

      ],

    );

  }

}

