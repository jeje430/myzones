import '../../core/http/api_client.dart';
import '../dto/offer_catalog_dto.dart';
import '../../models/zones_models.dart';

/// Fetches offers from Laravel GET /api/offers.
class OfferCatalogRepository {
  OfferCatalogRepository._();
  static final OfferCatalogRepository instance = OfferCatalogRepository._();

  final ApiClient _api = ApiClient.instance;

  List<OfferCatalogDto>? _cached;

  Future<List<OfferCatalogDto>> fetchCatalog({bool forceRefresh = false}) async {
    if (!forceRefresh && _cached != null) return _cached!;

    final body = await _api.get('/offers');
    if (body is! List) {
      throw const ApiException(
        statusCode: 500,
        message: 'استجابة غير متوقعة من خادم العروض',
      );
    }

    _cached = body
        .map((e) => OfferCatalogDto.fromJson(e as Map<String, dynamic>))
        .toList();

    return _cached!;
  }

  Future<List<OfferModel>> fetchActiveOffers({bool forceRefresh = false}) async {
    final catalog = await fetchCatalog(forceRefresh: forceRefresh);
    return catalog.map(OfferCatalogMapper.toOffer).toList();
  }

  Future<List<TimeSlotModel>> fetchTimeSlots(int offerId) async {
    final catalog = await fetchCatalog();
    final offer = catalog.where((o) => o.id == offerId).firstOrNull;
    if (offer == null) return const [];
    return OfferCatalogMapper.toTimeSlots(offer);
  }

  double getOfferPrice(int offerId) {
    final offer = _cached?.where((o) => o.id == offerId).firstOrNull;
    return offer?.finalPrice ?? 0;
  }

  Future<String> confirmSlotBooking({
    required int offerId,
    required int timeSlotId,
  }) async {
    final body = await _api.post(
      '/offers/$offerId/slots/$timeSlotId/book',
    ) as Map<String, dynamic>;

    invalidateCache();
    return body['booking_id'] as String;
  }

  void invalidateCache() => _cached = null;
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
