/// App-wide constants. Centralised so values that may later move to Remote
/// Config or environment have a single home.
library;

import 'package:flutter/material.dart';

import '../models/enums.dart';

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

/// Picture-step icons for the visual schedule (FR13). Stored by key so the
/// rendered icon can be swapped for real art later without a data migration.
/// Order here is the order shown in the editor's icon picker.
const Map<String, IconData> kScheduleIconCatalog = {
  'breakfast': Icons.free_breakfast_rounded,
  'lessons': Icons.menu_book_rounded,
  'break': Icons.emoji_people_rounded,
  'art': Icons.palette_rounded,
  'music': Icons.music_note_rounded,
  'play': Icons.toys_rounded,
  'reading': Icons.auto_stories_rounded,
  'lunch': Icons.restaurant_rounded,
  'nap': Icons.bedtime_rounded,
  'clean': Icons.cleaning_services_rounded,
  'home': Icons.home_rounded,
  'star': Icons.star_rounded, // generic fallback
};

/// Resolve a schedule [iconKey] to an icon, falling back to a neutral star for
/// unknown/empty keys so the child's view never shows a broken glyph.
IconData scheduleIcon(String iconKey) =>
    kScheduleIconCatalog[iconKey] ?? Icons.star_rounded;

/// Emotion → placeholder face icon for the journal (FR12) and pickers. Like
/// [kScheduleIconCatalog], the glyphs are centralised so real expression art can
/// replace them later with no call-site changes (CLAUDE.md section 9). The six
/// keys match the companion's expression set.
const Map<Emotion, IconData> kEmotionIcon = {
  Emotion.happy: Icons.sentiment_very_satisfied_rounded,
  Emotion.sad: Icons.sentiment_dissatisfied_rounded,
  Emotion.angry: Icons.mood_bad_rounded,
  Emotion.scared: Icons.sentiment_very_dissatisfied_rounded,
  Emotion.surprised: Icons.emoji_emotions_rounded,
  Emotion.neutral: Icons.sentiment_neutral_rounded,
};

/// Soft, constant colour per emotion. Deliberately muted (no harsh/alarming
/// reds — see `kMutedAlert`) and identical in every theme, so a given feeling
/// always looks the same to the child (predictable & consistent, section 4.2).
const Map<Emotion, Color> kEmotionColor = {
  Emotion.happy: Color(0xFFE3B23C),
  Emotion.sad: Color(0xFF6B92B0),
  Emotion.angry: Color(0xFFC58579),
  Emotion.scared: Color(0xFF9385BC),
  Emotion.surprised: Color(0xFF5DAA9C),
  Emotion.neutral: Color(0xFF8B97A1),
};

/// Optional "where / what" context pictures a child can tag onto a journal
/// entry. The key is stored on the entry; the icon is resolved here so art can
/// be swapped later. Order here is the order shown in the picker.
const Map<String, IconData> kJournalContextCatalog = {
  'home': Icons.home_rounded,
  'class': Icons.school_rounded,
  'play': Icons.toys_rounded,
  'outside': Icons.park_rounded,
  'meal': Icons.restaurant_rounded,
  'friends': Icons.group_rounded,
};

/// Resolve a journal context [key] to an icon, or null when none/unknown.
IconData? journalContextIcon(String? key) =>
    key == null ? null : kJournalContextCatalog[key];

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
