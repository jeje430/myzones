import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/zonez_colors.dart';
import '../../../widgets/neon_gradient_button.dart';
import '../../../widgets/rating/star_rating_row.dart';

class LoungeCard extends StatelessWidget {
  const LoungeCard({
    super.key,
    required this.loungeId,
    required this.name,
    required this.rating,
    required this.reviews,
    required this.location,
    required this.devices,
    required this.price,
    this.isFavorite = false,
    this.compact = false,
    this.onFavoriteTap,
    this.onTap,
    this.onBookTap,
  });

  final String loungeId;
  final String name;
  final double rating;
  final int reviews;
  final String location;
  final int devices;
  final int price;
  final bool isFavorite;
  final bool compact;
  final VoidCallback? onFavoriteTap;
  final VoidCallback? onTap;
  final VoidCallback? onBookTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final muted = theme.brightness == Brightness.dark
        ? ZonezColors.textMuted
        : ZonezColors.lightTextMuted;
    final accent = theme.brightness == Brightness.dark
        ? ZonezColors.neonCyan
        : ZonezColors.lightPrimary;

    final thumbSize = compact ? 52.0 : 90.0;
    final padding = compact ? 8.0 : 12.0;
    final marginBottom = compact ? 8.0 : 14.0;
    final titleSize = compact ? 13.0 : 15.0;
    final bookHeight = compact ? 30.0 : 38.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: marginBottom),
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark
              ? ZonezColors.cardDark
              : Colors.white,
          borderRadius: BorderRadius.circular(compact ? 14 : 18),
          border: Border.all(
            color: theme.brightness == Brightness.dark
                ? ZonezColors.neonPurple.withValues(alpha: 0.15)
                : ZonezColors.lightBorder,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(compact ? 10 : 12),
              child: SizedBox(
                width: thumbSize,
                height: thumbSize,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        ZonezColors.neonPurple.withValues(alpha: 0.4),
                        ZonezColors.neonCyan.withValues(alpha: 0.2),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Icon(
                    Icons.sports_esports,
                    color: onSurface.withValues(alpha: 0.45),
                    size: compact ? 24 : 36,
                  ),
                ),
              ),
            ),
            SizedBox(width: compact ? 6 : 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: titleSize,
                            fontWeight: FontWeight.bold,
                            color: onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: onFavoriteTap,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: theme.colorScheme.primary,
                            size: compact ? 17 : 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: compact ? 2 : 4),
                  Row(
                    children: [
                      Flexible(
                        child: RatingStarsDisplay(
                          rating: rating,
                          size: compact ? 10 : 14,
                          showValue: !compact,
                        ),
                      ),
                      Text(
                        '($reviews)',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: compact ? 9 : 12,
                          color: muted,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: compact ? 2 : 4),
                  _InfoRow(
                    icon: Icons.location_on_outlined,
                    text: location,
                    muted: muted,
                    size: compact ? 10 : 11,
                  ),
                  if (!compact) ...[
                    const SizedBox(height: 2),
                    _InfoRow(
                      icon: Icons.sports_esports_outlined,
                      text: '$devices جهاز متاح',
                      muted: muted,
                      size: 11,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'يبدأ من $price د.ل / ساعة',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: accent,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ] else
                    Text(
                      '$devices أجهزة · من $price د.ل',
                      style: GoogleFonts.cairo(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: accent,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            SizedBox(width: compact ? 4 : 8),
            if (compact)
              _CompactBookButton(
                height: bookHeight,
                onPressed: onBookTap ?? onTap,
              )
            else
              SizedBox(
                width: 82,
                child: NeonGradientButton(
                  label: 'احجز',
                  height: bookHeight,
                  fontSize: 14,
                  borderRadius: 12,
                  onPressed: onBookTap ?? onTap,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CompactBookButton extends StatelessWidget {
  const _CompactBookButton({
    required this.height,
    required this.onPressed,
  });

  final double height;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            gradient: isDark
                ? ZonezColors.neonGradient
                : ZonezColors.lightAccentGradient,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              'احجز',
              style: GoogleFonts.cairo(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.text,
    required this.muted,
    required this.size,
  });

  final IconData icon;
  final String text;
  final Color muted;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: size + 1, color: muted),
        const SizedBox(width: 3),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: size,
                  color: muted,
                ),
          ),
        ),
      ],
    );
  }
}
