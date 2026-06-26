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
    this.imageUrl,
    this.services = const [],
    this.workHoursLabel,
    this.distanceLabel,
    this.isFavorite = false,
    this.compact = false,
    this.onFavoriteTap,
    this.onTap,
    this.onBookTap,
    this.removeOuterMargin = false,
  });

  final String loungeId;
  final String name;
  final double rating;
  final int reviews;
  final String location;
  final int devices;
  final int price;
  final String? imageUrl;
  final List<String> services;
  final String? workHoursLabel;
  final String? distanceLabel;
  final bool isFavorite;
  final bool compact;
  final VoidCallback? onFavoriteTap;
  final VoidCallback? onTap;
  final VoidCallback? onBookTap;
  final bool removeOuterMargin;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _CompactLoungeCard(
        loungeId: loungeId,
        name: name,
        rating: rating,
        reviews: reviews,
        location: location,
        devices: devices,
        price: price,
        imageUrl: imageUrl,
        services: services,
        workHoursLabel: workHoursLabel,
        distanceLabel: distanceLabel,
        isFavorite: isFavorite,
        onFavoriteTap: onFavoriteTap,
        onTap: onTap,
        onBookTap: onBookTap,
        removeOuterMargin: removeOuterMargin,
      );
    }

    return _VerticalLoungeCard(
      loungeId: loungeId,
      name: name,
      rating: rating,
      reviews: reviews,
      location: location,
      devices: devices,
      price: price,
      imageUrl: imageUrl,
      services: services,
      workHoursLabel: workHoursLabel,
      distanceLabel: distanceLabel,
      onFavoriteTap: onFavoriteTap,
      onTap: onTap,
      onBookTap: onBookTap,
    );
  }
}

