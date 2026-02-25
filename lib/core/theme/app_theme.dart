import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// "Neon Carnival on a Dark Stage" — Material 3 dark theme.
class AppTheme {
  AppTheme._();

  static final ColorScheme _colorScheme = ColorScheme(
    brightness: Brightness.dark,
    // Primary
    primary: AppColors.neonCyan,
    onPrimary: AppColors.background,
    primaryContainer: AppColors.neonCyan.withAlpha(40),
    onPrimaryContainer: AppColors.neonCyan,
    // Secondary
    secondary: AppColors.neonMagenta,
    onSecondary: AppColors.background,
    secondaryContainer: AppColors.neonMagenta.withAlpha(40),
    onSecondaryContainer: AppColors.neonMagenta,
    // Tertiary
    tertiary: AppColors.neonLime,
    onTertiary: AppColors.background,
    tertiaryContainer: AppColors.neonLime.withAlpha(40),
    onTertiaryContainer: AppColors.neonLime,
    // Error
    error: AppColors.error,
    onError: Colors.white,
    // Surfaces
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
    surfaceContainerHighest: AppColors.surfaceVariant,
    onSurfaceVariant: AppColors.textSecondary,
    outline: AppColors.textMuted,
    outlineVariant: AppColors.surfaceVariant,
    // Misc
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: AppColors.textPrimary,
    onInverseSurface: AppColors.background,
    inversePrimary: const Color(0xFF006874),
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: _colorScheme,
    scaffoldBackgroundColor: AppColors.background,
    textTheme: AppTypography.textTheme,

    // ─── App Bar ──────────────────────────────────────────────────
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
    ),

    // ─── Cards ────────────────────────────────────────────────────
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 4,
      shadowColor: AppColors.neonCyan.withAlpha(30),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),

    // ─── Elevated Button ──────────────────────────────────────────
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.neonCyan,
        foregroundColor: AppColors.background,
        minimumSize: const Size(double.infinity, 56),
        textStyle: AppTypography.textTheme.labelLarge,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),

    // ─── Outlined Button ──────────────────────────────────────────
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.neonCyan,
        side: const BorderSide(color: AppColors.neonCyan),
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),

    // ─── Text Button ─────────────────────────────────────────────
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.neonCyan),
    ),

    // ─── Input Decoration ─────────────────────────────────────────
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.neonCyan, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),

    // ─── Divider ──────────────────────────────────────────────────
    dividerTheme: const DividerThemeData(
      color: AppColors.surfaceVariant,
      thickness: 1,
    ),

    // ─── Bottom Navigation ────────────────────────────────────────
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.neonCyan.withAlpha(30),
    ),
  );
}
