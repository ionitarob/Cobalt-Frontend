import 'package:flutter/painting.dart';

// Theme-sensitive colors → use context.ct (see cobalt_theme.dart)
// Brand colors below are constant in both modes:
abstract final class CobaltColors {
  static const Color cobalt = Color(0xFF0047AB);
  static const Color cobaltLight = Color(0xFF1A6FDB);
  static const Color cobaltGlow = Color(0x660047AB);
  static const Color background = Color(0xFF0D0F12);
  static const Color surface = Color(0xFF161A20);
  static const Color surfaceElevated = Color(0xFF1E232B);
  static const Color border = Color(0xFF2A3040);
  static const Color textPrimary = Color(0xFFEEF1F6);
  static const Color textSecondary = Color(0xFF8B93A0);
  static const Color textHint = Color(0xFF4A5260);
}
