import '../../core/config/api_config.dart';
import '../../core/http/api_client.dart';
import '../dto/lounge_catalog_dto.dart';
import '../../models/lounge_model.dart';
import '../../models/lounge_rating.dart';
import '../../models/device_rating.dart';
import '../../models/lounge_comment.dart';
import '../../models/booking_stop_status.dart';
import '../../models/paginated_comments.dart';

/// Fetches lounge catalog from Laravel GET /api/lounges.
class LoungeCatalogRepository {
  LoungeCatalogRepository._();
  static final LoungeCatalogRepository instance = LoungeCatalogRepository._();

  final ApiClient _api = ApiClient.instance;

  List<LoungeCatalogDto>? _cached;

  Future<List<LoungeCatalogDto>> fetchCatalog({bool forceRefresh = false}) async {
    if (!forceRefresh && _cached != null) return _cached!;

    final body = await _api.get(ApiConfig.lounges);
    if (body is! List) {
      throw const ApiException(
        statusCode: 500,
        message: 'استجابة غير متوقعة من خادم الصالات',
      );
    }

    _cached = _parseCatalogList(body);

    return _cached!;
  }

  List<LoungeCatalogDto> _parseCatalogList(List<dynamic> body) {
    final parsed = <LoungeCatalogDto>[];
    for (final item in body) {
      if (item is! Map<String, dynamic>) continue;
      try {
        parsed.add(LoungeCatalogDto.fromJson(item));
      } catch (_) {
        // Skip malformed rows — do not fail the entire home catalog.
      }
    }
    if (parsed.isEmpty && body.isNotEmpty) {
      throw const ApiException(
        statusCode: 500,
        message: 'تعذّر قراءة بيانات الصالات من الخادم',
      );
    }
    return parsed;
  }

