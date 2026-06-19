import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'zonez_colors.dart';

/// Central typography helper — Cairo for premium Arabic gaming UI.
abstract final class ZonezTypography {
  static Color _onSurface(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;

  static Color _muted(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? ZonezColors.textMuted
          : ZonezColors.lightTextMuted;

  static Color _body(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? Colors.white70
          : ZonezColors.lightText;

  static TextStyle display({
    double size = 22,
    Color? color,
    FontWeight weight = FontWeight.bold,
    BuildContext? context,
  }) =>
      GoogleFonts.cairo(
        fontSize: size,
        fontWeight: weight,
        color: color ?? (context != null ? _onSurface(context) : Colors.white),
        height: 1.3,
      );

  static TextStyle title({
    double size = 18,
    Color? color,
    FontWeight weight = FontWeight.bold,
    BuildContext? context,
  }) =>
      GoogleFonts.cairo(
        fontSize: size,
        fontWeight: weight,
        color: color ?? (context != null ? _onSurface(context) : Colors.white),
      );

  static TextStyle body({
    double size = 14,
    Color? color,
    FontWeight weight = FontWeight.normal,
    BuildContext? context,
  }) =>
      GoogleFonts.cairo(
        fontSize: size,
        fontWeight: weight,
        color: color ?? (context != null ? _body(context) : Colors.white70),
        height: 1.5,
      );

  static TextStyle caption({
    double size = 12,
    Color? color,
    FontWeight weight = FontWeight.w500,
    BuildContext? context,
  }) =>
      GoogleFonts.cairo(
        fontSize: size,
        fontWeight: weight,
        color: color ?? (context != null ? _muted(context) : ZonezColors.textMuted),
      );

  static TextStyle accent({
    double size = 14,
    FontWeight weight = FontWeight.w600,
    Color? color,
    BuildContext? context,
  }) {
    final fallback = context != null
        ? (Theme.of(context).brightness == Brightness.dark
            ? ZonezColors.neonCyan
            : ZonezColors.lightPrimary)
        : ZonezColors.neonCyan;
    return GoogleFonts.cairo(
      fontSize: size,
      fontWeight: weight,
      color: color ?? fallback,
    );
  }

  static TextTheme textTheme({required Color onSurface}) =>
      GoogleFonts.cairoTextTheme().apply(
        bodyColor: onSurface,
        displayColor: onSurface,
      );
}
