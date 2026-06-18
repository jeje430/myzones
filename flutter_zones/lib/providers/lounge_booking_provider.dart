import 'package:flutter/foundation.dart';

import '../models/booking.dart';
import '../models/lounge_model.dart';
import '../services/lounge_api_extension.dart';
import '../utils/date_format_utils.dart';

enum BookingFlowStep {
  packageSelection,
  dateSelection,
  availability,
  payment,
  confirmation,
}

class LoungeBookingProvider extends ChangeNotifier {
  final LoungeDataStore _store = LoungeDataStore.instance;

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
    'التأكيد',
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

  double get totalPrice => selectedDevice?.hourlyRate ?? 0;

  Future<void> checkAvailability() async {
    if (lounge == null || selectedDevice == null || selectedDate == null) {
      return;
    }

    isCheckingAvailability = true;
    errorMessage = null;
    availabilityResult = null;
    selectedSlot = null;
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 600));

    final result = _store.checkAvailability(
      loungeId: lounge!.id,
      deviceType: selectedDevice!.type,
      date: selectedDate!,
    );

    availabilityResult = result;
    isCheckingAvailability = false;
    notifyListeners();
  }

  Future<bool> confirmBooking() async {
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
      await Future<void>.delayed(const Duration(milliseconds: 500));
      confirmation = await _store.confirmDeviceBooking(
        loungeId: lounge!.id,
        deviceType: selectedDevice!.type,
        date: selectedDate!,
        slot: selectedSlot!,
      );
      earnedPoints = confirmation!.earnedPoints;
      currentStep = BookingFlowStep.confirmation;
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
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
}
