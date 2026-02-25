import 'package:flutter/material.dart';

/// "Neon Carnival on a Dark Stage" colour palette.
class AppColors {
  AppColors._();

  // ─── Primary neon accents ──────────────────────────────────────────────────
  static const Color neonCyan = Color(0xFF00E5FF); // Electric cyan
  static const Color neonMagenta = Color(0xFFFF00E5); // Hot magenta
  static const Color neonLime = Color(0xFF76FF03); // Lime green

  /// Alias used throughout the theme as the main brand colour.
  static const Color primary = neonCyan;
  static const Color secondary = neonMagenta;
  static const Color tertiary = neonLime;

  // ─── Surfaces ──────────────────────────────────────────────────────────────
  static const Color background = Color(0xFF0D0D1A); // near-black indigo
  static const Color surface = Color(0xFF1A1A2E); // dark card surface
  static const Color surfaceVariant = Color(0xFF252545); // slightly lighter
  static const Color surfaceBright = Color(0xFF2F2F55); // elevated cards

  // ─── Semantic ──────────────────────────────────────────────────────────────
  static const Color error = Color(0xFFFF5252);
  static const Color warning = Color(0xFFFFD93D);
  static const Color success = neonLime;

  // ─── Text ──────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0CC);
  static const Color textMuted = Color(0xFF6B6B8A);

  // ─── Player avatar colours (indices 0–7) ───────────────────────────────────
  static const List<Color> playerColors = [
    neonCyan, // 0 – cyan
    neonMagenta, // 1 – magenta
    neonLime, // 2 – lime
    Color(0xFFFFD93D), // 3 – yellow
    Color(0xFFFF6B6B), // 4 – coral red
    Color(0xFFFF8C00), // 5 – orange
    Color(0xFF7C4DFF), // 6 – purple
    Color(0xFF18FFFF), // 7 – aqua
  ];
}
