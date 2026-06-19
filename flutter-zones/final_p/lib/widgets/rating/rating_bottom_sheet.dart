import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/theme/zonez_colors.dart';
import '../../models/lounge_model.dart';
import '../../models/lounge_rating.dart';
import '../../providers/lounge_ratings_provider.dart';
import '../neon_gradient_button.dart';
import 'star_rating_row.dart';

Future<bool?> showRatingBottomSheet(
  BuildContext context, {
  required LoungeModel lounge,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ChangeNotifierProvider.value(
      value: context.read<LoungeRatingsProvider>(),
      child: RatingBottomSheet(lounge: lounge),
    ),
  );
}

class RatingBottomSheet extends StatefulWidget {
  const RatingBottomSheet({super.key, required this.lounge});

  final LoungeModel lounge;

  @override
  State<RatingBottomSheet> createState() => _RatingBottomSheetState();
}

class _RatingBottomSheetState extends State<RatingBottomSheet> {
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
            style: GoogleFonts.cairo(),
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
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم إرسال التقييم بنجاح',
            style: GoogleFonts.cairo(),
            textAlign: TextAlign.center,
          ),
          backgroundColor: ZonezColors.neonCyan,
        ),
      );
    } else if (provider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error!, style: GoogleFonts.cairo()),
          backgroundColor: ZonezColors.neonRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final ratingsProvider = context.watch<LoungeRatingsProvider>();

    return Container(
      margin: const EdgeInsets.only(top: 48),
      decoration: const BoxDecoration(
        color: ZonezColors.cardDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: ZonezColors.neonPurple, width: 1.5),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: ZonezColors.textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'قيّم الصالة',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              widget.lounge.name,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 13,
                color: ZonezColors.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: widget.lounge.supportedRatingCategories
                      .map((category) => _CategoryRatingTile(
                            category: category,
                            input: _inputs[category]!,
                            onStarsChanged: (stars) {
                              setState(() {
                                _inputs[category] =
                                    _inputs[category]!.copyWith(stars: stars);
                              });
                            },
                            onCommentChanged: (comment) {
                              setState(() {
                                _inputs[category] =
                                    _inputs[category]!.copyWith(comment: comment);
                              });
                            },
                          ))
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ratingsProvider.isSubmitting
                ? const Center(
                    child: CircularProgressIndicator(color: ZonezColors.neonPurple),
                  )
                : NeonGradientButton(
                    label: 'إرسال التقييم',
                    icon: Icons.send_rounded,
                    onPressed: _submit,
                  ),
          ],
        ),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ZonezColors.inputBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: ZonezColors.neonPurple.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            category.labelAr,
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
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
            style: GoogleFonts.cairo(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'اكتب تعليقاً عن ${category.labelAr}...',
              hintStyle: GoogleFonts.cairo(
                color: ZonezColors.textMuted,
                fontSize: 12,
              ),
              filled: true,
              fillColor: ZonezColors.cardDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: ZonezColors.neonPurple.withValues(alpha: 0.2),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: ZonezColors.neonPurple.withValues(alpha: 0.2),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: ZonezColors.neonPurple),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
