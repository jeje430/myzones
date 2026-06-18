import '../data/dto/lounge_catalog_dto.dart';
import '../data/seeds/lounge_catalog_seed.dart';
import '../models/lounge_model.dart';
import '../models/lounge_rating.dart';
import '../utils/booking_time_utils.dart';

/// Mock lounge catalog and rating storage — backed by API-shaped seed data.
/// Replace [LoungeCatalogRepository.fetchCatalog] with HTTP when the dashboard API is live.
class LoungeDataStore {
  LoungeDataStore._();
  static final LoungeDataStore instance = LoungeDataStore._();

  final Map<String, LoungeModel> _lounges = {};
  final Map<String, List<StoredCategoryRating>> _ratingsByLounge = {};

  void seedIfEmpty() {
    if (_lounges.isNotEmpty) return;

    final catalog = kLoungeCatalogApiPayload
        .map(LoungeCatalogDto.fromJson)
        .toList();

    for (final dto in catalog) {
      _lounges[dto.id] = LoungeCatalogMapper.toLounge(dto);
      _ratingsByLounge[dto.id] = LoungeCatalogMapper.toStoredReviews(dto);
      _recalculateAverages(dto.id);
    }
  }

  List<LoungeModel> getAllLounges() {
    seedIfEmpty();
    return _lounges.values.toList();
  }

  LoungeModel? getLounge(String id) {
    seedIfEmpty();
    return _lounges[id];
  }

  LoungeModel? getLoungeByName(String name) {
    seedIfEmpty();
    for (final lounge in _lounges.values) {
      if (lounge.name == name) return lounge;
    }
    return null;
  }

  List<StoredCategoryRating> getReviews(
    String loungeId, {
    RatingCategory? category,
  }) {
    seedIfEmpty();
    final lounge = _lounges[loungeId];
    final ratings = _ratingsByLounge[loungeId] ?? [];
    final supported = lounge?.supportedRatingCategories.toSet() ?? {};
    final filtered = ratings.where((r) => supported.contains(r.category));
    final byCategory = category == null
        ? filtered
        : filtered.where((r) => r.category == category);
    return List<StoredCategoryRating>.from(byCategory)
      ..sort((a, b) {
        final aTime = a.submittedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.submittedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
  }

  double averageForCategory(String loungeId, RatingCategory category) {
    seedIfEmpty();
    final lounge = _lounges[loungeId];
    if (lounge != null && !lounge.supportedRatingCategories.contains(category)) {
      return 0;
    }
    final ratings = _ratingsByLounge[loungeId]
            ?.where((r) => r.category == category)
            .map((r) => r.stars)
            .toList() ??
        [];
    if (ratings.isEmpty) return 0;
    return ratings.reduce((a, b) => a + b) / ratings.length;
  }

  void submitRating(LoungeRatingSubmission submission) {
    seedIfEmpty();
    final lounge = _lounges[submission.loungeId];
    if (lounge == null) return;

    final supported = lounge.supportedRatingCategories.toSet();
    final stored = _ratingsByLounge.putIfAbsent(submission.loungeId, () => []);

    for (final input in submission.categories) {
      if (!input.isValid) continue;
      if (!supported.contains(input.category)) continue;
      stored.add(
        StoredCategoryRating(
          category: input.category,
          stars: input.stars,
          comment: input.comment.trim(),
          submittedAt: submission.submittedAt,
        ),
      );
    }
    _recalculateAverages(submission.loungeId);
  }

  void _recalculateAverages(String loungeId) {
    final lounge = _lounges[loungeId];
    if (lounge == null) return;

    final generalAvg = averageForCategory(loungeId, RatingCategory.general);
    final generalCount = _ratingsByLounge[loungeId]
            ?.where((r) => r.category == RatingCategory.general)
            .length ??
        0;

    final updatedDevices = lounge.devices.map((device) {
      final category = RatingCategory.fromDeviceType(device.type);
      if (category == null || !device.isAvailable) return device;
      final avg = averageForCategory(loungeId, category);
      return device.copyWith(
        averageRating: avg > 0
            ? double.parse(avg.toStringAsFixed(1))
            : device.averageRating,
      );
    }).toList();

    _lounges[loungeId] = lounge.copyWith(
      loungeAverageRating: generalAvg > 0
          ? double.parse(generalAvg.toStringAsFixed(1))
          : lounge.loungeAverageRating,
      reviewCount: generalCount > 0 ? generalCount : lounge.reviewCount,
      devices: updatedDevices,
    );
  }

  AvailabilityResult checkAvailability({
    required String loungeId,
    required DeviceType deviceType,
    required DateTime date,
  }) {
    seedIfEmpty();
    final lounge = _lounges[loungeId];
    if (lounge == null) {
      return const AvailabilityResult(
        isAvailable: false,
        message: 'الصالة غير موجودة',
      );
    }

    final device = lounge.deviceByType(deviceType);
    if (device == null || !device.isAvailable) {
      return const AvailabilityResult(
        isAvailable: false,
        message: 'نعتذر، لا يوجد جهاز متاح',
      );
    }

    if (deviceType == DeviceType.vr && date.weekday == DateTime.sunday) {
      return const AvailabilityResult(
        isAvailable: false,
        message: 'نعتذر، لا يوجد جهاز متاح',
      );
    }

    final slots = _generateSlots(date);
    final availableSlots =
        slots.where((s) => s.isAvailable).toList(growable: false);

    if (availableSlots.isEmpty) {
      return const AvailabilityResult(
        isAvailable: false,
        message: 'نعتذر، لا يوجد جهاز متاح',
      );
    }

    return AvailabilityResult(isAvailable: true, slots: availableSlots);
  }

  List<HourlyTimeSlot> _generateSlots(DateTime date) {
    final hours = [17, 18, 19, 20, 21, 22];
    return hours.map((hour) {
      final start = DateTime(date.year, date.month, date.day, hour);
      final isPast = start.isBefore(DateTime.now());
      final label = formatHourlySlotLabel(hour);
      return HourlyTimeSlot(
        id: '${date.millisecondsSinceEpoch}-$hour',
        label: label,
        startDateTime: start,
        isAvailable: !isPast,
      );
    }).toList();
  }

  final Set<String> _bookedSlotKeys = {};

  Future<DeviceBookingConfirmation> confirmDeviceBooking({
    required String loungeId,
    required DeviceType deviceType,
    required DateTime date,
    required HourlyTimeSlot slot,
  }) async {
    seedIfEmpty();
    final key = '$loungeId-${deviceType.name}-${slot.id}';
    if (_bookedSlotKeys.contains(key)) {
      throw Exception('هذا الوقت محجوز مسبقاً');
    }
    _bookedSlotKeys.add(key);

    final lounge = _lounges[loungeId]!;
    final device = lounge.deviceByType(deviceType)!;
    final bookingId =
        'ZNS-${DateTime.now().millisecondsSinceEpoch}-${deviceType.name}';

    return DeviceBookingConfirmation(
      bookingId: bookingId,
      finalPrice: device.hourlyRate,
      earnedPoints: (device.hourlyRate * 0.5).round(),
    );
  }
}

class DeviceBookingConfirmation {
  const DeviceBookingConfirmation({
    required this.bookingId,
    required this.finalPrice,
    required this.earnedPoints,
  });

  final String bookingId;
  final double finalPrice;
  final int earnedPoints;
}
