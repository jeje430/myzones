import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/zonez_colors.dart';
import '../../../../models/map_lounge.dart';
import '../../../../widgets/neon_gradient_button.dart';

class ExploreGlassCard extends StatelessWidget {
  const ExploreGlassCard({
    super.key,
    required this.lounge,
    required this.distanceMeters,
    required this.onNavigate,
    required this.onFavoriteTap,
    required this.isFavorite,
  });

  final MapLounge lounge;
  final double distanceMeters;
  final VoidCallback onNavigate;
  final VoidCallback onFavoriteTap;
  final bool isFavorite;

  String get _distanceLabel {
    if (distanceMeters < 1000) {
      return '${distanceMeters.round()} م';
    }
    final km = distanceMeters / 1000;
    return '${km.toStringAsFixed(km >= 10 ? 0 : 1)} كم';
  }

  IconData get _categoryIcon {
    switch (lounge.category) {
      case LoungeCategory.ps5:
        return Icons.videogame_asset_rounded;
      case LoungeCategory.pc:
        return Icons.computer_rounded;
      case LoungeCategory.mixed:
        return Icons.sports_esports_rounded;
    }
  }

  Color get _categoryColor {
    switch (lounge.category) {
      case LoungeCategory.ps5:
        return ZonezColors.neonCyan;
      case LoungeCategory.pc:
        return ZonezColors.neonPurple;
      case LoungeCategory.mixed:
        return ZonezColors.neonGold;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                ZonezColors.cardDark.withValues(alpha: 0.55),
                ZonezColors.darkNavy.withValues(alpha: 0.88),
              ],
            ),
            border: Border(
              top: BorderSide(
                color: ZonezColors.neonPurple.withValues(alpha: 0.45),
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: ZonezColors.neonPurple.withValues(alpha: 0.25),
                blurRadius: 24,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: ZonezColors.textMuted.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Thumbnail(
                    imageUrl: lounge.imageUrl,
                    icon: _categoryIcon,
                    accentColor: _categoryColor,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                lounge.name,
                                style: GoogleFonts.cairo(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: onFavoriteTap,
                              icon: Icon(
                                isFavorite
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                color: isFavorite
                                    ? ZonezColors.neonRed
                                    : ZonezColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            ...List.generate(5, (index) {
                              final filled = index < lounge.rating.floor();
                              final half = !filled &&
                                  index < lounge.rating &&
                                  lounge.rating - index >= 0.5;
                              return Icon(
                                filled
                                    ? Icons.star_rounded
                                    : half
                                        ? Icons.star_half_rounded
                                        : Icons.star_outline_rounded,
                                size: 18,
                                color: ZonezColors.neonGold,
                              );
                            }),
                            const SizedBox(width: 6),
                            Text(
                              lounge.rating.toStringAsFixed(1),
                              style: GoogleFonts.cairo(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              ' (${lounge.reviews})',
                              style: GoogleFonts.cairo(
                                color: ZonezColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.place_rounded,
                              size: 16,
                              color: ZonezColors.neonCyan.withValues(alpha: 0.9),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              lounge.locationLabel,
                              style: GoogleFonts.cairo(
                                color: ZonezColors.textMuted,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.near_me_rounded,
                              size: 16,
                              color: ZonezColors.neonPurple.withValues(alpha: 0.9),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _distanceLabel,
                              style: GoogleFonts.cairo(
                                color: ZonezColors.neonCyan,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          _categoryColor.withValues(alpha: 0.45),
                          _categoryColor.withValues(alpha: 0.05),
                        ],
                      ),
                      border: Border.all(
                        color: _categoryColor.withValues(alpha: 0.7),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _categoryColor.withValues(alpha: 0.45),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: Icon(
                      _categoryIcon,
                      color: _categoryColor,
                      size: 24,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              NeonGradientButton(
                label: 'التوجه للصالة',
                icon: Icons.navigation_rounded,
                height: 48,
                onPressed: onNavigate,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({
    this.imageUrl,
    required this.icon,
    required this.accentColor,
  });

  final String? imageUrl;
  final IconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 78,
        height: 78,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ZonezColors.neonPurple.withValues(alpha: 0.55),
              ZonezColors.neonCyan.withValues(alpha: 0.25),
            ],
          ),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.55),
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.35),
              blurRadius: 12,
            ),
          ],
        ),
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                width: 78,
                height: 78,
                errorBuilder: (_, __, ___) => Icon(icon, color: Colors.white, size: 34),
              )
            : Icon(icon, color: Colors.white, size: 34),
      ),
    );
  }
}
