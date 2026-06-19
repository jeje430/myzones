import 'package:flutter/material.dart';
import '../core/theme/zonez_colors.dart';

class NeonGradientBorder extends StatelessWidget {
  const NeonGradientBorder({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.padding = 1.5,
  });

  final Widget child;
  final double borderRadius;
  final double padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: ZonezColors.neonGradient,
        boxShadow: [
          BoxShadow(
            color: ZonezColors.neonPurple.withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: 1,
          ),
        ],
      ),
      padding: EdgeInsets.all(padding),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? ZonezColors.cardDark.withValues(alpha: 0.95)
              : Colors.white,
          borderRadius: BorderRadius.circular(borderRadius - padding),
        ),
        child: child,
      ),
    );
  }
}
