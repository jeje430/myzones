import '../../core/config/api_config.dart';

import '../../core/http/api_client.dart';



class PlutuPaymentResult {

  const PlutuPaymentResult({

    required this.paymentUrl,

    required this.invoiceNo,

    this.transactionId,

  });



  final String paymentUrl;

  final String invoiceNo;

  final int? transactionId;

}



/// Creates Plutu sandbox/production checkout sessions via Laravel.

class PlutuPaymentService {

  PlutuPaymentService._();

  static final PlutuPaymentService instance = PlutuPaymentService._();



  final ApiClient _api = ApiClient.instance;



  Future<PlutuPaymentResult> createPayment({

    required double amount,

    int? bookingId,

  }) async {

    final body = await _api.post(

      ApiConfig.plutuLocalBankCreate,

      body: {

        'amount': amount,

        'booking_id': bookingId,

        'return_url': ApiConfig.paymentCallbackUrl,

      },

    ) as Map<String, dynamic>;



    final paymentUrl = body['payment_url'] as String?;

    if (paymentUrl == null || paymentUrl.isEmpty) {

      throw ApiException(

        statusCode: 400,

        message: (body['message'] as String?) ?? 'لم يُرجع الخادم رابط الدفع',

      );

    }



    return PlutuPaymentResult(

      paymentUrl: paymentUrl,

      invoiceNo: (body['invoice_no'] ?? '') as String,

      transactionId: body['transaction_id'] as int?,

    );

  }

}

