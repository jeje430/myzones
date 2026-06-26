import '../../core/config/api_config.dart';
import '../../core/http/api_client.dart';
import '../../models/booking.dart';
import '../../models/lounge_model.dart';

class CustomerBookingRecord {
  const CustomerBookingRecord({
    required this.id,
    required this.bookingNumber,
    required this.stationId,
    required this.stationName,
    required this.packageId,
    required this.packageName,
    required this.deviceId,
    required this.deviceCode,
    required this.deviceName,
    required this.date,
    required this.hour,
    required this.hourTo,
    required this.totalPrice,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.bookingStatus,
    this.sessionStatus,
    this.endsAt,
    this.receiptPdfUrl,
    this.platformCommissionRate,
    this.platformCommissionAmount,
    this.hallNetAmount,
  });

  final int id;
  final String bookingNumber;
  final int stationId;
  final String stationName;
  final int packageId;
  final String packageName;
  final int deviceId;
  final String deviceCode;
  final String deviceName;
  final String date;
  final String hour;
  final String hourTo;
  final double totalPrice;
  final String paymentMethod;
  final String paymentStatus;
  final String bookingStatus;
  final String? sessionStatus;
  final String? endsAt;
  final String? receiptPdfUrl;
  final double? platformCommissionRate;
  final double? platformCommissionAmount;
  final double? hallNetAmount;

  factory CustomerBookingRecord.fromJson(Map<String, dynamic> json) {
    return CustomerBookingRecord(
      id: json['id'] as int,
      bookingNumber: (json['booking_number'] ?? '') as String,
      stationId: json['station_id'] as int,
      stationName: (json['station_name'] ?? '') as String,
      packageId: json['package_id'] as int,
      packageName: (json['package_name'] ?? '') as String,
      deviceId: json['device_id'] as int,
      deviceCode: (json['device_code'] ?? '') as String,
      deviceName: (json['device_name'] ?? '') as String,
      date: (json['date'] ?? '') as String,
      hour: (json['hour'] ?? '') as String,
      hourTo: (json['hour_to'] ?? '') as String,
      totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0,
      paymentMethod: (json['payment_method'] ?? 'cash') as String,
      paymentStatus: (json['payment_status'] ?? 'pending') as String,
      bookingStatus: (json['booking_status'] ?? 'pending') as String,
      sessionStatus: json['session_status'] as String?,
      endsAt: json['ends_at'] as String?,
      receiptPdfUrl: json['receipt_pdf_url'] as String?,
      platformCommissionRate: (json['platform_commission_rate'] as num?)?.toDouble(),
      platformCommissionAmount: (json['platform_commission_amount'] as num?)?.toDouble(),
      hallNetAmount: (json['hall_net_amount'] as num?)?.toDouble(),
    );
  }

  PaymentStatus get paymentStatusEnum {
    if (paymentMethod == 'loyalty_reward') {
      return PaymentStatus.payWithPoints;
    }
    if (paymentMethod == 'online' && paymentStatus == 'paid') {
      return PaymentStatus.electronic;
    }
    if (paymentStatus == 'paid') return PaymentStatus.paid;
    return PaymentStatus.payOnArrival;
  }
}

class DeviceBookingConfirmation {
  const DeviceBookingConfirmation({
    required this.bookingId,
    required this.bookingNumber,
    required this.finalPrice,
    required this.earnedPoints,
    this.receiptPdfUrl,
    this.numericId,
  });

  final String bookingId;
  final String bookingNumber;
  final double finalPrice;
  final int earnedPoints;
  final String? receiptPdfUrl;
  final int? numericId;
}

/// Customer lounge bookings — Laravel API.
class BookingRepository {
  BookingRepository._();
  static final BookingRepository instance = BookingRepository._();

  final ApiClient _api = ApiClient.instance;

  Future<AvailabilityResult> checkAvailability({
    required int stationId,
    required int packageId,
    required DateTime date,
    int? offerId,
  }) async {
    final dateStr =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final query = <String, String>{
      'package_id': packageId.toString(),
      'date': dateStr,
    };
    if (offerId != null) {
      query['offer_id'] = offerId.toString();
    }

    final body = await _api.get(
      ApiConfig.loungeAvailability(stationId),
      query: query,
    ) as Map<String, dynamic>;

    final isAvailable = body['is_available'] == true;
    if (!isAvailable) {
      return AvailabilityResult(
        isAvailable: false,
        message: (body['message'] as String?) ?? 'لا يوجد حجز متاح',
      );
    }

    final slotsJson = body['slots'] as List<dynamic>? ?? [];
    final slots = slotsJson.map((raw) {
      final slot = raw as Map<String, dynamic>;
      final hour = (slot['hour'] ?? '00:00') as String;
      final hourParts = hour.split(':');
      final hourInt = int.tryParse(hourParts.first) ?? 0;

      return HourlyTimeSlot(
        id: slot['id'] as String,
        label: (slot['label'] ?? hour) as String,
        startDateTime: DateTime(date.year, date.month, date.day, hourInt),
        isAvailable: slot['is_available'] == true,
        deviceId: slot['device_id'] as int?,
        deviceCode: slot['device_code'] as String?,
        deviceName: slot['device_name'] as String?,
        packageId: slot['package_id'] as int?,
        hour: hour,
        hourTo: slot['hour_to'] as String?,
        totalPrice: (slot['total_price'] as num?)?.toDouble(),
        originalTotalPrice: (slot['original_total_price'] as num?)?.toDouble(),
        discountPercent: (slot['discount_percent'] as num?)?.toInt(),
        endDateTime: () {
          final hourTo = slot['hour_to'] as String?;
          if (hourTo == null) return null;
          final endParts = hourTo.split(':');
          final endH = int.tryParse(endParts.first) ?? hourInt;
          return DateTime(date.year, date.month, date.day, endH);
        }(),
      );
    }).toList();

    if (slots.isEmpty) {
      return const AvailabilityResult(
        isAvailable: false,
        message: 'لا يوجد حجز متاح',
      );
    }

    return AvailabilityResult(isAvailable: true, slots: slots);
  }

