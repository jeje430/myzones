import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_filex/open_filex.dart';
import 'package:pdfx/pdfx.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/zonez_colors.dart';
import '../../services/booking_receipt_service.dart';

/// In-app viewer for server-generated booking receipt PDFs.
class BookingReceiptViewerScreen extends StatefulWidget {
  const BookingReceiptViewerScreen({
    super.key,
    required this.bookingId,
    this.bookingNumber,
  });

  final int bookingId;
  final String? bookingNumber;

  @override
  State<BookingReceiptViewerScreen> createState() =>
      _BookingReceiptViewerScreenState();
}

class _BookingReceiptViewerScreenState extends State<BookingReceiptViewerScreen> {
  PdfControllerPinch? _controller;
  String? _filePath;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _loadPdf() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final path =
          await BookingReceiptService.instance.downloadAndSave(widget.bookingId);
      final controller = PdfControllerPinch(
        document: PdfDocument.openFile(path),
      );

      if (!mounted) {
        controller.dispose();
        return;
      }

      setState(() {
        _filePath = path;
        _controller = controller;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _shareReceipt() async {
    if (_filePath == null) return;
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(_filePath!)],
        subject: widget.bookingNumber ?? 'إيصال الحجز',
        text: 'إيصال حجز ZONES',
      ),
    );
  }

  Future<void> _openExternally() async {
    if (_filePath == null) return;
    await OpenFilex.open(_filePath!);
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.bookingNumber ?? 'إيصال الحجز';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(title, style: GoogleFonts.cairo(fontSize: 16)),
        actions: [
          if (_filePath != null) ...[
            IconButton(
              tooltip: 'مشاركة',
              onPressed: _shareReceipt,
              icon: const Icon(Icons.share_outlined),
            ),
            IconButton(
              tooltip: 'فتح خارجياً',
              onPressed: _openExternally,
              icon: const Icon(Icons.download_outlined),
            ),
          ],
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: ZonezColors.neonPurple),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(color: ZonezColors.neonRed),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _loadPdf,
                child: Text('إعادة المحاولة', style: GoogleFonts.cairo()),
              ),
            ],
          ),
        ),
      );
    }

    final controller = _controller;
    if (controller == null) {
      return const SizedBox.shrink();
    }

    return PdfViewPinch(
      controller: controller,
      scrollDirection: Axis.vertical,
      padding: 10,
      backgroundDecoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
      ),
    );
  }
}
