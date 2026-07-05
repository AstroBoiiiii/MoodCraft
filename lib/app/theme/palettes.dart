/// Calm colour palettes (CLAUDE.md section 3 sensory settings, section 4 calm
/// visual language). Soft, low-contrast, low-saturation — no harsh contrast or
/// flashing. One palette per [AppColorTheme]; the student picks via sensory
/// settings.
library;

import 'package:flutter/material.dart';

import '../../core/models/enums.dart';

@immutable
class CalmPalette {
  const CalmPalette({
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.surface,
    required this.surfaceHigh,
    required this.background,
    required this.onSurface,
    required this.accent,
    this.brightness = Brightness.light,
  });

  final Color primary;
  final Color onPrimary;
  final Color secondary;
  final Color surface;

  /// A step more tinted than [surface]: fills inner tiles, text-field
  /// backgrounds and other "one level up" containers so layering actually
  /// reads (maps to `ColorScheme.surfaceContainerHighest`).
  final Color surfaceHigh;
  final Color background;
  final Color onSurface;
  final Color accent;
  final Brightness brightness;
}

const CalmPalette _calmBlue = CalmPalette(
  primary: Color(0xFF4E7C96),
  onPrimary: Color(0xFFFFFFFF),
  secondary: Color(0xFF8FB4C7),
  surface: Color(0xFFF2F7FA),
  surfaceHigh: Color(0xFFDFEAF0),
  background: Color(0xFFE9F1F5),
  onSurface: Color(0xFF273F4A),
  accent: Color(0xFFA6C9D8),
);

const CalmPalette _softGreen = CalmPalette(
  primary: Color(0xFF5C9079),
  onPrimary: Color(0xFFFFFFFF),
  secondary: Color(0xFF9DC4AE),
  surface: Color(0xFFF1F8F3),
  surfaceHigh: Color(0xFFDDEDE3),
  background: Color(0xFFE7F2EB),
  onSurface: Color(0xFF2F4338),
  accent: Color(0xFFBBD8C6),
);

const CalmPalette _warmNeutral = CalmPalette(
  primary: Color(0xFFB68A57),
  onPrimary: Color(0xFFFFFFFF),
  secondary: Color(0xFFD8BE9C),
  surface: Color(0xFFFBF6EF),
  surfaceHigh: Color(0xFFEFE4D2),
  background: Color(0xFFF4ECE0),
  onSurface: Color(0xFF4A3F30),
  accent: Color(0xFFE5D2B5),
);

const CalmPalette _lowStimGrey = CalmPalette(
  primary: Color(0xFF6E7C86),
  onPrimary: Color(0xFFFFFFFF),
  secondary: Color(0xFFA7B2B8),
  surface: Color(0xFFF4F6F7),
  surfaceHigh: Color(0xFFE2E7EA),
  background: Color(0xFFECEFF1),
  onSurface: Color(0xFF37424A),
  accent: Color(0xFFC3CCD1),
);

CalmPalette paletteFor(AppColorTheme theme) => switch (theme) {
  AppColorTheme.calmBlue => _calmBlue,
  AppColorTheme.softGreen => _softGreen,
  AppColorTheme.warmNeutral => _warmNeutral,
  AppColorTheme.lowStimGrey => _lowStimGrey,
};
