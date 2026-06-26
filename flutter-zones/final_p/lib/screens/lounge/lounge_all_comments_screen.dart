import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '../../core/theme/zonez_colors.dart';
import '../../core/theme/zonez_typography.dart';
import '../../data/repositories/lounge_catalog_repository.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import '../../models/lounge_comment.dart';
import '../../models/lounge_model.dart';
import '../../models/paginated_comments.dart';
import '../../providers/lounge_ratings_provider.dart';
import '../../widgets/circuit_background.dart';
import '../../widgets/rating/comment_card.dart';
import '../../widgets/rating/comments_pagination_bar.dart';
import '../../widgets/zonez_screen.dart';

const int _kCommentsPerPage = 8;

class LoungeAllCommentsScreen extends StatefulWidget {
  const LoungeAllCommentsScreen({super.key, required this.lounge});

  final LoungeModel lounge;

  @override
  State<LoungeAllCommentsScreen> createState() => _LoungeAllCommentsScreenState();
}

class _LoungeAllCommentsScreenState extends State<LoungeAllCommentsScreen> {
  final _scrollController = ScrollController();
  final _editController = TextEditingController();

  bool _loading = true;
  bool _pageLoading = false;
  String? _error;
  int _currentPage = 1;
  PaginatedComments? _pageData;
  int? _editingCommentId;

  @override
  void initState() {
    super.initState();
    _loadPage(1);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _editController.dispose();
    super.dispose();
  }

  Future<void> _loadPage(int page) async {
    setState(() {
      _pageLoading = true;
      if (_pageData == null) _loading = true;
      _error = null;
    });

    try {
      final result = await LoungeCatalogRepository.instance.fetchCommentsPage(
        loungeId: widget.lounge.id,
        page: page,
        perPage: _kCommentsPerPage,
      );
      if (!mounted) return;
      setState(() {
        _pageData = result;
        _currentPage = page;
        _loading = false;
        _pageLoading = false;
      });
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
        _pageLoading = false;
      });
    }
  }

  Future<void> _submitEdit() async {
    if (_editingCommentId == null) return;
    final text = _editController.text.trim();
    if (text.isEmpty) return;

    final provider = context.read<LoungeRatingsProvider>();
    final success = await provider.updateComment(
      loungeId: widget.lounge.id,
      commentId: _editingCommentId!,
      body: text,
    );

    if (!mounted) return;
    if (success) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      setState(() {
        _editingCommentId = null;
      });
      _editController.clear();
      await _loadPage(_currentPage);
      _showSnack('تم تحديث التعليق');
    } else if (provider.error != null) {
      _showSnack(provider.error!, isError: true);
    }
  }

  void _openEditSheet(LoungeComment comment) {
    _editingCommentId = comment.id;
    _editController.text = comment.body;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: ZonezColors.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.paddingOf(context).bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('تعديل التعليق', style: ZonezTypography.title(size: 16)),
              const SizedBox(height: 12),
              TextField(
                controller: _editController,
                maxLines: 4,
                style: ZonezTypography.body(size: 13, color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: ZonezColors.inputBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _submitEdit,
                style: FilledButton.styleFrom(backgroundColor: ZonezColors.neonPurple),
                child: const Text('حفظ التعديل'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center),
        backgroundColor: isError ? ZonezColors.neonRed : ZonezColors.neonCyan,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final meta = _pageData?.meta;
    final comments = _pageData?.comments ?? [];
    final currentUserId = context.watch<AuthBloc>().currentUser?.id;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('كل التعليقات', style: ZonezTypography.title(size: 17)),
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          const CircuitBackground(),
          ZonezScreen(
            top: false,
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: ZonezColors.neonPurple))
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_error!, style: ZonezTypography.caption(), textAlign: TextAlign.center),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: () => _loadPage(_currentPage),
                              child: const Text('إعادة المحاولة'),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          Expanded(
                            child: ListView.separated(
                              controller: _scrollController,
                              padding: const EdgeInsets.fromLTRB(20, 100, 20, 12),
                              itemCount: comments.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final comment = comments[index];
                                return CommentCard(
                                  comment: comment,
                                  onEdit: comment.isEditableBy(currentUserId: currentUserId)
                                      ? () => _openEditSheet(comment)
                                      : null,
                                );
                              },
                            ),
                          ),
                          if (meta != null)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                              child: CommentsPaginationBar(
                                meta: meta,
                                isLoading: _pageLoading,
                                onPageSelected: _loadPage,
                              ),
                            ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}
