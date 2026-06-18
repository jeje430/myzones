import 'lounge_model.dart';

class CategoryRatingInput {
  const CategoryRatingInput({
    required this.category,
    this.stars = 0,
    this.comment = '',
  });

  final RatingCategory category;
  final int stars;
  final String comment;

  CategoryRatingInput copyWith({int? stars, String? comment}) {
    return CategoryRatingInput(
      category: category,
      stars: stars ?? this.stars,
      comment: comment ?? this.comment,
    );
  }

  bool get isValid => stars >= 1 && stars <= 5;
}

class LoungeRatingSubmission {
  const LoungeRatingSubmission({
    required this.loungeId,
    required this.categories,
    required this.submittedAt,
  });

  final String loungeId;
  final List<CategoryRatingInput> categories;
  final DateTime submittedAt;
}

class StoredCategoryRating {
  const StoredCategoryRating({
    required this.category,
    required this.stars,
    this.comment = '',
    this.submittedAt,
  });

  final RatingCategory category;
  final int stars;
  final String comment;
  final DateTime? submittedAt;

  bool get hasComment => comment.trim().isNotEmpty;
}
