import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/zonez_colors.dart';
import '../../core/theme/zonez_typography.dart';
import '../../models/lounge_model.dart';
import '../../models/lounge_rating.dart';
import '../../providers/lounge_ratings_provider.dart';
import '../glass_container.dart';
import '../neon_gradient_button.dart';
import 'star_rating_row.dart';

/// Integrated split-layout: read reviews (Section A) + write & rate (Section B).
class LoungeReviewsPanel extends StatefulWidget {
  const LoungeReviewsPanel({super.key, required this.lounge});

  final LoungeModel lounge;

  @override
  State<LoungeReviewsPanel> createState() => _LoungeReviewsPanelState();
}

class _LoungeReviewsPanelState extends State<LoungeReviewsPanel> {
  RatingCategory? _filterCategory;
  late final Map<RatingCategory, CategoryRatingInput> _inputs;

  @override
  void initState() {
    super.initState();
    _inputs = {
      for (final category in widget.lounge.supportedRatingCategories)
        category: CategoryRatingInput(category: category),
    };
  }

  Future<void> _submit() async {
    final validCategories =
        _inputs.values.where((input) => input.isValid).toList();

    if (validCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'يرجى تقييم فئة واحدة على الأقل',
            style: ZonezTypography.body(),
            textAlign: TextAlign.center,
          ),
          backgroundColor: ZonezColors.neonRed,
        ),
      );
      return;
    }

    final provider = context.read<LoungeRatingsProvider>();
    final success = await provider.submitRating(
      loungeId: widget.lounge.id,
      categories: validCategories,
    );

    if (!mounted) return;

    if (success) {
      setState(() {
        for (final category in widget.lounge.supportedRatingCategories) {
          _inputs[category] = CategoryRatingInput(category: category);
        }
      });
      provider.refreshLounges();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم إرسال التقييم بنجاح',
            style: ZonezTypography.body(),
            textAlign: TextAlign.center,
          ),
          backgroundColor: ZonezColors.neonCyan,
        ),
      );
    } else if (provider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error!, style: ZonezTypography.body()),
          backgroundColor: ZonezColors.neonRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ratingsProvider = context.watch<LoungeRatingsProvider>();
    final reviews = ratingsProvider.reviewsForLounge(
      widget.lounge.id,
      category: _filterCategory,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(
          icon: Icons.forum_outlined,
          title: 'التقييمات والمراجعات',
          subtitle: 'اقرأ آراء اللاعبين أو شارك تجربتك',
        ),
        const SizedBox(height: 16),
        _ReadReviewsSection(
          lounge: widget.lounge,
          reviews: reviews,
          filterCategory: _filterCategory,
          onFilterChanged: (category) {
            setState(() => _filterCategory = category);
          },
        ),
        const SizedBox(height: 24),
        _SectionHeader(
          icon: Icons.rate_review_outlined,
          title: 'قيّم واكتب مراجعتك',
          subtitle: 'اختر النجوم لكل فئة واكتب تعليقك مباشرة',
        ),
        const SizedBox(height: 12),
        _WriteReviewSection(
          lounge: widget.lounge,
          inputs: _inputs,
          isSubmitting: ratingsProvider.isSubmitting,
          onStarsChanged: (category, stars) {
            setState(() {
              _inputs[category] = _inputs[category]!.copyWith(stars: stars);
            });
          },
          onCommentChanged: (category, comment) {
            setState(() {
              _inputs[category] =
                  _inputs[category]!.copyWith(comment: comment);
            });
          },
          onSubmit: _submit,
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

class _ReadReviewsSection extends StatelessWidget {
  const _ReadReviewsSection({
    required this.lounge,
    required this.reviews,
    required this.filterCategory,
    required this.onFilterChanged,
  });

  final LoungeModel lounge;
  final List<StoredCategoryRating> reviews;
  final RatingCategory? filterCategory;
  final ValueChanged<RatingCategory?> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('قراءة المراجعات', style: ZonezTypography.title(size: 16)),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'الكل',
                  selected: filterCategory == null,
                  onTap: () => onFilterChanged(null),
                ),
                ...lounge.supportedRatingCategories.map(
                  (category) => _FilterChip(
                    label: category.labelAr,
                    selected: filterCategory == category,
                    onTap: () => onFilterChanged(category),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (reviews.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'لا توجد مراجعات في هذه الفئة بعد',
                textAlign: TextAlign.center,
                style: ZonezTypography.caption(),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: reviews.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) =>
                  _ReviewCard(review: reviews[index]),
            ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: selected ? ZonezColors.neonGradient : null,
              color: selected ? null : ZonezColors.inputBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected
                    ? Colors.transparent
                    : ZonezColors.neonPurple.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              label,
              style: ZonezTypography.caption(
                size: 12,
                weight: FontWeight.bold,
                color: selected ? Colors.white : ZonezColors.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});

  final StoredCategoryRating review;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ZonezColors.inputBg.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: ZonezColors.neonCyan.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: ZonezColors.neonPurple.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  review.category.labelAr,
                  style: ZonezTypography.caption(
                    size: 11,
                    color: ZonezColors.neonPurple,
                    weight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              RatingStarsDisplay(
                rating: review.stars.toDouble(),
                size: 14,
                showValue: false,
              ),
            ],
          ),
          if (review.hasComment) ...[
            const SizedBox(height: 10),
            Text(
              review.comment,
              style: ZonezTypography.body(size: 13),
            ),
          ],
        ],
      ),
    );
  }
}

