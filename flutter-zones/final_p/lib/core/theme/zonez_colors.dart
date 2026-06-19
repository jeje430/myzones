import 'package:flutter/material.dart';

abstract final class ZonezColors {
  static const neonPurple = Color(0xFFA020F0);
  static const neonCyan = Color(0xFF00FFFF);
  static const deepBlack = Color(0xFF000000);
  static const darkNavy = Color(0xFF08080E);
  static const cardDark = Color(0xFF12121B);
  static const inputBg = Color(0xFF1A1A24);
  static const borderMuted = Color(0xFF2A2A38);
  static const textMuted = Color(0xFF9E9EAE);
  static const neonRed = Color(0xFFFF4D6D);
  static const neonGold = Color(0xFFFFD700);

  // Premium Gaming Light Clean palette
  static const lightBackground = Color(0xFFF8F9FA);
  static const lightSurfaceAlt = Color(0xFFF3F4F6);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightPrimary = Color(0xFF6366F1);
  static const lightAccent = Color(0xFF06B6D4);
  static const lightText = Color(0xFF1F2937);
  static const lightTextMuted = Color(0xFF6B7280);
  static const lightBorder = Color(0xFFE5E7EB);
  static const deleteRed = Color(0xFFDC2626);

  static const neonGradient = LinearGradient(
    colors: [neonPurple, neonCyan],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const neonGradientVertical = LinearGradient(
    colors: [neonCyan, neonPurple],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const lightAccentGradient = LinearGradient(
    colors: [lightPrimary, lightAccent],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
