import 'package:flutter/foundation.dart';

import '../models/lounge_model.dart';
import '../models/lounge_rating.dart';
import '../models/device_rating.dart';
import '../models/lounge_comment.dart';
import '../services/lounge_api_extension.dart';

class LoungeRatingsProvider extends ChangeNotifier {
  final LoungeDataStore _store = LoungeDataStore.instance;

  List<LoungeModel> _lounges = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _isSubmittingComment = false;
  String? _error;

  List<LoungeModel> get lounges => List.unmodifiable(_lounges);
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  bool get isSubmittingComment => _isSubmittingComment;
  String? get error => _error;

  LoungeRatingsProvider() {
    loadLounges();
  }

  Future<void> loadLounges({bool forceRefresh = false}) async {
    if (_isLoading && !forceRefresh) return;

    final stale = _store.getAllLounges();
    if (stale.isNotEmpty && _lounges.isEmpty) {
      _lounges = stale;
      notifyListeners();
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _store.ensureLoaded(forceRefresh: forceRefresh);
      _lounges = _store.getAllLounges();
      _error = null;
    } catch (e) {
      final cached = _store.getAllLounges();
      if (cached.isNotEmpty) {
        _lounges = cached;
        _error = null;
      } else {
        _error = _friendlyLoadError(e);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void refreshLounges() => loadLounges(forceRefresh: true);

  /// Nearby lounges for the explore map only — does not replace [lounges].
  Future<List<LoungeModel>> loadNearbyLounges({
    required double latitude,
    required double longitude,
    double radiusKm = 100,
    bool openNow = false,
  }) {
    return _store.loadNearbyAndMerge(
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
      openNow: openNow,
    );
  }

  LoungeModel? loungeById(String id) => _store.getLounge(id);

  LoungeModel? loungeByName(String name) => _store.getLoungeByName(name);

  double categoryAverage(String loungeId, RatingCategory category) {
    return _store.averageForCategory(loungeId, category);
  }

  List<StoredCategoryRating> reviewsForLounge(
    String loungeId, {
    RatingCategory? category,
  }) {
    return _store.getReviews(loungeId, category: category);
  }

  List<LoungeComment> commentsForLounge(String loungeId) {
    return _store.getComments(loungeId);
  }

  Future<void> refreshLoungeDetails(String loungeId) async {
    try {
      await _store.refreshLounge(loungeId);
      _lounges = _store.getAllLounges();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> submitComment({
    required String loungeId,
    required String body,
  }) async {
    _isSubmittingComment = true;
    _error = null;
    notifyListeners();

    try {
      await _store.submitComment(loungeId: loungeId, body: body);
      _lounges = _store.getAllLounges();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isSubmittingComment = false;
      notifyListeners();
    }
  }

  Future<bool> updateComment({
    required String loungeId,
    required int commentId,
    required String body,
  }) async {
    _isSubmittingComment = true;
    _error = null;
    notifyListeners();

    try {
      await _store.updateComment(
        loungeId: loungeId,
        commentId: commentId,
        body: body,
      );
      _lounges = _store.getAllLounges();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isSubmittingComment = false;
      notifyListeners();
    }
  }

  Future<bool> submitCombinedRatings({
    required String loungeId,
    CategoryRatingInput? generalRating,
    required List<DeviceRatingInput> deviceRatings,
  }) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      await _store.submitCombinedRatings(
        loungeId: loungeId,
        generalRating: generalRating,
        deviceRatings: deviceRatings,
      );
      _lounges = _store.getAllLounges();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> submitRating({
    required String loungeId,
    required List<CategoryRatingInput> categories,
  }) async {
    CategoryRatingInput? general;
    for (final input in categories) {
      if (input.category == RatingCategory.general && input.isValid) {
        general = input;
        break;
      }
    }

    return submitCombinedRatings(
      loungeId: loungeId,
      generalRating: general,
      deviceRatings: const [],
    );
  }

  String _friendlyLoadError(Object error) {
    final raw = error.toString();
    if (raw.contains('SocketException') ||
        raw.contains('Failed host lookup') ||
        raw.contains('Connection refused') ||
        raw.contains('Network is unreachable')) {
      return 'تعذّر الاتصال بالخادم. تأكّد أن Laravel يعمل على نفس شبكة Wi‑Fi.';
    }
    return raw;
  }
}
