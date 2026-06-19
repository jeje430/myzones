import '../dto/lounge_catalog_dto.dart';
import '../seeds/lounge_catalog_seed.dart';
import '../../models/lounge_model.dart';
import '../../models/lounge_rating.dart';

/// Local catalog source — replace [fetchCatalog] body with HTTP GET when API is ready.
class LoungeCatalogRepository {
  LoungeCatalogRepository._();
  static final LoungeCatalogRepository instance = LoungeCatalogRepository._();

  List<LoungeCatalogDto>? _cached;

  Future<List<LoungeCatalogDto>> fetchCatalog() async {
    if (_cached != null) return _cached!;
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _cached = kLoungeCatalogApiPayload
        .map((json) => LoungeCatalogDto.fromJson(json))
        .toList();
    return _cached!;
  }

  Future<Map<String, LoungeModel>> loadLounges() async {
    final catalog = await fetchCatalog();
    return {
      for (final dto in catalog) dto.id: LoungeCatalogMapper.toLounge(dto),
    };
  }

  Future<Map<String, List<StoredCategoryRating>>> loadReviews() async {
    final catalog = await fetchCatalog();
    return {
      for (final dto in catalog)
        dto.id: LoungeCatalogMapper.toStoredReviews(dto),
    };
  }

  void invalidateCache() => _cached = null;
}
