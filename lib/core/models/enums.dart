/// Enumerations used across MoodCraft, with defensive string (de)serialisation.
library;

enum UserRole { student, teacher, parent }

enum ActivityType { companion, ar, story, mixmatch, quiz }

enum SyncStatus { pending, synced }

enum Emotion { happy, sad, scared, angry, surprised, neutral }

/// The three calm ways the FR7 quiz asks about a feeling (look at art, listen to
/// a sound cue, hear a short story). In `enums.dart` so the persisted
/// `QuizRound` can name it without depending on the quiz feature.
enum QuizModality { look, listen, story }

enum AnimationIntensity { full, reduced, off }

enum AppColorTheme { calmBlue, softGreen, warmNeutral, lowStimGrey }

enum AppLanguage { en, ms }

enum BackgroundTrack { track1, track2, track3 }

/// Resolves an enum value by its [Enum.name], falling back to [fallback] when
/// the stored string is missing or unrecognised (defensive parsing per
/// CLAUDE.md section 8).
T enumFromName<T extends Enum>(List<T> values, Object? name, T fallback) {
  for (final value in values) {
    if (value.name == name) return value;
  }
  return fallback;
}
