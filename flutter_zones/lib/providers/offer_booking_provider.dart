import 'package:flutter/foundation.dart';

import '../models/booking.dart';
import '../models/zones_models.dart';
import '../services/zones_api_service.dart';
import '../utils/date_format_utils.dart';
import '../utils/booking_time_utils.dart';

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

  final ZonesApiService _api = ZonesApiService.instance;

  OfferBookingStep currentStep = OfferBookingStep.dateSelection;
  DateTime? selectedDate;
  bool isCheckingAvailability = false;
  bool isAvailable = false;
  String? availabilityMessage;
  List<TimeSlotModel> _timeSlots = [];
  TimeSlotModel? selectedSlot;
  PaymentStatus paymentMethod = PaymentStatus.payOnArrival;
  bool isConfirming = false;
  String? errorMessage;
  String? confirmedBookingId;

  /// Wizard steps 2–5; step 1 is [OfferDetailsScreen].
  static const stepLabels = ['التاريخ', 'التحقق', 'الدفع', 'التأكيد'];
  static const stepDisplayOffset = 2;

  List<TimeSlotModel> get availableTimeSlots =>
      _timeSlots.where((s) => s.isAvailable).toList(growable: false);

  bool get canProceedFromDate =>
      selectedDate != null && !isCheckingAvailability;
  bool get canProceedFromVerification => selectedSlot != null;
  bool get canProceedFromPayment => !isConfirming;

  int get earnedPoints => (finalPrice * 0.5).round();

  String get formattedDate =>
      selectedDate != null ? formatArabicDate(selectedDate!) : '';

  String get formattedTime => selectedSlot?.timeRange ?? '';

  DateTime? get slotStartDateTime {
    if (selectedDate == null || selectedSlot == null) return null;
    final parsed = _parseSlotStart(selectedSlot!.timeRange);
    if (parsed == null) return null;
    return DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      parsed.hour,
      parsed.minute,
    );
  }

  DateTime? _parseSlotStart(String timeRange) {
    return parseSlotStartDateTime(timeRange);
  }

  void selectDate(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    if (!offer.isDateInPromoWindow(normalized)) return;
    selectedDate = normalized;
    isAvailable = false;
    availabilityMessage = null;
    selectedSlot = null;
    _timeSlots = [];
    notifyListeners();
  }

  Future<bool> advanceFromDate() async {
    if (selectedDate == null) return false;

    isCheckingAvailability = true;
    isAvailable = false;
    availabilityMessage = null;
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 600));

    if (!offer.isDateInPromoWindow(selectedDate!)) {
      isCheckingAvailability = false;
      availabilityMessage = 'التاريخ خارج فترة العرض';
      notifyListeners();
      return false;
    }

    isAvailable = true;
    availabilityMessage = 'يوجد مكان متاح!';
    isCheckingAvailability = false;
    notifyListeners();

    await loadTimeSlots();
    if (availableTimeSlots.isEmpty) {
      availabilityMessage = 'لا توجد أوقات متاحة في هذا التاريخ';
      isAvailable = false;
      notifyListeners();
      return false;
    }

    currentStep = OfferBookingStep.verification;
    notifyListeners();
    return true;
  }

  Future<void> loadTimeSlots() async {
    try {
      final slots = await _api.fetchTimeSlots(offer.id);
      _timeSlots = slots.where((s) {
        if (!s.isAvailable) return false;
        if (selectedDate == null) return true;
        final start = parseSlotStartDateTime(s.timeRange, onDate: selectedDate);
        if (start == null) return true;
        return start.isAfter(DateTime.now());
      }).toList();
      selectedSlot = null;
      notifyListeners();
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  void selectSlot(TimeSlotModel slot) {
    if (!slot.isAvailable) return;
    selectedSlot = slot;
    notifyListeners();
  }

  void setPaymentMethod(PaymentStatus method) {
    paymentMethod = method;
    notifyListeners();
  }

  Future<bool> confirmBooking() async {
    if (selectedSlot == null || selectedDate == null) return false;

    isConfirming = true;
    errorMessage = null;
    notifyListeners();

    try {
      final confirmation = await _api.confirmBooking(
        offerId: offer.id,
        timeSlotId: selectedSlot!.id,
        loungeName: loungeName,
      );
      confirmedBookingId = confirmation.bookingId;
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
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
    final ok = await confirmBooking();
    if (!ok) return false;
    currentStep = OfferBookingStep.confirmation;
    notifyListeners();
    return true;
  }

  void previousStep() {
    switch (currentStep) {
      case OfferBookingStep.dateSelection:
        return;
      case OfferBookingStep.verification:
        currentStep = OfferBookingStep.dateSelection;
        selectedSlot = null;
        _timeSlots = [];
        isAvailable = false;
      case OfferBookingStep.payment:
        currentStep = OfferBookingStep.verification;
      case OfferBookingStep.confirmation:
        return;
    }
    notifyListeners();
  }
}
