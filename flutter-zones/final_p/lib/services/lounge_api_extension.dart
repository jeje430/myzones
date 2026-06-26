import '../data/dto/lounge_catalog_dto.dart';
import '../data/repositories/lounge_catalog_repository.dart';
import '../core/http/api_client.dart';
import '../models/lounge_model.dart';
import '../models/lounge_rating.dart';
import '../models/device_rating.dart';
import '../models/lounge_comment.dart';

export '../data/repositories/booking_repository.dart'
    show DeviceBookingConfirmation, BookingRepository;

/// In-memory lounge cache backed by Laravel GET /api/lounges.
class LoungeDataStore {
  LoungeDataStore._();
  static final LoungeDataStore instance = LoungeDataStore._();

  final LoungeCatalogRepository _repository = LoungeCatalogRepository.instance;

  final Map<String, LoungeModel> _lounges = {};
  final Map<String, List<StoredCategoryRating>> _ratingsByLounge = {};
  final Map<String, List<LoungeComment>> _commentsByLounge = {};
  bool _isLoaded = false;
  Future<void>? _loadFuture;

  Future<void> ensureLoaded({bool forceRefresh = false}) {
    if (_isLoaded && !forceRefresh) {
      return Future.value();
    }

    final pending = _loadFuture;
    if (pending != null && !forceRefresh) {
      return pending;
    }

    return _loadFuture = _loadFromApi(forceRefresh: forceRefresh);
  }

  Future<void> _loadFromApi({required bool forceRefresh}) async {
    try {
      final catalog = await _repository.fetchCatalog(forceRefresh: forceRefresh);

      final nextLounges = <String, LoungeModel>{};
      final nextRatings = <String, List<StoredCategoryRating>>{};
      final nextComments = <String, List<LoungeComment>>{};

      for (final dto in catalog) {
        nextLounges[dto.id] = LoungeCatalogMapper.toLounge(dto);
        nextRatings[dto.id] = LoungeCatalogMapper.toStoredReviews(dto);
        nextComments[dto.id] = LoungeCatalogMapper.toStoredComments(dto);
      }

      _lounges
        ..clear()
        ..addAll(nextLounges);
      _ratingsByLounge
        ..clear()
        ..addAll(nextRatings);
      _commentsByLounge
        ..clear()
        ..addAll(nextComments);

      _isLoaded = true;
    } finally {
      _loadFuture = null;
    }
  }

  List<LoungeModel> getAllLounges() => _lounges.values.toList();

  LoungeModel? getLounge(String id) => _lounges[id];

  LoungeModel? getLoungeByName(String name) {
    for (final lounge in _lounges.values) {
      if (lounge.name == name) return lounge;
    }
    return null;
  }

  List<LoungeComment> getComments(String loungeId) {
    return List<LoungeComment>.from(_commentsByLounge[loungeId] ?? []);
  }

  List<StoredCategoryRating> getReviews(
    String loungeId, {
    RatingCategory? category,
  }) {
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

  Future<void> submitCombinedRatings({
    required String loungeId,
    CategoryRatingInput? generalRating,
    required List<DeviceRatingInput> deviceRatings,
  }) async {
    if (generalRating != null && generalRating.isValid) {
      await _repository.submitReview(
        loungeId: loungeId,
        category: generalRating.category,
        stars: generalRating.stars,
      );
    }

    final validDevices = deviceRatings.where((r) => r.isValid).toList();
    if (validDevices.isNotEmpty) {
      await _repository.submitDeviceRatings(
        loungeId: loungeId,
        ratings: validDevices,
      );
    }

    await refreshLounge(loungeId);
  }

  Future<LoungeComment> submitComment({
    required String loungeId,
    required String body,
  }) async {
    final comment = await _repository.submitComment(
      loungeId: loungeId,
      body: body,
    );
    await refreshLounge(loungeId);
    return comment;
  }

  Future<LoungeComment> updateComment({
    required String loungeId,
    required int commentId,
    required String body,
  }) async {
    final comment = await _repository.updateComment(
      loungeId: loungeId,
      commentId: commentId,
      body: body,
    );
    await refreshLounge(loungeId);
    return comment;
  }

  void removeLounge(String loungeId) {
    _lounges.remove(loungeId);
    _ratingsByLounge.remove(loungeId);
    _commentsByLounge.remove(loungeId);
  }

  Future<LoungeModel> refreshLounge(String loungeId) async {
    try {
      final dto = await _repository.fetchLounge(loungeId);
      final lounge = LoungeCatalogMapper.toLounge(dto);
      _lounges[loungeId] = lounge;
      _ratingsByLounge[loungeId] = LoungeCatalogMapper.toStoredReviews(dto);
      _commentsByLounge[loungeId] = LoungeCatalogMapper.toStoredComments(dto);
      _isLoaded = true;
      return lounge;
    } on ApiException catch (error) {
      if (error.statusCode == 404) {
        removeLounge(loungeId);
      }
      rethrow;
    }
  }

  Future<List<LoungeModel>> loadNearbyAndMerge({
    required double latitude,
    required double longitude,
    double radiusKm = 100,
    bool openNow = false,
  }) async {
    final dtos = await _repository.fetchNearbyLounges(
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
      openNow: openNow,
    );

    final nearby = <LoungeModel>[];
    for (final dto in dtos) {
      final lounge = LoungeCatalogMapper.toLounge(dto);
      _lounges[lounge.id] = lounge;
      _ratingsByLounge[lounge.id] = LoungeCatalogMapper.toStoredReviews(dto);
      _commentsByLounge[lounge.id] = LoungeCatalogMapper.toStoredComments(dto);
      nearby.add(lounge);
    }

    _isLoaded = true;
    return nearby;
  }
}