  Future<DeviceBookingConfirmation> createBooking({
    required int stationId,
    required int packageId,
    required int deviceId,
    required DateTime date,
    required String hour,
    required String paymentMethod,
    int? offerId,
  }) async {
    final dateStr =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final payload = <String, dynamic>{
      'station_id': stationId,
      'package_id': packageId,
      'device_id': deviceId,
      'date': dateStr,
      'hour': hour,
      'payment_method': paymentMethod,
    };
    if (offerId != null) {
      payload['offer_id'] = offerId;
    }

    final body = await _api.post(
      ApiConfig.bookings,
      body: payload,
    ) as Map<String, dynamic>;

    final booking = CustomerBookingRecord.fromJson(
      body['booking'] as Map<String, dynamic>,
    );

    final loyaltyJson = body['loyalty'] as Map<String, dynamic>?;
    final earned = loyaltyJson == null
        ? 0
        : (loyaltyJson['points_per_completed_session'] as num?)?.toInt() ?? 0;

    return DeviceBookingConfirmation(
      bookingId: booking.bookingNumber,
      bookingNumber: booking.bookingNumber,
      finalPrice: booking.totalPrice,
      earnedPoints: paymentMethod == 'loyalty_reward' ? 0 : earned,
      receiptPdfUrl: booking.receiptPdfUrl,
      numericId: booking.id,
    );
  }

  Future<CustomerBookingRecord> fetchBooking(int id) async {
    final body = await _api.get(ApiConfig.booking(id)) as Map<String, dynamic>;
    return CustomerBookingRecord.fromJson(body['booking'] as Map<String, dynamic>);
  }

  Future<List<CustomerBookingRecord>> fetchMyBookings() async {
    final body = await _api.get(ApiConfig.bookings) as Map<String, dynamic>;
    final list = body['bookings'] as List<dynamic>? ?? [];
    return list
        .map((e) => CustomerBookingRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> cancelBooking(int id) async {
    await _api.post(ApiConfig.bookingCancel(id));
  }

  Future<CustomerBookingRecord> syncPayment(
    int bookingId, {
    String? invoiceNo,
    Map<String, String>? callbackParams,
  }) async {
    final body = <String, dynamic>{};
    if (invoiceNo != null && invoiceNo.isNotEmpty) {
      body['invoice_no'] = invoiceNo;
    }
    if (callbackParams != null && callbackParams.isNotEmpty) {
      body.addAll(callbackParams);
      if (!body.containsKey('approved') &&
          callbackParams.containsKey('status') &&
          callbackParams['status'] == 'success') {
        body['approved'] = 1;
      }
    }

    final response = await _api.post(
      ApiConfig.bookingSyncPayment(bookingId),
      body: body.isEmpty ? null : body,
    ) as Map<String, dynamic>;

    return CustomerBookingRecord.fromJson(response['booking'] as Map<String, dynamic>);
  }

  /// Poll until online payment is confirmed on the server (Plutu callback).
  Future<CustomerBookingRecord?> waitForPaymentConfirmation(
    int bookingId, {
    String? invoiceNo,
    Map<String, String>? callbackParams,
    int maxAttempts = 40,
  }) async {
    Map<String, String>? params = callbackParams;

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        await syncPayment(
          bookingId,
          invoiceNo: invoiceNo,
          callbackParams: attempt < 3 ? params : null,
        );
      } catch (_) {
        // Keep polling — callback may still be processing.
      }

      final record = await fetchBooking(bookingId);
      final paidOnline = record.paymentMethod == 'online' &&
          record.paymentStatus == 'paid';
      final confirmed = record.bookingStatus == 'confirmed';

      if (paidOnline && confirmed) {
        return record;
      }

      await Future<void>.delayed(
        Duration(milliseconds: attempt < 8 ? 600 : 1000),
      );
    }
    return null;
  }

  String receiptPdfPath(int bookingId) =>
      '${ApiConfig.apiUrl}${ApiConfig.bookingReceiptPdf(bookingId)}';
}