class _WriteReviewSection extends StatelessWidget {
  const _WriteReviewSection({
    required this.lounge,
    required this.inputs,
    required this.isSubmitting,
    required this.onStarsChanged,
    required this.onCommentChanged,
    required this.onSubmit,
  });

  final LoungeModel lounge;
  final Map<RatingCategory, CategoryRatingInput> inputs;
  final bool isSubmitting;
  final void Function(RatingCategory category, int stars) onStarsChanged;
  final void Function(RatingCategory category, String comment) onCommentChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderColor: ZonezColors.neonCyan.withValues(alpha: 0.3),
      gradient: LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          ZonezColors.neonPurple.withValues(alpha: 0.12),
          ZonezColors.cardDark.withValues(alpha: 0.9),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...lounge.supportedRatingCategories.map(
            (category) => _CategoryRatingTile(
              category: category,
              input: inputs[category]!,
              onStarsChanged: (stars) => onStarsChanged(category, stars),
              onCommentChanged: (comment) =>
                  onCommentChanged(category, comment),
            ),
          ),
          const SizedBox(height: 8),
          isSubmitting
              ? const Center(
                  child: CircularProgressIndicator(color: ZonezColors.neonPurple),
                )
              : NeonGradientButton(
                  label: 'إرسال التقييم',
                  icon: Icons.send_rounded,
                  onPressed: onSubmit,
                ),
        ],
      ),
    );
  }
}

class _CategoryRatingTile extends StatelessWidget {
  const _CategoryRatingTile({
    required this.category,
    required this.input,
    required this.onStarsChanged,
    required this.onCommentChanged,
  });

  final RatingCategory category;
  final CategoryRatingInput input;
  final ValueChanged<int> onStarsChanged;
  final ValueChanged<String> onCommentChanged;

  @override
  Widget build(BuildContext context) {
    final hasRating = input.stars > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ZonezColors.inputBg.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasRating
              ? ZonezColors.neonPurple.withValues(alpha: 0.5)
              : ZonezColors.borderMuted.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            category.labelAr,
            style: ZonezTypography.title(size: 14),
          ),
          const SizedBox(height: 10),
          StarRatingRow(
            rating: input.stars,
            onChanged: onStarsChanged,
            starSize: 28,
          ),
          const SizedBox(height: 10),
          TextField(
            onChanged: onCommentChanged,
            maxLines: 2,
            style: ZonezTypography.body(size: 13, color: Colors.white),
            decoration: InputDecoration(
              hintText: 'اكتب تعليقاً عن ${category.labelAr}...',
              hintStyle: ZonezTypography.caption(size: 12),
              filled: true,
              fillColor: ZonezColors.cardDark.withValues(alpha: 0.8),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: ZonezColors.neonPurple.withValues(alpha: 0.2),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: ZonezColors.neonPurple.withValues(alpha: 0.2),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: ZonezColors.neonCyan),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
