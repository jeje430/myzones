import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../core/theme/zonez_colors.dart';
import '../../core/theme/zonez_typography.dart';
import '../../core/utils/media_url_resolver.dart';
import '../../models/lounge_comment.dart';
import '../../models/lounge_model.dart';
import '../../providers/lounge_ratings_provider.dart';
import '../glass_container.dart';
import '../neon_gradient_button.dart';

/// Dedicated comments section — list + write/edit, separate from ratings.
class LoungeCommentsBox extends StatefulWidget {
  const LoungeCommentsBox({super.key, required this.lounge});

  final LoungeModel lounge;

  @override
  State<LoungeCommentsBox> createState() => _LoungeCommentsBoxState();
}

class _LoungeCommentsBoxState extends State<LoungeCommentsBox> {
  final _controller = TextEditingController();
  int? _editingCommentId;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      _showSnack('يرجى كتابة تعليق', isError: true);
      return;
    }

    final provider = context.read<LoungeRatingsProvider>();
    final wasEditing = _editingCommentId != null;
    final success = wasEditing
        ? await provider.updateComment(
            loungeId: widget.lounge.id,
            commentId: _editingCommentId!,
            body: text,
          )
        : await provider.submitComment(
            loungeId: widget.lounge.id,
            body: text,
          );

    if (!mounted) return;

    if (success) {
      _controller.clear();
      setState(() => _editingCommentId = null);
      _showSnack(wasEditing ? 'تم تحديث التعليق' : 'تم إرسال التعليق');
    } else if (provider.error != null) {
      _showSnack(provider.error!, isError: true);
    }
  }

  void _startEdit(LoungeComment comment) {
    setState(() {
      _editingCommentId = comment.id;
      _controller.text = comment.body;
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingCommentId = null;
      _controller.clear();
    });
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: ZonezTypography.body(), textAlign: TextAlign.center),
        backgroundColor: isError ? ZonezColors.neonRed : ZonezColors.neonCyan,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LoungeRatingsProvider>();
    final comments = provider.commentsForLounge(widget.lounge.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(
          icon: Icons.chat_bubble_outline,
          title: 'التعليقات',
          subtitle: 'شارك رأيك أو اقرأ تجارب اللاعبين',
        ),
        const SizedBox(height: 12),
        GlassContainer(
          padding: const EdgeInsets.all(16),
          borderColor: ZonezColors.neonCyan.withValues(alpha: 0.25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('تعليقات الزبائن', style: ZonezTypography.title(size: 15)),
              const SizedBox(height: 12),
              if (comments.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'لا توجد تعليقات بعد — كن أول من يشارك!',
                    textAlign: TextAlign.center,
                    style: ZonezTypography.caption(),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: comments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => _CommentCard(
                    comment: comments[index],
                    onEdit: comments[index].canEdit ? () => _startEdit(comments[index]) : null,
                  ),
                ),
              const SizedBox(height: 16),
              if (_editingCommentId != null)
                Row(
                  children: [
                    Text('تعديل التعليق', style: ZonezTypography.caption(color: ZonezColors.neonCyan)),
                    const Spacer(),
                    TextButton(onPressed: _cancelEdit, child: const Text('إلغاء')),
                  ],
                ),
              TextField(
                controller: _controller,
                maxLines: 3,
                style: ZonezTypography.body(size: 13, color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'اكتب تعليقك هنا...',
                  hintStyle: ZonezTypography.caption(size: 12),
                  filled: true,
                  fillColor: ZonezColors.inputBg,
                  contentPadding: const EdgeInsets.all(14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: ZonezColors.neonPurple.withValues(alpha: 0.25)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: ZonezColors.neonPurple.withValues(alpha: 0.25)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: ZonezColors.neonCyan),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              provider.isSubmittingComment
                  ? const Center(child: CircularProgressIndicator(color: ZonezColors.neonPurple))
                  : NeonGradientButton(
                      label: _editingCommentId != null ? 'تحديث التعليق' : 'إرسال التعليق',
                      icon: Icons.send_rounded,
                      onPressed: _submit,
                    ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CommentCard extends StatelessWidget {
  const _CommentCard({required this.comment, this.onEdit});

  final LoungeComment comment;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final date = comment.submittedAt;
    final dateLabel = date != null
        ? DateFormat('d MMM yyyy • HH:mm', 'ar').format(date.toLocal())
        : '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ZonezColors.inputBg.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ZonezColors.neonCyan.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Avatar(name: comment.customerName, imageUrl: comment.profileImage),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            comment.customerName,
                            style: ZonezTypography.title(size: 13),
                          ),
                        ),
                        if (dateLabel.isNotEmpty)
                          Text(dateLabel, style: ZonezTypography.caption(size: 10)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(comment.body, style: ZonezTypography.body(size: 13)),
                    if (comment.editedAt != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('(معدّل)', style: ZonezTypography.caption(size: 10)),
                      ),
                    if (onEdit != null)
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: TextButton.icon(
                          onPressed: onEdit,
                          icon: const Icon(Icons.edit_outlined, size: 14),
                          label: Text('تعديل', style: ZonezTypography.caption(size: 11)),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (comment.managerReply != null) ...[
            const SizedBox(height: 12),
            Container(
              margin: const EdgeInsetsDirectional.only(start: 44),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ZonezColors.neonPurple.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ZonezColors.neonPurple.withValues(alpha: 0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.support_agent, size: 14, color: ZonezColors.neonPurple),
                      const SizedBox(width: 6),
                      Text(
                        'رد ${comment.managerReply!.managerName}',
                        style: ZonezTypography.caption(
                          size: 11,
                          weight: FontWeight.bold,
                          color: ZonezColors.neonPurple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(comment.managerReply!.body, style: ZonezTypography.body(size: 12)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, this.imageUrl});

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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: ZonezColors.neonGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: ZonezTypography.title()),
              Text(subtitle, style: ZonezTypography.caption()),
            ],
          ),
        ),
      ],
    );
  }
}
