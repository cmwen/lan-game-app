import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography using Google Fonts:
///   • **Fredoka One** for display / headline text (fun, rounded, party vibe)
///   • **Nunito** for body / label text (friendly, legible)
class AppTypography {
  AppTypography._();

  /// Display font for headlines and big numbers.
  static TextStyle get _display =>
      GoogleFonts.fredoka(fontWeight: FontWeight.w700);

  /// Body font for readable text.
  static TextStyle get _body => GoogleFonts.nunito();

  static TextTheme get textTheme => TextTheme(
    // ─── Display ─────────────────────────────────────────────────
    displayLarge: _display.copyWith(fontSize: 57, letterSpacing: -0.25),
    displayMedium: _display.copyWith(fontSize: 45),
    displaySmall: _display.copyWith(fontSize: 36),

    // ─── Headline ────────────────────────────────────────────────
    headlineLarge: _display.copyWith(fontSize: 32),
    headlineMedium: _display.copyWith(
      fontSize: 28,
      fontWeight: FontWeight.w600,
    ),
    headlineSmall: _display.copyWith(fontSize: 24, fontWeight: FontWeight.w600),

    // ─── Title ───────────────────────────────────────────────────
    titleLarge: _body.copyWith(fontSize: 22, fontWeight: FontWeight.w700),
    titleMedium: _body.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.15,
    ),
    titleSmall: _body.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
    ),

    // ─── Body ────────────────────────────────────────────────────
    bodyLarge: _body.copyWith(fontSize: 16),
    bodyMedium: _body.copyWith(fontSize: 14),
    bodySmall: _body.copyWith(fontSize: 12),

    // ─── Label ───────────────────────────────────────────────────
    labelLarge: _body.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.5,
    ),
    labelMedium: _body.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    ),
    labelSmall: _body.copyWith(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    ),
  );
}
