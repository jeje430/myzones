class LoungeComment {
  const LoungeComment({
    required this.id,
    required this.body,
    required this.customerName,
    this.authorUserId,
    this.profileImage,
    this.submittedAt,
    this.editedAt,
    this.canEdit = false,
    this.managerReply,
  });

  final int id;
  final String body;
  final String customerName;
  final int? authorUserId;
  final String? profileImage;
  final DateTime? submittedAt;
  final DateTime? editedAt;
  final bool canEdit;
  final ManagerCommentReply? managerReply;

  /// Latest activity time — prefers edit time, falls back to creation.
  DateTime? get updatedAt => editedAt ?? submittedAt;

  /// Whether the signed-in customer may edit this comment.
  bool isEditableBy({int? currentUserId}) {
    if (canEdit) return true;
    if (currentUserId == null || authorUserId == null) return false;
    return authorUserId == currentUserId;
  }

  LoungeComment copyWith({
    String? body,
    DateTime? editedAt,
    ManagerCommentReply? managerReply,
  }) {
    return LoungeComment(
      id: id,
      body: body ?? this.body,
      customerName: customerName,
      authorUserId: authorUserId,
      profileImage: profileImage,
      submittedAt: submittedAt,
      editedAt: editedAt ?? this.editedAt,
      canEdit: canEdit,
      managerReply: managerReply ?? this.managerReply,
    );
  }
}

class ManagerCommentReply {
  const ManagerCommentReply({
    required this.id,
    required this.body,
    required this.managerName,
    this.profileImage,
    this.repliedAt,
  });

  final int id;
  final String body;
  final String managerName;
  final String? profileImage;
  final DateTime? repliedAt;
}
