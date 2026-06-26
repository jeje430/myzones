import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import 'package:webview_flutter/webview_flutter.dart';



import '../../core/config/api_config.dart';

import '../../core/theme/zonez_colors.dart';



enum PlutuPaymentOutcome { success, canceled }



/// Result returned after the Plutu WebView closes.

class PlutuPaymentWebViewResult {

  const PlutuPaymentWebViewResult({

    required this.outcome,

    this.invoiceNo,

    this.callbackParams = const {},

  });



  final PlutuPaymentOutcome outcome;

  final String? invoiceNo;

  final Map<String, String> callbackParams;

}



/// Opens Plutu checkout (sandbox or production) inside an in-app WebView.

class PlutuPaymentWebViewScreen extends StatefulWidget {

  const PlutuPaymentWebViewScreen({

    super.key,

    required this.paymentUrl,

    this.expectedInvoiceNo,

  });



  final String paymentUrl;

  final String? expectedInvoiceNo;



  @override

  State<PlutuPaymentWebViewScreen> createState() =>

      _PlutuPaymentWebViewScreenState();

}



class _PlutuPaymentWebViewScreenState extends State<PlutuPaymentWebViewScreen> {

  late final WebViewController _controller;

  bool _isLoading = true;

  bool _finished = false;

  Map<String, String> _callbackParams = {};

  String? _invoiceNo;



  bool _isSuccessUrl(String url) {

    final lower = url.toLowerCase();

    return lower.contains('approved=1') ||

        lower.contains('status=success') ||

        lower.contains('payment-success');

  }



  bool _isCancelUrl(String url) {

    final lower = url.toLowerCase();

    return lower.contains('canceled=1') ||

        lower.contains('status=canceled') ||

        lower.contains('status=cancelled') ||

        lower.contains('payment-cancel') ||

        lower.contains('status=failed');

  }



  bool _isCallbackUrl(String url) {

    final callback = ApiConfig.paymentCallbackUrl.toLowerCase();

    return url.toLowerCase().startsWith(callback);

  }



  void _captureParamsFromUrl(String url) {

    final uri = Uri.tryParse(url);

    if (uri == null) return;



    final params = <String, String>{};

    uri.queryParameters.forEach((key, value) {

      params[key] = value;

    });



    if (params.isNotEmpty) {

      _callbackParams = {..._callbackParams, ...params};

    }



    _invoiceNo = params['invoice_no'] ??

        params['invoiceNo'] ??

        widget.expectedInvoiceNo;

  }



  void _finish(PlutuPaymentOutcome outcome) {

    if (_finished || !mounted) return;

    _finished = true;



    Navigator.pop(

      context,

      PlutuPaymentWebViewResult(

        outcome: outcome,

        invoiceNo: _invoiceNo ?? widget.expectedInvoiceNo,

        callbackParams: _callbackParams,

      ),

    );

  }



  @override

  void initState() {

    super.initState();

    _invoiceNo = widget.expectedInvoiceNo;



    _controller = WebViewController()

      ..setJavaScriptMode(JavaScriptMode.unrestricted)

      ..setBackgroundColor(const Color(0xFF0A0A0F))

      ..setNavigationDelegate(

        NavigationDelegate(

          onPageStarted: (_) => setState(() => _isLoading = true),

          onWebResourceError: (err) {

            debugPrint('WebView error: ${err.description}');

          },

          onNavigationRequest: (request) {

            final url = request.url;

            debugPrint('WebView → $url');

            _captureParamsFromUrl(url);



            if (_isCallbackUrl(url)) {

              return NavigationDecision.navigate;

            }



            if (_isSuccessUrl(url)) {

              Future<void>.delayed(const Duration(milliseconds: 1200), () {

                if (mounted) _finish(PlutuPaymentOutcome.success);

              });

              return NavigationDecision.prevent;

            }



            if (_isCancelUrl(url)) {

              _finish(PlutuPaymentOutcome.canceled);

              return NavigationDecision.prevent;

            }



            return NavigationDecision.navigate;

          },

          onPageFinished: (url) {

            if (mounted) setState(() => _isLoading = false);

            _captureParamsFromUrl(url);



            if (_isCallbackUrl(url) || _isSuccessUrl(url)) {

              Future<void>.delayed(const Duration(milliseconds: 1500), () {

                if (!mounted || _finished) return;



                if (_isCancelUrl(url)) {

                  _finish(PlutuPaymentOutcome.canceled);

                  return;

                }



                if (_isSuccessUrl(url) ||

                    url.toLowerCase().contains('status=success') ||

                    _callbackParams['approved'] == '1') {

                  _finish(PlutuPaymentOutcome.success);

                }

              });

            }

          },

        ),

      )

      ..loadRequest(Uri.parse(widget.paymentUrl));

  }



  Future<void> _confirmClose() async {

    final leave = await showDialog<bool>(

      context: context,

      builder: (ctx) => AlertDialog(

        backgroundColor: ZonezColors.cardDark,

        title: Text(

          'إلغاء الدفع',

          style: GoogleFonts.cairo(color: Colors.white),

        ),

        content: Text(

          'هل تريد إلغاء عملية الدفع؟',

          style: GoogleFonts.cairo(color: ZonezColors.textMuted),

        ),

        actions: [

          TextButton(

            onPressed: () => Navigator.pop(ctx, false),

            child: Text('لا', style: GoogleFonts.cairo(color: ZonezColors.neonPurple)),

          ),

          TextButton(

            onPressed: () => Navigator.pop(ctx, true),

            child: Text('نعم', style: GoogleFonts.cairo(color: ZonezColors.neonRed)),

          ),

        ],

      ),

    );



    if (leave == true && mounted) {

      _finish(PlutuPaymentOutcome.canceled);

    }

  }



  @override

  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: const Color(0xFF0A0A0F),

      appBar: AppBar(

        backgroundColor: const Color(0xFF0A0A0F),

        elevation: 0,

        leading: IconButton(

          icon: const Icon(Icons.close, color: Colors.white),

          onPressed: _confirmClose,

        ),

        title: Text(

          'إتمام الدفع',

          style: GoogleFonts.cairo(

            color: Colors.white,

            fontWeight: FontWeight.bold,

          ),

        ),

        centerTitle: true,

      ),

      body: SafeArea(

        child: Stack(

          children: [

            WebViewWidget(controller: _controller),

            if (_isLoading)

              Container(

                color: const Color(0xFF0A0A0F).withValues(alpha: 0.92),

                child: Center(

                  child: Column(

                    mainAxisSize: MainAxisSize.min,

                    children: [

                      const CircularProgressIndicator(color: ZonezColors.neonPurple),

                      const SizedBox(height: 16),

                      Text(

                        'جاري تحميل صفحة الدفع...',

                        style: GoogleFonts.cairo(

                          color: ZonezColors.textMuted,

                          fontSize: 14,

                        ),

                      ),

                    ],

                  ),

                ),

              ),

          ],

        ),

      ),

    );

  }

}

