import '../dto/offer_catalog_dto.dart';
import '../seeds/offer_catalog_seed.dart';
import '../../models/zones_models.dart';

/// Local offer catalog — replace [fetchCatalog] with HTTP GET when API is ready.
class OfferCatalogRepository {
  OfferCatalogRepository._();
  static final OfferCatalogRepository instance = OfferCatalogRepository._();

  List<OfferCatalogDto>? _cached;
  final Map<int, List<TimeSlotModel>> _liveSlots = {};

  Future<List<OfferCatalogDto>> fetchCatalog() async {
    if (_cached != null) return _cached!;
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _cached = buildOfferCatalogApiPayload()
        .map(OfferCatalogDto.fromJson)
        .toList();
    for (final dto in _cached!) {
      _liveSlots[dto.id] = OfferCatalogMapper.toTimeSlots(dto);
    }
    return _cached!;
  }

  Future<List<OfferModel>> fetchActiveOffers() async {
    final catalog = await fetchCatalog();
    return catalog
        .where((o) => !o.toDomain().isExpired)
        .map((o) => o.toDomain())
        .toList();
  }

  Future<List<TimeSlotModel>> fetchTimeSlots(int offerId) async {
    await fetchCatalog();
    return List<TimeSlotModel>.from(_liveSlots[offerId] ?? []);
  }

  double getOfferPrice(int offerId) {
    final dto = _cached?.where((o) => o.id == offerId).firstOrNull;
    return dto?.finalPrice ?? 0;
  }

  OfferCatalogDto? offerById(int offerId) {
    return _cached?.where((o) => o.id == offerId).firstOrNull;
  }

  Future<String> confirmSlotBooking({
    required int offerId,
    required int timeSlotId,
  }) async {
    await fetchCatalog();
    final slots = _liveSlots[offerId];
    if (slots == null) throw Exception('العرض غير موجود');

    final index = slots.indexWhere((s) => s.id == timeSlotId);
    if (index == -1) throw Exception('الوقت المحدد غير موجود');
    if (!slots[index].isAvailable) throw Exception('هذا الوقت محجوز مسبقاً');

    slots[index].isAvailable = false;
    return 'ZNS-${DateTime.now().millisecondsSinceEpoch}-$timeSlotId';
  }

  void invalidateCache() {
    _cached = null;
    _liveSlots.clear();
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final i = iterator;
    return i.moveNext() ? i.current : null;
  }
}