class _VerticalLoungeCard extends StatelessWidget {
  const _VerticalLoungeCard({
    required this.loungeId,
    required this.name,
    required this.rating,
    required this.reviews,
    required this.location,
    required this.devices,
    required this.price,
    this.imageUrl,
    this.services = const [],
    this.workHoursLabel,
    this.distanceLabel,
    this.isFavorite = false,
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
  final String? imageUrl;
  final List<String> services;
  final String? workHoursLabel;
  final String? distanceLabel;
  final bool isFavorite;
  final VoidCallback? onFavoriteTap;
  final VoidCallback? onTap;
  final VoidCallback? onBookTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    final muted = isDark ? ZonezColors.textMuted : ZonezColors.lightTextMuted;
    final accent = isDark ? ZonezColors.neonCyan : ZonezColors.lightPrimary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isDark ? ZonezColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? ZonezColors.neonPurple.withValues(alpha: 0.18)
                : ZonezColors.lightBorder,
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 168,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _HeroImage(imageUrl: imageUrl, onSurface: onSurface),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(999),
                      child: InkWell(
                        onTap: onFavoriteTap,
                        borderRadius: BorderRadius.circular(999),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite
                                ? ZonezColors.neonRed
                                : Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Flexible(
                        child: RatingStarsDisplay(
                          rating: rating,
                          size: 14,
                          showValue: true,
                        ),
                      ),
                      Text(
                        '($reviews)',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          color: muted,
                        ),
                      ),
                    ],
                  ),
                  if (services.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: services
                          .take(4)
                          .map((s) => _ServiceChip(label: s))
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 10),
                  _InfoRow(
                    icon: Icons.location_on_outlined,
                    text: location,
                    muted: muted,
                    size: 11,
                  ),
                  if (distanceLabel != null && distanceLabel!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    _InfoRow(
                      icon: Icons.near_me_outlined,
                      text: distanceLabel!,
                      muted: muted,
                      size: 11,
                    ),
                  ],
                  if (workHoursLabel != null && workHoursLabel!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    _InfoRow(
                      icon: Icons.schedule_outlined,
                      text: workHoursLabel!,
                      muted: muted,
                      size: 11,
                    ),
                  ],
                  const SizedBox(height: 4),
                  _InfoRow(
                    icon: Icons.sports_esports_outlined,
                    text: '$devices جهاز متاح',
                    muted: muted,
                    size: 11,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'يبدأ من $price د.ل / ساعة',
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: accent,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(
                        width: 92,
                        child: NeonGradientButton(
                          label: 'احجز',
                          height: 38,
                          fontSize: 14,
                          borderRadius: 12,
                          onPressed: onBookTap ?? onTap,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactLoungeCard extends StatelessWidget {
  const _CompactLoungeCard({
    required this.loungeId,
    required this.name,
    required this.rating,
    required this.reviews,
    required this.location,
    required this.devices,
    required this.price,
    this.imageUrl,
    this.services = const [],
    this.workHoursLabel,
    this.distanceLabel,
    this.isFavorite = false,
    this.onFavoriteTap,
    this.onTap,
    this.onBookTap,
    this.removeOuterMargin = false,
  });

  final String loungeId;
  final String name;
  final double rating;
  final int reviews;
  final String location;
  final int devices;
  final int price;
  final String? imageUrl;
  final List<String> services;
  final String? workHoursLabel;
  final String? distanceLabel;
  final bool isFavorite;
  final VoidCallback? onFavoriteTap;
  final VoidCallback? onTap;
  final VoidCallback? onBookTap;
  final bool removeOuterMargin;

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

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: removeOuterMargin
            ? EdgeInsets.zero
            : const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark
              ? ZonezColors.cardDark
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.brightness == Brightness.dark
                ? ZonezColors.neonPurple.withValues(alpha: 0.15)
                : ZonezColors.lightBorder,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 120,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _HeroImage(imageUrl: imageUrl, onSurface: onSurface),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(999),
                      child: InkWell(
                        onTap: onFavoriteTap,
                        borderRadius: BorderRadius.circular(999),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite
                                ? ZonezColors.neonRed
                                : Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Flexible(
                        child: RatingStarsDisplay(
                          rating: rating,
                          size: 10,
                          showValue: false,
                        ),
                      ),
                      Text(
                        '($reviews)',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 9,
                          color: muted,
                        ),
                      ),
                    ],
                  ),
                  if (services.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: services
                          .take(3)
                          .map((s) => _ServiceChip(label: s, compact: true))
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 6),
                  _InfoRow(
                    icon: Icons.location_on_outlined,
                    text: location,
                    muted: muted,
                    size: 10,
                  ),
                  if (distanceLabel != null && distanceLabel!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    _InfoRow(
                      icon: Icons.near_me_outlined,
                      text: distanceLabel!,
                      muted: muted,
                      size: 10,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$devices أجهزة · من $price د.ل',
                          style: GoogleFonts.cairo(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: accent,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _CompactBookButton(
                        height: 30,
                        onPressed: onBookTap ?? onTap,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage({
    required this.imageUrl,
    required this.onSurface,
  });

  final String? imageUrl;
  final Color onSurface;

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(onSurface),
      );
    }

    return _placeholder(onSurface);
  }
}

Widget _placeholder(Color onSurface) {
  return DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          ZonezColors.neonPurple.withValues(alpha: 0.45),
          ZonezColors.neonCyan.withValues(alpha: 0.25),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Center(
      child: Icon(
        Icons.sports_esports,
        color: onSurface.withValues(alpha: 0.45),
        size: 40,
      ),
    ),
  );
}

class _ServiceChip extends StatelessWidget {
  const _ServiceChip({
    required this.label,
    this.compact = false,
  });

  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 9,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? ZonezColors.neonPurple.withValues(alpha: 0.18)
            : ZonezColors.lightPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isDark
              ? ZonezColors.neonPurple.withValues(alpha: 0.35)
              : ZonezColors.lightPrimary.withValues(alpha: 0.25),
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.cairo(
          fontSize: compact ? 9 : 10,
          fontWeight: FontWeight.w600,
          color: isDark ? ZonezColors.neonCyan : ZonezColors.lightPrimary,
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
