import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/zonez_colors.dart';
import 'branding_logo_image.dart';

/// Centered neon platform logo + Arabic tagline for auth screens.
class AuthLogoHero extends StatelessWidget {
  const AuthLogoHero({
    super.key,
    this.logoWidth = 200,
    this.tagline = 'بوابتك لعالم الألعاب والتحدي',
  });

  final double logoWidth;
  final String tagline;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          decoration: BoxDecoration(
            boxShadow: isDark
                ? [
                    BoxShadow(
                      color: ZonezColors.neonPurple.withValues(alpha: 0.6),
                      blurRadius: 48,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: ZonezColors.neonCyan.withValues(alpha: 0.32),
                      blurRadius: 64,
                      spreadRadius: 6,
                    ),
                    BoxShadow(
                      color: ZonezColors.neonPurple.withValues(alpha: 0.18),
                      blurRadius: 90,
                      spreadRadius: 10,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: ZonezColors.lightPrimary.withValues(alpha: 0.25),
                      blurRadius: 32,
                      spreadRadius: 2,
                    ),
                  ],
          ),
          child: BrandingLogoImage(
            width: logoWidth * 0.78,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 18),
        ShaderMask(
          shaderCallback: (bounds) => (isDark
                  ? ZonezColors.neonGradient
                  : ZonezColors.lightAccentGradient)
              .createShader(bounds),
          child: Text(
            tagline,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.45,
              shadows: isDark
                  ? [
                      Shadow(
                        color: ZonezColors.neonCyan.withValues(alpha: 0.45),
                        blurRadius: 12,
                      ),
                      Shadow(
                        color: ZonezColors.neonPurple.withValues(alpha: 0.35),
                        blurRadius: 20,
                      ),
                    ]
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 56,
          height: 3,
          decoration: BoxDecoration(
            gradient: isDark
                ? ZonezColors.neonGradient
                : ZonezColors.lightAccentGradient,
            borderRadius: BorderRadius.circular(2),
            boxShadow: isDark
                ? [
                    BoxShadow(
                      color: ZonezColors.neonCyan.withValues(alpha: 0.5),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
        ),
      ],
    );
  }
}
