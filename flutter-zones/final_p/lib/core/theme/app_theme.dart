import 'package:flutter/material.dart';
import 'zonez_colors.dart';
import 'zonez_typography.dart';

abstract final class AppTheme {
  static ThemeData dark() => _build(isDark: true);
  static ThemeData light() => _build(isDark: false);

  static ThemeData _build({required bool isDark}) {
    final bg = isDark ? ZonezColors.deepBlack : ZonezColors.lightBackground;
    final surface = isDark ? ZonezColors.cardDark : ZonezColors.lightSurface;
    final surfaceAlt =
        isDark ? ZonezColors.inputBg : ZonezColors.lightSurfaceAlt;
    final onBg = isDark ? Colors.white : ZonezColors.lightText;
    final onMuted = isDark ? Colors.white70 : ZonezColors.lightTextMuted;
    final primary = isDark ? ZonezColors.neonPurple : ZonezColors.lightPrimary;
    final secondary = isDark ? ZonezColors.neonCyan : ZonezColors.lightAccent;
    final muted = isDark ? ZonezColors.textMuted : ZonezColors.lightTextMuted;
    final border = isDark ? ZonezColors.borderMuted : ZonezColors.lightBorder;

    final textTheme = TextTheme(
      displayLarge: ZonezTypography.display(size: 32, color: onBg),
      displayMedium: ZonezTypography.display(size: 26, color: onBg),
      displaySmall: ZonezTypography.display(size: 22, color: onBg),
      headlineMedium: ZonezTypography.title(size: 20, color: onBg),
      headlineSmall: ZonezTypography.title(size: 18, color: onBg),
      titleLarge: ZonezTypography.title(size: 18, color: onBg),
      titleMedium: ZonezTypography.title(size: 16, color: onBg),
      titleSmall: ZonezTypography.title(size: 14, color: onBg),
      bodyLarge: ZonezTypography.body(size: 16, color: onBg),
      bodyMedium: ZonezTypography.body(size: 14, color: onBg),
      bodySmall: ZonezTypography.body(size: 12, color: onMuted),
      labelLarge: ZonezTypography.caption(size: 14, color: onBg),
      labelMedium: ZonezTypography.caption(size: 12, color: muted),
      labelSmall: ZonezTypography.caption(size: 11, color: muted),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: primary,
        onPrimary: Colors.white,
        secondary: secondary,
        onSecondary: isDark ? Colors.black : Colors.white,
        error: ZonezColors.neonRed,
        onError: Colors.white,
        surface: surface,
        onSurface: onBg,
        surfaceContainerHighest: surfaceAlt,
        onSurfaceVariant: muted,
        outline: border,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: isDark ? 0 : 2,
        shadowColor:
            isDark ? Colors.transparent : Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      iconTheme: IconThemeData(color: onBg),
      primaryIconTheme: IconThemeData(color: onBg),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: onBg,
        titleTextStyle: ZonezTypography.title(size: 20, color: onBg),
        iconTheme: IconThemeData(color: onBg),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: isDark ? ZonezColors.deepBlack : ZonezColors.lightSurface,
        surfaceTintColor: Colors.transparent,
        scrimColor: Colors.black.withValues(alpha: 0.45),
        elevation: isDark ? 8 : 2,
        shadowColor: isDark
            ? Colors.transparent
            : Colors.black.withValues(alpha: 0.08),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: ZonezTypography.title(size: 18, color: onBg),
        contentTextStyle: ZonezTypography.body(size: 14, color: onBg),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: surface,
      ),
      listTileTheme: ListTileThemeData(
        textColor: onBg,
        iconColor: primary,
        titleTextStyle: ZonezTypography.title(size: 14, color: onBg),
        subtitleTextStyle: ZonezTypography.caption(size: 11, color: muted),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: isDark ? ZonezColors.neonCyan : primary,
        unselectedLabelColor: muted,
        indicatorColor: primary,
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1),
      dividerColor: border,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? ZonezColors.inputBg : ZonezColors.lightSurfaceAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        hintStyle: ZonezTypography.caption(color: muted),
        labelStyle: ZonezTypography.body(color: onBg),
      ),
      snackBarTheme: SnackBarThemeData(
        contentTextStyle: ZonezTypography.body(color: Colors.white),
        backgroundColor: isDark ? ZonezColors.cardDark : ZonezColors.lightText,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return isDark ? ZonezColors.neonCyan : ZonezColors.lightAccent;
          }
          return null;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primary.withValues(alpha: 0.5);
          }
          return null;
        }),
      ),
    );
  }
}
