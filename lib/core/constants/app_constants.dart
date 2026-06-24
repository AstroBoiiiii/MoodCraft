/// App-wide constants. Centralised so values that may later move to Remote
/// Config or environment have a single home.
library;

import 'package:flutter/widgets.dart';

class AppConstants {
  AppConstants._();

  static const String appName = 'MoodCraft';

  /// Gemini model used via Firebase AI Logic. Kept as a constant so it can be
  /// swapped (later: Remote Config) without touching call sites. The 2.0 Flash
  /// models were retired June 2026; this is the current cheapest tier.
  static const String geminiModel = 'gemini-2.5-flash-lite';

  /// Supported app-UI locales. The AI companion is English-only and is NOT
  /// localised — that boundary is intentional (see CLAUDE.md section 3).
  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('ms'),
  ];

  /// Minimum tap-target edge (logical px). Large targets reduce cognitive load.
  static const double minTapTarget = 64.0;
}

/// Firestore collection names — referenced by repository implementations so the
/// schema lives in one place (see CLAUDE.md section 7).
class FirestoreCollections {
  FirestoreCollections._();

  static const String users = 'users';
  static const String students = 'students';
  static const String sessions = 'sessions';
  static const String journalEntries = 'journalEntries';
  static const String messages = 'messages';
  static const String observationReports = 'observationReports';
  static const String emotionContent = 'emotionContent';
  static const String visualSchedules = 'visualSchedules';
}
