import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../core/config/api_config.dart';
import '../data/repositories/auth_repository.dart';
import '../screens/booking/booking_receipt_viewer_screen.dart';

/// Downloads authenticated booking receipt PDFs from Laravel.
class BookingReceiptService {
  BookingReceiptService._();
  static final BookingReceiptService instance = BookingReceiptService._();

  Future<String> downloadAndSave(int bookingId) async {
    final uri = Uri.parse(
      '${ApiConfig.apiUrl}${ApiConfig.bookingReceiptPdf(bookingId)}',
    );

    final response = await http.get(
      uri,
      headers: AuthRepository.instance.authHeaders,
    );

    if (response.statusCode != 200) {
      throw Exception('تعذر تحميل الإيصال (${response.statusCode})');
    }

    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/booking-$bookingId-receipt.pdf';
    final file = File(path);
    await file.writeAsBytes(response.bodyBytes);
    return path;
  }

  Future<void> openReceipt(int bookingId) async {
    final path = await downloadAndSave(bookingId);
    await OpenFilex.open(path);
  }

  void openReceiptViewer(
    BuildContext context, {
    required int bookingId,
    String? bookingNumber,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BookingReceiptViewerScreen(
          bookingId: bookingId,
          bookingNumber: bookingNumber,
        ),
      ),
    );
  }
}
