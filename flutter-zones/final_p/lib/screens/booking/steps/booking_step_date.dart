import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/zonez_colors.dart';
import '../../../providers/lounge_booking_provider.dart';
import '../../../utils/date_format_utils.dart';

class BookingStepDate extends StatelessWidget {
  const BookingStepDate({super.key});

  Future<void> _pickDate(BuildContext context, LoungeBookingProvider flow) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: flow.selectedDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
      locale: const Locale('ar'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: ZonezColors.neonPurple,
              onPrimary: Colors.white,
              surface: ZonezColors.cardDark,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      flow.selectDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final flow = context.watch<LoungeBookingProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'التاريخ',
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'اختر يوم الحجز — سيتم عرض الأوقات المتاحة في الخطوة التالية',
            style: GoogleFonts.cairo(fontSize: 13, color: ZonezColors.textMuted),
          ),
          const SizedBox(height: 24),
          if (flow.selectedDevice != null)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: ZonezColors.inputBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: ZonezColors.neonPurple.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  Icon(flow.selectedDevice!.icon, color: ZonezColors.neonCyan),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      flow.selectedDevice!.nameAr,
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          Material(
            color: ZonezColors.cardDark,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _pickDate(context, flow),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: ZonezColors.neonPurple.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: ZonezColors.neonPurple.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.calendar_month,
                        color: ZonezColors.neonPurple,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'تاريخ الحجز',
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              color: ZonezColors.textMuted,
                            ),
                          ),
                          Text(
                            flow.selectedDate != null
                                ? formatArabicDate(flow.selectedDate!)
                                : 'اضغط لاختيار التاريخ',
                            style: GoogleFonts.cairo(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: flow.selectedDate != null
                                  ? Colors.white
                                  : ZonezColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_left, color: ZonezColors.textMuted),
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
