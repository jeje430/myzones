import 'package:flutter/foundation.dart';

import '../models/lounge_model.dart';
import '../models/lounge_rating.dart';
import '../services/lounge_api_extension.dart';

class LoungeRatingsProvider extends ChangeNotifier {
  final LoungeDataStore _store = LoungeDataStore.instance;

  List<LoungeModel> _lounges = [];
  bool _isSubmitting = false;
  String? _error;

  List<LoungeModel> get lounges {
    _ensureLoaded();
    return List.unmodifiable(_lounges);
  }

  bool get isSubmitting => _isSubmitting;
  String? get error => _error;

  void _ensureLoaded() {
    if (_lounges.isEmpty) {
      _store.seedIfEmpty();
      _lounges = _store.getAllLounges();
    }
  }

  void refreshLounges() {
    _store.seedIfEmpty();
    _lounges = _store.getAllLounges();
    notifyListeners();
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

  Future<bool> submitRating({
    required String loungeId,
    required List<CategoryRatingInput> categories,
  }) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      _store.submitRating(
        LoungeRatingSubmission(
          loungeId: loungeId,
          categories: categories.where((c) => c.isValid).toList(),
          submittedAt: DateTime.now(),
        ),
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
}
