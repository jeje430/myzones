import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/booking.dart';

class PdfReceiptService {
  PdfReceiptService._();
  static final PdfReceiptService instance = PdfReceiptService._();

  static const _cairoRegularUrl =
      'https://fonts.gstatic.com/s/cairo/v28/SLXgc1nY6HkvangtZmpQdkhzfH5lkSs2SgRjCAGMQl.ttf';
  static const _cairoBoldUrl =
      'https://fonts.gstatic.com/s/cairo/v28/SLXgc1nY6HkvangtZmpQdkhzfH5lkSs2SgRjCAGMQl.ttf';

  pw.Font? _regularFont;
  pw.Font? _boldFont;

  Future<String> generateAndSaveReceipt(Booking booking) async {
    final font = await _loadRegularFont();
    final boldFont = await _loadBoldFont();
    final issuedAt = DateTime.now();

    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        textDirection: pw.TextDirection.rtl,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 24,
                ),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#6366F1'),
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      'ZONEZ',
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 28,
                        color: PdfColors.white,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'إيصال حجز — Gaming Lounge',
                      style: pw.TextStyle(
                        font: font,
                        fontSize: 13,
                        color: PdfColors.white,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 24),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'رقم الحجز',
                    style: pw.TextStyle(font: font, fontSize: 12),
                  ),
                  pw.Text(
                    booking.id,
                    style: pw.TextStyle(font: boldFont, fontSize: 12),
                  ),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'تاريخ الإصدار',
                    style: pw.TextStyle(font: font, fontSize: 12),
                  ),
                  pw.Text(
                    _formatDate(issuedAt),
                    style: pw.TextStyle(font: boldFont, fontSize: 12),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Column(
                  children: [
                    _row('الصالة', booking.loungeName ?? booking.title, font, boldFont),
                    _divider(),
                    if (booking.deviceName != null) ...[
                      _row('الجهاز', booking.deviceName!, font, boldFont),
                      _divider(),
                    ],
                    _row('التاريخ', booking.day, font, boldFont),
                    _divider(),
                    _row('الوقت', booking.time, font, boldFont),
                    _divider(),
                    _row(
                      'السعر الإجمالي',
                      '${booking.price.toStringAsFixed(0)} د.ل',
                      font,
                      boldFont,
                      highlight: true,
                    ),
                    _divider(),
                    _row('حالة الدفع', booking.paymentStatusLabel, font, boldFont),
                    if (booking.earnedPoints != null) ...[
                      _divider(),
                      _row(
                        'نقاط الولاء',
                        '+${booking.earnedPoints} نقطة',
                        font,
                        boldFont,
                      ),
                    ],
                  ],
                ),
              ),
              pw.Spacer(),
              pw.Divider(thickness: 0.5, color: PdfColors.grey400),
              pw.SizedBox(height: 12),
              pw.Text(
                'شكراً لاختيارك ZONEZ — نتمنى لك تجربة لعب ممتعة!',
                style: pw.TextStyle(font: font, fontSize: 11),
                textAlign: pw.TextAlign.center,
              ),
            ],
          );
        },
      ),
    );

    final bytes = await doc.save();
    final dir = await getApplicationDocumentsDirectory();
    final fileName =
        'zonez_receipt_${booking.id.replaceAll(RegExp(r'[^\w-]'), '_')}.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  pw.Widget _divider() => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 4),
        child: pw.Divider(thickness: 0.3, color: PdfColors.grey300),
      );

  pw.Widget _row(
    String label,
    String value,
    pw.Font font,
    pw.Font boldFont, {
    bool highlight = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              font: font,
              fontSize: 13,
              color: highlight ? PdfColor.fromHex('#06B6D4') : null,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              font: boldFont,
              fontSize: highlight ? 15 : 13,
              color: highlight ? PdfColor.fromHex('#06B6D4') : null,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  Future<pw.Font> _loadRegularFont() async {
    _regularFont ??= pw.Font.ttf(
      ByteData.sublistView(await _fetchFontBytes(_cairoRegularUrl)),
    );
    return _regularFont!;
  }

  Future<pw.Font> _loadBoldFont() async {
    _boldFont ??= pw.Font.ttf(
      ByteData.sublistView(await _fetchFontBytes(_cairoBoldUrl)),
    );
    return _boldFont!;
  }

  Future<Uint8List> _fetchFontBytes(String url) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      if (response.statusCode != 200) {
        throw Exception('Failed to load font');
      }
      return consolidateHttpClientResponseBytes(response);
    } finally {
      client.close();
    }
  }
}
