import 'lounge_comment.dart';

class CommentsPageMeta {
  const CommentsPageMeta({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  bool get hasNext => currentPage < lastPage;
  bool get hasPrevious => currentPage > 1;

  factory CommentsPageMeta.fromJson(Map<String, dynamic> json) {
    return CommentsPageMeta(
      currentPage: json['current_page'] as int? ?? 1,
      lastPage: json['last_page'] as int? ?? 1,
      perPage: json['per_page'] as int? ?? 10,
      total: json['total'] as int? ?? 0,
    );
  }
}

class PaginatedComments {
  const PaginatedComments({
    required this.comments,
    required this.meta,
  });

  final List<LoungeComment> comments;
  final CommentsPageMeta meta;
}
