import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';



import '../../core/theme/zonez_colors.dart';



class StarRatingRow extends StatelessWidget {

  const StarRatingRow({

    super.key,

    required this.rating,

    required this.onChanged,

    this.starSize = 32,

    this.readOnly = false,

  });



  final int rating;

  final ValueChanged<int> onChanged;

  final double starSize;

  final bool readOnly;



  @override

  Widget build(BuildContext context) {

    final muted = Theme.of(context).brightness == Brightness.dark

        ? ZonezColors.textMuted

        : ZonezColors.lightTextMuted;



    return Row(

      mainAxisAlignment: MainAxisAlignment.center,

      children: List.generate(5, (index) {

        final starValue = index + 1;

        final filled = starValue <= rating;

        return GestureDetector(

          onTap: readOnly ? null : () => onChanged(starValue),

          child: Padding(

            padding: const EdgeInsets.symmetric(horizontal: 4),

            child: Icon(

              filled ? Icons.star_rounded : Icons.star_border_rounded,

              color: filled ? ZonezColors.neonGold : muted,

              size: starSize,

            ),

          ),

        );

      }),

    );

  }

}



class RatingStarsDisplay extends StatelessWidget {

  const RatingStarsDisplay({

    super.key,

    required this.rating,

    this.size = 14,

    this.showValue = true,

  });



  final double rating;

  final double size;

  final bool showValue;



  @override

  Widget build(BuildContext context) {

    final muted = Theme.of(context).brightness == Brightness.dark

        ? ZonezColors.textMuted

        : ZonezColors.lightTextMuted;



    return Row(

      mainAxisSize: MainAxisSize.min,

      children: [

        ...List.generate(5, (i) {

          final filled = i < rating.floor();

          final half = !filled && i < rating;

          return Icon(

            filled

                ? Icons.star

                : half

                    ? Icons.star_half

                    : Icons.star_border,

            color: filled || half ? ZonezColors.neonGold : muted,

            size: size,

          );

        }),

        if (showValue) ...[

          const SizedBox(width: 4),

          Text(

            rating.toStringAsFixed(1),

            style: GoogleFonts.cairo(

              fontSize: size,

              fontWeight: FontWeight.bold,

              color: ZonezColors.neonGold,

            ),

          ),

        ],

      ],

    );

  }

}