  Future<List<LoungeCatalogDto>> fetchNearbyLounges({
    required double latitude,
    required double longitude,
    double radiusKm = 100,
    bool openNow = false,
  }) async {
    final query = <String, String>{
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'radius_km': radiusKm.toString(),
    };

    if (openNow) {
      query['is_open'] = '1';
    }

    final body = await _api.get(ApiConfig.loungesNearby, query: query);
    if (body is! List) {
      throw const ApiException(
        statusCode: 500,
        message: 'استجابة غير متوقعة من خادم الصالات القريبة',
      );
    }

    return body
        .map((e) => LoungeCatalogDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<LoungeCatalogDto> fetchLounge(String loungeId) async {
    final body = await _api.get('${ApiConfig.lounges}/$loungeId');
    if (body is! Map<String, dynamic>) {
      throw const ApiException(
        statusCode: 500,
        message: 'استجابة غير متوقعة من خادم الصالات',
      );
    }

    return LoungeCatalogDto.fromJson(body);
  }

  Future<Map<String, LoungeModel>> loadLounges({bool forceRefresh = false}) async {
    final catalog = await fetchCatalog(forceRefresh: forceRefresh);
    return {
      for (final dto in catalog) dto.id: LoungeCatalogMapper.toLounge(dto),
    };
  }

  Future<List<LoungeModel>> loadNearbyLounges({
    required double latitude,
    required double longitude,
    double radiusKm = 100,
    bool openNow = false,
  }) async {
    final catalog = await fetchNearbyLounges(
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
      openNow: openNow,
    );

    return catalog.map(LoungeCatalogMapper.toLounge).toList();
  }

  Future<Map<String, List<StoredCategoryRating>>> loadReviews({
    bool forceRefresh = false,
  }) async {
    final catalog = await fetchCatalog(forceRefresh: forceRefresh);
    return {
      for (final dto in catalog)
        dto.id: LoungeCatalogMapper.toStoredReviews(dto),
    };
  }

  Future<void> submitReview({
    required String loungeId,
    required RatingCategory category,
    required int stars,
  }) async {
    await _api.post(
      '${ApiConfig.lounges}/$loungeId/reviews',
      body: {
        'category': _categoryKey(category),
        'stars': stars,
      },
    );
    invalidateCache();
  }

  Future<void> submitDeviceRatings({
    required String loungeId,
    required List<DeviceRatingInput> ratings,
  }) async {
    final valid = ratings.where((r) => r.isValid).toList();
    if (valid.isEmpty) return;

    await _api.post(
      '${ApiConfig.lounges}/$loungeId/device-ratings',
      body: {
        'ratings': valid
            .map(
              (r) => {
                'device_id': int.parse(r.deviceId),
                'rating_value': r.stars,
              },
            )
            .toList(),
      },
    );
    invalidateCache();
  }

  Future<PaginatedComments> fetchCommentsPage({
    required String loungeId,
    int page = 1,
    int perPage = 10,
  }) async {
    final body = await _api.get(
      '${ApiConfig.lounges}/$loungeId/comments',
      query: {
        'page': page.toString(),
        'per_page': perPage.toString(),
      },
    );

    if (body is! Map<String, dynamic>) {
      throw const ApiException(statusCode: 500, message: 'استجابة غير متوقعة');
    }

    final rawComments = body['comments'] as List<dynamic>? ?? [];
    final metaJson = body['meta'] as Map<String, dynamic>? ?? {};

    return PaginatedComments(
      comments: rawComments
          .map((e) => CommentCatalogDto.fromJson(e as Map<String, dynamic>).toDomain())
          .toList(),
      meta: CommentsPageMeta.fromJson(metaJson),
    );
  }

  Future<List<LoungeComment>> fetchComments(String loungeId) async {
    final page = await fetchCommentsPage(loungeId: loungeId, page: 1, perPage: 50);
    return page.comments;
  }

  Future<BookingStopStatus?> fetchBookingStopStatus(String loungeId) async {
    final body = await _api.get(ApiConfig.loungeBookingStop(int.parse(loungeId)));
    if (body is! Map<String, dynamic>) return null;
    final raw = body['booking_stop'];
    if (raw is! Map<String, dynamic>) return null;
    return BookingStopStatus.fromJson(raw);
  }

  Future<LoungeComment> submitComment({
    required String loungeId,
    required String body,
  }) async {
    final response = await _api.post(
      '${ApiConfig.lounges}/$loungeId/comments',
      body: {'body': body.trim()},
    );
    if (response is! Map<String, dynamic>) {
      throw const ApiException(statusCode: 500, message: 'استجابة غير متوقعة');
    }
    final comment = response['comment'] as Map<String, dynamic>?;
    if (comment == null) {
      throw const ApiException(statusCode: 500, message: 'استجابة غير متوقعة');
    }
    invalidateCache();
    return CommentCatalogDto.fromJson(comment).toDomain();
  }

  Future<LoungeComment> updateComment({
    required String loungeId,
    required int commentId,
    required String body,
  }) async {
    final response = await _api.put(
      '${ApiConfig.lounges}/$loungeId/comments/$commentId',
      body: {'body': body.trim()},
    );
    if (response is! Map<String, dynamic>) {
      throw const ApiException(statusCode: 500, message: 'استجابة غير متوقعة');
    }
    final comment = response['comment'] as Map<String, dynamic>?;
    if (comment == null) {
      throw const ApiException(statusCode: 500, message: 'استجابة غير متوقعة');
    }
    invalidateCache();
    return CommentCatalogDto.fromJson(comment).toDomain();
  }

  String _categoryKey(RatingCategory category) {
    switch (category) {
      case RatingCategory.general:
        return 'general';
      case RatingCategory.ps5:
        return 'ps5';
      case RatingCategory.pc:
        return 'pc';
      case RatingCategory.vr:
        return 'vr';
      case RatingCategory.xbox:
        return 'xbox';
    }
  }

  void invalidateCache() => _cached = null;
}
