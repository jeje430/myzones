import 'package:flutter/foundation.dart';

import '../data/repositories/booking_repository.dart';
import '../models/booking.dart';
import '../models/lounge_model.dart';
import '../utils/date_format_utils.dart';

enum BookingFlowStep {
  packageSelection,
  dateSelection,
  availability,
  payment,
  confirmation,
}

class LoungeBookingProvider extends ChangeNotifier {
  final BookingRepository _bookings = BookingRepository.instance;

  LoungeModel? lounge;
  DevicePackage? selectedDevice;
  DateTime? selectedDate;
  HourlyTimeSlot? selectedSlot;
  AvailabilityResult? availabilityResult;
  PaymentStatus paymentMethod = PaymentStatus.payOnArrival;

  BookingFlowStep currentStep = BookingFlowStep.packageSelection;
  bool isCheckingAvailability = false;
  bool isConfirming = false;
  String? errorMessage;

  DeviceBookingConfirmation? confirmation;
  int earnedPoints = 0;

  static const stepLabels = [
    'اختيار الباقة',
    'التاريخ',
    'التحقق',
    'الدفع',
    'الإيصال',
  ];

  void init(LoungeModel loungeModel) {
    lounge = loungeModel;
    reset();
  }

  void reset() {
    selectedDevice = null;
    selectedDate = null;
    selectedSlot = null;
    availabilityResult = null;
    paymentMethod = PaymentStatus.payOnArrival;
    currentStep = BookingFlowStep.packageSelection;
    isCheckingAvailability = false;
    isConfirming = false;
    errorMessage = null;
    confirmation = null;
    earnedPoints = 0;
    notifyListeners();
  }

  void selectDevice(DevicePackage device) {
    selectedDevice = device;
    notifyListeners();
  }

  void selectDate(DateTime date) {
    selectedDate = DateTime(date.year, date.month, date.day);
    notifyListeners();
  }

  void selectSlot(HourlyTimeSlot slot) {
    selectedSlot = slot;
    notifyListeners();
  }

  void setPaymentMethod(PaymentStatus method) {
    paymentMethod = method;
    notifyListeners();
  }

  bool get canProceedFromStep1 => selectedDevice != null;
  bool get canProceedFromStep2 => selectedDate != null;
  bool get canProceedFromStep3 =>
      availabilityResult?.isAvailable == true && selectedSlot != null;
  bool get canProceedFromStep4 => true;

  double get totalPrice =>
      selectedSlot?.totalPrice ?? selectedDevice?.hourlyRate ?? 0;

  int get stationId => int.tryParse(lounge?.id ?? '') ?? 0;

  int get packageId => int.tryParse(selectedDevice?.id ?? '') ?? 0;

  Future<void> checkAvailability() async {
    if (lounge == null || selectedDevice == null || selectedDate == null) {
      return;
    }

    isCheckingAvailability = true;
    errorMessage = null;
    availabilityResult = null;
    selectedSlot = null;
    notifyListeners();

    try {
      availabilityResult = await _bookings.checkAvailability(
        stationId: stationId,
        packageId: packageId,
        date: selectedDate!,
      );
    } catch (e) {
      errorMessage = e.toString().replaceFirst('ApiException: ', '');
      availabilityResult = AvailabilityResult(
        isAvailable: false,
        message: errorMessage ?? 'تعذر التحقق من التوفر',
      );
    } finally {
      isCheckingAvailability = false;
      notifyListeners();
    }
  }

  /// Creates booking on Laravel. For online payments call with [paymentMethod] `online`
  /// before opening Plutu, then call [refreshConfirmationAfterPayment] after success.
  Future<DeviceBookingConfirmation?> createBookingOnServer({
    required String paymentMethod,
  }) async {
    if (lounge == null ||
        selectedDevice == null ||
        selectedDate == null ||
        selectedSlot == null) {
      return null;
    }

    final slot = selectedSlot!;
    if (slot.deviceId == null || slot.hour == null) {
      throw Exception('بيانات الموعد غير مكتملة');
    }

    return _bookings.createBooking(
      stationId: stationId,
      packageId: packageId,
      deviceId: slot.deviceId!,
      date: selectedDate!,
      hour: slot.hour!,
      paymentMethod: paymentMethod,
    );
  }

  Future<bool> confirmBooking({String paymentMethod = 'cash'}) async {
    if (lounge == null ||
        selectedDevice == null ||
        selectedDate == null ||
        selectedSlot == null) {
      return false;
    }

    isConfirming = true;
    errorMessage = null;
    notifyListeners();

    try {
      final result = await createBookingOnServer(paymentMethod: paymentMethod);
      if (result == null) return false;

      confirmation = result;
      earnedPoints = result.earnedPoints;
      currentStep = BookingFlowStep.confirmation;
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
      earnedPoints = confirmation!.earnedPoints;
      paymentMethod = PaymentStatus.electronic;
      currentStep = BookingFlowStep.confirmation;
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

  void goToStep(BookingFlowStep step) {
    currentStep = step;
    notifyListeners();
  }

  bool nextStep() {
    switch (currentStep) {
      case BookingFlowStep.packageSelection:
        if (!canProceedFromStep1) return false;
        currentStep = BookingFlowStep.dateSelection;
      case BookingFlowStep.dateSelection:
        if (!canProceedFromStep2) return false;
        currentStep = BookingFlowStep.availability;
        checkAvailability();
      case BookingFlowStep.availability:
        if (!canProceedFromStep3) return false;
        currentStep = BookingFlowStep.payment;
      case BookingFlowStep.payment:
        if (!canProceedFromStep4) return false;
        return false;
      case BookingFlowStep.confirmation:
        return false;
    }
    notifyListeners();
    return true;
  }

  void previousStep() {
    switch (currentStep) {
      case BookingFlowStep.packageSelection:
        return;
      case BookingFlowStep.dateSelection:
        currentStep = BookingFlowStep.packageSelection;
      case BookingFlowStep.availability:
        currentStep = BookingFlowStep.dateSelection;
        availabilityResult = null;
        selectedSlot = null;
      case BookingFlowStep.payment:
        currentStep = BookingFlowStep.availability;
      case BookingFlowStep.confirmation:
        currentStep = BookingFlowStep.payment;
    }
    notifyListeners();
  }

  String get formattedDate =>
      selectedDate != null ? formatArabicDate(selectedDate!) : '';

  String get formattedTime =>
      selectedSlot != null ? selectedSlot!.label : '';

  String get orderSummaryDevice => selectedDevice?.nameAr ?? '';

  String get assignedDeviceLabel =>
      selectedSlot?.deviceCode ?? selectedSlot?.deviceName ?? '—';
}
