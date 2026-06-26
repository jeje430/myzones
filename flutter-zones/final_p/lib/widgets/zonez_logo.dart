import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/theme/zonez_colors.dart';
import '../providers/branding_provider.dart';
import 'branding_logo_image.dart';

class ZonezLogo extends StatelessWidget {
  const ZonezLogo({
    super.key,
    this.size = 48,
    this.showText = true,
    this.imageOnly = false,
    this.compact = false,
  });

  final double size;
  final bool showText;
  final bool imageOnly;

  /// When true, renders a larger proportional mark without a boxed background.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final branding = context.watch<BrandingProvider>();
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final imageWidth = compact ? size * 1.55 : size * 1.25;
    final imageHeight = compact ? size * 1.35 : size;

    Widget logoImage = BrandingLogoImage(
      width: imageWidth,
      height: imageHeight,
      fit: BoxFit.contain,
      showDarkGlow: isDark && !imageOnly,
    );

    if (imageOnly) {
      return logoImage;
    }

    return Row(
      mainAxisSize: showText ? MainAxisSize.max : MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        logoImage,
        if (showText) ...[
          SizedBox(width: compact ? 8 : 10),
          Expanded(
            child: Text(
              branding.platformName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.cairo(
                fontSize: size * (compact ? 0.42 : 0.45),
                fontWeight: FontWeight.bold,
                color: onSurface,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class ZonezLogoLarge extends StatelessWidget {
  const ZonezLogoLarge({super.key, this.width = 220});

  final double width;

  @override
  Widget build(BuildContext context) {
    final branding = context.watch<BrandingProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget logo = BrandingLogoImage(
      width: width * 0.78,
      fit: BoxFit.contain,
      showDarkGlow: isDark,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        logo,
        const SizedBox(height: 12),
        ShaderMask(
          shaderCallback: (bounds) => (isDark
                  ? ZonezColors.neonGradient
                  : ZonezColors.lightAccentGradient)
              .createShader(bounds),
          child: Text(
            branding.platformName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.cairo(
              fontSize: width * 0.12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
        ),
      ],
    );
  }
}
