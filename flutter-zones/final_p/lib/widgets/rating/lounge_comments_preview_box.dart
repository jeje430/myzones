import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '../../core/theme/zonez_colors.dart';
import '../../core/theme/zonez_typography.dart';
import '../../data/repositories/lounge_catalog_repository.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import '../../models/lounge_comment.dart';
import '../../models/lounge_model.dart';
import '../../providers/lounge_ratings_provider.dart';
import '../glass_container.dart';
import '../neon_gradient_button.dart';
import 'comment_card.dart';
import '../../screens/lounge/lounge_all_comments_screen.dart';

const int _kPreviewCommentCount = 4;

/// Hall details — last 4 comments + compose + link to full list.
class LoungeCommentsPreviewBox extends StatefulWidget {
  const LoungeCommentsPreviewBox({super.key, required this.lounge});

  final LoungeModel lounge;

  @override
  State<LoungeCommentsPreviewBox> createState() => _LoungeCommentsPreviewBoxState();
}

class _LoungeCommentsPreviewBoxState extends State<LoungeCommentsPreviewBox> {
  final _controller = TextEditingController();
  int? _editingCommentId;
  bool _loadingPreview = true;
  List<LoungeComment> _recentComments = [];
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadRecent();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadRecent() async {
    setState(() {
      _loadingPreview = true;
      _loadError = null;
    });

    try {
      final page = await LoungeCatalogRepository.instance.fetchCommentsPage(
        loungeId: widget.lounge.id,
        page: 1,
        perPage: _kPreviewCommentCount,
      );
      if (!mounted) return;
      setState(() {
        _recentComments = page.comments;
        _loadingPreview = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _loadingPreview = false;
      });
    }
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
      await _loadRecent();
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

  void _openAllComments() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LoungeAllCommentsScreen(lounge: widget.lounge),
      ),
    ).then((_) => _loadRecent());
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
    final currentUserId = context.watch<AuthBloc>().currentUser?.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(
          icon: Icons.chat_bubble_outline,
          title: 'التعليقات',
          subtitle: 'آخر آراء اللاعبين عن الصالة',
        ),
        const SizedBox(height: 12),
        GlassContainer(
          padding: const EdgeInsets.all(16),
          borderColor: ZonezColors.neonCyan.withValues(alpha: 0.25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('تعليقات الزبائن', style: ZonezTypography.title(size: 15)),
                  ),
                  TextButton(
                    onPressed: _openAllComments,
                    child: Text(
                      'مشاهدة كل التعليقات',
                      style: ZonezTypography.caption(
                        size: 12,
                        weight: FontWeight.bold,
                        color: ZonezColors.neonCyan,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_loadingPreview)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: CircularProgressIndicator(color: ZonezColors.neonPurple),
                  ),
                )
              else if (_loadError != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    children: [
                      Text(_loadError!, style: ZonezTypography.caption(), textAlign: TextAlign.center),
                      const SizedBox(height: 8),
                      TextButton(onPressed: _loadRecent, child: const Text('إعادة المحاولة')),
                    ],
                  ),
                )
              else if (_recentComments.isEmpty)
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
                  itemCount: _recentComments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final comment = _recentComments[index];
                    return CommentCard(
                      compact: true,
                      comment: comment,
                      onEdit: comment.isEditableBy(currentUserId: currentUserId)
                          ? () => _startEdit(comment)
                          : null,
                    );
                  },
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
