import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/zonez_colors.dart';

class NeonGradientButton extends StatelessWidget {
  const NeonGradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.height = 54,
    this.fontSize = 16,
    this.borderRadius = 16,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;
  final double fontSize;
  final double borderRadius;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isActive = enabled && onPressed != null;

    return Opacity(
      opacity: isActive ? 1.0 : 0.45,
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: isActive
                ? (isDark
                    ? ZonezColors.neonGradient
                    : ZonezColors.lightAccentGradient)
                : LinearGradient(
                    colors: [
                      ZonezColors.textMuted.withValues(alpha: 0.5),
                      ZonezColors.textMuted.withValues(alpha: 0.3),
                    ],
                  ),
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: (isDark ? ZonezColors.neonPurple : ZonezColors.lightPrimary)
                          .withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              disabledBackgroundColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(borderRadius),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: GoogleFonts.cairo(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
