import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/theme/zonez_colors.dart';

class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.blurSigma = 12,
    this.gradient,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final double blurSigma;
  final Gradient? gradient;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? ZonezColors.neonPurple : ZonezColors.lightPrimary;

    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            gradient: gradient ??
                LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          ZonezColors.cardDark.withValues(alpha: 0.85),
                          ZonezColors.inputBg.withValues(alpha: 0.75),
                        ]
                      : [
                          ZonezColors.lightSurface.withValues(alpha: 0.95),
                          ZonezColors.lightSurfaceAlt.withValues(alpha: 0.9),
                        ],
                ),
            borderRadius: borderRadius,
            border: Border.all(
              color: borderColor ?? primary.withValues(alpha: isDark ? 0.35 : 0.2),
            ),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: child,
        ),
      ),
    );
  }
}
