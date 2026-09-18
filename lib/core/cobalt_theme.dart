import 'package:flutter/material.dart';

class CobaltPalette extends ThemeExtension<CobaltPalette> {
  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textHint;

  const CobaltPalette({
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
  });

  static const CobaltPalette dark = CobaltPalette(
    background: Color(0xFF0D0F12),
    surface: Color(0xFF161A20),
    surfaceElevated: Color(0xFF1E232B),
    border: Color(0xFF2A3040),
    textPrimary: Color(0xFFEEF1F6),
    textSecondary: Color(0xFF8B93A0),
    textHint: Color(0xFF4A5260),
  );

  static const CobaltPalette light = CobaltPalette(
    background: Color(0xFFF0F4FA),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFE8EDF5),
    border: Color(0xFFD0D8E8),
    textPrimary: Color(0xFF0F1419),
    textSecondary: Color(0xFF4A5568),
    textHint: Color(0xFF8A96A8),
  );

  @override
  ThemeExtension<CobaltPalette> copyWith({
    Color? background,
    Color? surface,
    Color? surfaceElevated,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? textHint,
  }) =>
      CobaltPalette(
        background: background ?? this.background,
        surface: surface ?? this.surface,
        surfaceElevated: surfaceElevated ?? this.surfaceElevated,
        border: border ?? this.border,
        textPrimary: textPrimary ?? this.textPrimary,
        textSecondary: textSecondary ?? this.textSecondary,
        textHint: textHint ?? this.textHint,
      );

  @override
  ThemeExtension<CobaltPalette> lerp(
      ThemeExtension<CobaltPalette>? other, double t) {
    if (other is! CobaltPalette) return this;
    return CobaltPalette(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated:
          Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textHint: Color.lerp(textHint, other.textHint, t)!,
    );
  }
}

extension CobaltThemeContext on BuildContext {
  CobaltPalette get ct =>
      Theme.of(this).extension<CobaltPalette>() ?? CobaltPalette.dark;
}
