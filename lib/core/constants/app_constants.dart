/// App-wide constants. Centralised so values that may later move to Remote
/// Config or environment have a single home.
library;

import 'package:flutter/widgets.dart';

/// When true, the app uses the in-memory [StubAuthService] instead of real
/// Firebase auth — handy for building UI offline. Default false so the demo
/// runs against real Firebase. Flip via `--dart-define=USE_STUB_AUTH=true`.
const bool kUseStubAuth = bool.fromEnvironment(
  'USE_STUB_AUTH',
  defaultValue: false,
);

class AppConstants {
  AppConstants._();

  static const String appName = 'MoodCraft';

  /// Gemini model used via Firebase AI Logic. Kept as a constant so it can be
  /// swapped (later: Remote Config) without touching call sites. The 2.0 Flash
  /// models were retired June 2026; this is the current cheapest tier.
  static const String geminiModel = 'gemini-2.5-flash-lite';

  /// Supported app-UI locales. The AI companion is English-only and is NOT
  /// localised — that boundary is intentional (see CLAUDE.md section 3).
  static const List<Locale> supportedLocales = [Locale('en'), Locale('ms')];

  /// Minimum tap-target edge (logical px). Large targets reduce cognitive load.
  static const double minTapTarget = 64.0;

  /// Length of a generated class code (FR1). Short enough to read aloud and
  /// type, drawn from an unambiguous alphabet (no 0/O, 1/I).
  static const int classCodeLength = 6;
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

  /// Teacher-owned classes; students join by code at registration (FR1).
  static const String classes = 'classes';

  /// Parent<->student links awaiting the counterpart's registration (FR1).
  static const String pendingLinks = 'pendingLinks';

  /// email -> {uid, role} lookup so a registrant can resolve a counterpart by
  /// email without reading other users' full account docs (FR1).
  static const String emailDirectory = 'emailDirectory';

  /// username -> {uid, email} lookup for username-based sign-in.
  static const String usernameDirectory = 'usernameDirectory';
}
