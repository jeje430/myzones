import 'package:flutter/foundation.dart';

import '../data/repositories/booking_repository.dart';
import '../models/booking.dart';
import '../models/lounge_model.dart';
import '../models/zones_models.dart';
import '../utils/date_format_utils.dart';

enum OfferBookingStep {
  dateSelection,
  verification,
  payment,
  confirmation,
}

class OfferBookingProvider extends ChangeNotifier {
  OfferBookingProvider({
    required this.offer,
    required this.loungeName,
    required this.finalPrice,
  });

  final OfferModel offer;
  final String loungeName;
  final double finalPrice;

  final BookingRepository _bookings = BookingRepository.instance;

  OfferBookingStep currentStep = OfferBookingStep.dateSelection;
  DateTime? selectedDate;
  bool isCheckingAvailability = false;
  bool isAvailable = false;
  String? availabilityMessage;
  AvailabilityResult? availabilityResult;
  HourlyTimeSlot? selectedSlot;
  PaymentStatus paymentMethod = PaymentStatus.payOnArrival;
  bool isConfirming = false;
  String? errorMessage;
  DeviceBookingConfirmation? confirmation;

  static const stepLabels = ['التاريخ', 'التحقق', 'الدفع', 'التأكيد'];
  static const stepDisplayOffset = 2;

  List<HourlyTimeSlot> get availableTimeSlots =>
      availabilityResult?.slots.where((s) => s.isAvailable).toList(growable: false) ??
      const [];

  bool get canProceedFromDate =>
      selectedDate != null && !isCheckingAvailability;
  bool get canProceedFromVerification => selectedSlot != null;
  bool get canProceedFromPayment => !isConfirming;

  int get stationId => offer.stationId ?? 0;
  int get packageId => offer.packageId ?? 0;

  double get checkoutBasePrice =>
      selectedSlot?.totalPrice ?? offer.discountedPrice ?? finalPrice;

  double? get originalTotalPrice =>
      selectedSlot?.originalTotalPrice ?? offer.originalPrice;

  int? get discountPercent =>
      selectedSlot?.discountPercent ?? offer.discountPercent;

  String? get selectedDeviceName => selectedSlot?.deviceName;

  int get earnedPoints => (checkoutBasePrice * 0.5).round();

  String get formattedDate =>
      selectedDate != null ? formatArabicDate(selectedDate!) : '';

  String get formattedTime => selectedSlot?.label ?? '';

  String? get confirmedBookingId => confirmation?.bookingId;

  DateTime? get slotStartDateTime => selectedSlot?.startDateTime;

  void selectDate(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    if (!offer.isDateInPromoWindow(normalized)) return;
    selectedDate = normalized;
    isAvailable = false;
    availabilityMessage = null;
    selectedSlot = null;
    availabilityResult = null;
    notifyListeners();
  }

  Future<bool> advanceFromDate() async {
    if (selectedDate == null || !offer.isBookable) return false;

    isCheckingAvailability = true;
    isAvailable = false;
    availabilityMessage = null;
    availabilityResult = null;
    selectedSlot = null;
    notifyListeners();

    try {
      if (!offer.isDateInPromoWindow(selectedDate!)) {
        availabilityMessage = 'التاريخ خارج فترة العرض';
        return false;
      }

      availabilityResult = await _bookings.checkAvailability(
        stationId: stationId,
        packageId: packageId,
        date: selectedDate!,
        offerId: offer.id,
      );

      if (availabilityResult?.isAvailable != true ||
          availableTimeSlots.isEmpty) {
        availabilityMessage =
            availabilityResult?.message ?? 'لا توجد حجوزات متاحة';
        isAvailable = false;
        return false;
      }

      isAvailable = true;
      availabilityMessage = 'يوجد مكان متاح!';
      currentStep = OfferBookingStep.verification;
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('ApiException: ', '');
      availabilityMessage = errorMessage;
      isAvailable = false;
      return false;
    } finally {
      isCheckingAvailability = false;
      notifyListeners();
    }
  }

  void selectSlot(HourlyTimeSlot slot) {
    if (!slot.isAvailable) return;
    selectedSlot = slot;
    notifyListeners();
  }

  void setPaymentMethod(PaymentStatus method) {
    paymentMethod = method;
    notifyListeners();
  }

  Future<DeviceBookingConfirmation?> createBookingOnServer({
    required String paymentMethod,
  }) async {
    if (selectedSlot == null ||
        selectedDate == null ||
        selectedSlot!.deviceId == null ||
        selectedSlot!.hour == null) {
      return null;
    }

    return _bookings.createBooking(
      stationId: stationId,
      packageId: packageId,
      deviceId: selectedSlot!.deviceId!,
      date: selectedDate!,
      hour: selectedSlot!.hour!,
      paymentMethod: paymentMethod,
      offerId: offer.id,
    );
  }

  Future<bool> confirmBooking({String paymentMethod = 'cash'}) async {
    if (selectedSlot == null || selectedDate == null) return false;

    isConfirming = true;
    errorMessage = null;
    notifyListeners();

    try {
      final result = await createBookingOnServer(paymentMethod: paymentMethod);
      if (result == null) return false;

      confirmation = result;
      currentStep = OfferBookingStep.confirmation;
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('ApiException: ', '');
      return false;
    } finally {
      isConfirming = false;
      notifyListeners();
    }
  }

  Future<bool> refreshConfirmationAfterPayment(
    int bookingId, {
    String? invoiceNo,
    Map<String, String>? callbackParams,
  }) async {
    isConfirming = true;
    errorMessage = null;
    notifyListeners();

    try {
      final record = await _bookings.waitForPaymentConfirmation(
        bookingId,
        invoiceNo: invoiceNo,
        callbackParams: callbackParams,
      );
      if (record == null) {
        throw Exception('تعذر تأكيد الدفع — حاول تحديث حجوزاتي');
      }

      confirmation = DeviceBookingConfirmation(
        bookingId: record.bookingNumber,
        bookingNumber: record.bookingNumber,
        finalPrice: record.totalPrice,
        earnedPoints: (record.totalPrice * 0.5).round(),
        receiptPdfUrl: record.receiptPdfUrl,
        numericId: record.id,
      );
      paymentMethod = PaymentStatus.electronic;
      currentStep = OfferBookingStep.confirmation;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('ApiException: ', '');
      notifyListeners();
      return false;
    } finally {
      isConfirming = false;
      notifyListeners();
    }
  }

  Future<bool> nextStep() async {
    switch (currentStep) {
      case OfferBookingStep.dateSelection:
        return advanceFromDate();
      case OfferBookingStep.verification:
        if (!canProceedFromVerification) return false;
        currentStep = OfferBookingStep.payment;
        notifyListeners();
        return true;
      case OfferBookingStep.payment:
        return false;
      case OfferBookingStep.confirmation:
        return false;
    }
  }

  Future<bool> confirmAndAdvance() async {
    final method =
        paymentMethod == PaymentStatus.electronic ? 'online' : 'cash';
    return confirmBooking(paymentMethod: method);
  }

  void previousStep() {
    switch (currentStep) {
      case OfferBookingStep.dateSelection:
        return;
      case OfferBookingStep.verification:
        currentStep = OfferBookingStep.dateSelection;
        selectedSlot = null;
        availabilityResult = null;
        isAvailable = false;
      case OfferBookingStep.payment:
        currentStep = OfferBookingStep.verification;
      case OfferBookingStep.confirmation:
        return;
    }
    notifyListeners();
  }
}
