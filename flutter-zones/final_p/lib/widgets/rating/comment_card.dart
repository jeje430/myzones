import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../core/theme/zonez_colors.dart';
import '../../core/theme/zonez_typography.dart';
import '../../core/utils/media_url_resolver.dart';
import '../../models/lounge_comment.dart';

/// Premium dark comment card — title, body, manager reply, edit + timestamp footer.
class CommentCard extends StatelessWidget {
  const CommentCard({
    super.key,
    required this.comment,
    this.onEdit,
    this.compact = false,
  });

  final LoungeComment comment;
  final VoidCallback? onEdit;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final timestamp = comment.updatedAt;
    final dateLabel = timestamp != null
        ? DateFormat('d MMM yyyy • HH:mm', 'ar').format(timestamp.toLocal())
        : '';

    return Container(
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: ZonezColors.inputBg.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(compact ? 12 : 16),
        border: Border.all(color: ZonezColors.neonCyan.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CommentAvatar(name: comment.customerName, imageUrl: comment.profileImage),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment.customerName,
                      style: ZonezTypography.title(size: compact ? 12 : 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      comment.body,
                      style: ZonezTypography.body(size: compact ? 12 : 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (comment.managerReply != null) ...[
            const SizedBox(height: 12),
            _ManagerReplyBlock(reply: comment.managerReply!, compact: compact),
          ],
          if (dateLabel.isNotEmpty || onEdit != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: AlignmentDirectional.bottomEnd,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onEdit != null)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onEdit,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            Icons.edit,
                            size: compact ? 17 : 19,
                            color: ZonezColors.neonCyan,
                          ),
                        ),
                      ),
                    ),
                  if (onEdit != null && dateLabel.isNotEmpty) const SizedBox(width: 4),
                  if (dateLabel.isNotEmpty)
                    Text(
                      dateLabel,
                      style: ZonezTypography.caption(
                        size: compact ? 10 : 11,
                        color: ZonezColors.textMuted,
                      ),
                      textDirection: TextDirection.ltr,
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ManagerReplyBlock extends StatelessWidget {
  const _ManagerReplyBlock({required this.reply, required this.compact});

  final ManagerCommentReply reply;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsetsDirectional.only(start: 44),
      padding: EdgeInsets.all(compact ? 10 : 12),
      decoration: BoxDecoration(
        color: ZonezColors.neonPurple.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ZonezColors.neonPurple.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.support_agent, size: 14, color: ZonezColors.neonPurple),
              const SizedBox(width: 6),
              Text(
                'رد ${reply.managerName}',
                style: ZonezTypography.caption(
                  size: 11,
                  weight: FontWeight.bold,
                  color: ZonezColors.neonPurple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(reply.body, style: ZonezTypography.body(size: compact ? 11 : 12)),
        ],
      ),
    );
  }
}

class _CommentAvatar extends StatelessWidget {
  const _CommentAvatar({required this.name, this.imageUrl});

  final String name;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final resolved = MediaUrlResolver.resolve(imageUrl);
    final initials = _initials(name);

    return CircleAvatar(
      radius: 20,
      backgroundColor: ZonezColors.neonPurple.withValues(alpha: 0.3),
      backgroundImage: resolved != null && resolved.isNotEmpty ? NetworkImage(resolved) : null,
      child: resolved == null || resolved.isEmpty
          ? Text(initials, style: ZonezTypography.accent(size: 12))
          : null,
    );
  }

  String _initials(String value) {
    final parts = value.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'ز';
    if (parts.length == 1) return parts.first.characters.first;
    return '${parts.first.characters.first}${parts[1].characters.first}';
  }
}
