/// Design tokens — the calm visual language (CLAUDE.md sections 4 & 6).
/// Generous spacing, soft radii, large legible type, gentle motion.
library;

import 'package:flutter/widgets.dart';

class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

class AppRadii {
  AppRadii._();
  static const double sm = 12;
  static const double md = 20;
  static const double lg = 28;
  static const double pill = 999;
}

/// Base motion durations. Always pass these through `effectiveDuration` so the
/// student's animationIntensity setting (full/reduced/off) is respected.
class AppDurations {
  AppDurations._();
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
}

/// A muted, non-alarming tone used for the ColorScheme.error slot. There are no
/// fail states in student UI, so we never want a harsh red (CLAUDE.md section 4).
const Color kMutedAlert = Color(0xFFB58A8A);
