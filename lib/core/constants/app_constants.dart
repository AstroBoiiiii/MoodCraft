/// App-wide constants. Centralised so values that may later move to Remote
/// Config or environment have a single home.
library;

import 'package:flutter/material.dart';

import '../models/emotion_content.dart';
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

/// Mix-and-Match (FR6). The child drags a card onto the matching emotion. The
/// four card types double as the four levels, ordered concrete → abstract so
/// progression is gentle: a face is the most literal cue, a short story the most
/// abstract (the child reads it and interprets the feeling).
/// [MixMatchType.values] order IS the level order.
enum MixMatchType { face, body, situation, story }

/// Number of cards (questions) in one Mix-and-Match round, per card type (FR6).
/// Each category's progress is shown as "X/[kMixMatchRoundSize]".
const int kMixMatchRoundSize = 5;

/// The feelings used as Mix-and-Match buckets (FR6). Five clear, distinct
/// emotions — `neutral` ("Okay") is intentionally left out here so every round's
/// cards map to a strong, teachable feeling and there's no spare empty bucket.
const List<Emotion> kMixMatchEmotions = [
  Emotion.happy,
  Emotion.sad,
  Emotion.scared,
  Emotion.angry,
  Emotion.surprised,
];

/// Root for Mix-and-Match card art. Image cards live under
/// `<root>/<type>/<emotion>_<n>.png`; the leading `<emotion>` token encodes the
/// correct answer, so dropping a new file in needs no code or data change
/// (asset strategy, CLAUDE.md section 9). Folders are auto-scanned at runtime
/// via the asset manifest — see `buildMixMatchDeck`.
const String kMixMatchAssetRoot = 'assets/images/mixmatch';

/// Folder (under [kMixMatchAssetRoot]) holding image cards for a type. `story`
/// has no folder — those cards are text from [kMixMatchStories].
String mixMatchTypeFolder(MixMatchType type) => switch (type) {
  MixMatchType.face => '$kMixMatchAssetRoot/face',
  MixMatchType.body => '$kMixMatchAssetRoot/body',
  MixMatchType.situation => '$kMixMatchAssetRoot/situation',
  MixMatchType.story => '$kMixMatchAssetRoot/story',
};

/// Whether a type's cards are drawn as text (vs. an image asset). Stories are
/// always text; situations fall back to text when no art has been uploaded.
bool mixMatchTypeIsText(MixMatchType type) => type == MixMatchType.story;

/// Calm, vetted short-story cards per emotion (FR6, hardest `story` level). The
/// child reads a tiny two-sentence scene and interprets which feeling it shows —
/// the most abstract step, no single emotion word given away. One per emotion so
/// a round shows five distinct feelings. Kept here so they can be swapped or
/// extended without touching the activity.
const Map<Emotion, List<String>> kMixMatchStories = {
  Emotion.happy: [
    'Mia opened her birthday present and found a soft puppy inside. She hugged it and could not stop smiling.',
  ],
  Emotion.sad: [
    'Sam watched his balloon float far up into the sky. He could not get it back, and his eyes filled with tears.',
  ],
  Emotion.scared: [
    'The lights went out and Lilya heard a loud bang. She pulled her blanket up and held it tight.',
  ],
  Emotion.angry: [
    'Ben built a tall block tower all by himself. Someone knocked it over, and he stamped his feet hard.',
  ],
  Emotion.surprised: [
    'Ava opened the door and the whole room jumped up shouting. Her mouth fell open. She never expected anyone to be there.',
  ],
};

/// Short situation cards per emotion (FR6, `situation` level), used when no
/// situation art has been uploaded. Each is a tiny, concrete scene a child can
/// link to a feeling. Drop images in `mixmatch/situation/` to use art instead.
const Map<Emotion, List<String>> kMixMatchSituations = {
  Emotion.happy: ['Got a present', 'Playing with a friend'],
  Emotion.sad: ['Dropped my ice cream', 'Said bye to a friend'],
  Emotion.scared: ['Heard a loud noise', 'It is very dark'],
  Emotion.angry: ['My tower fell down', 'Lost my turn'],
  Emotion.surprised: ['A surprise party', 'A balloon popped'],
};

/// FR7 stress-free quiz. Number of questions in one mixed round — the round
/// interleaves the three ways of asking (look / listen / story) so every
/// available way shows up. No timer, no score (CLAUDE.md FR7). Drives the
/// per-day "X/5" on the picker.
const int kQuizRoundSize = 5;

/// Number of daily quiz sets. Only the **stories** differ per day; the faces and
/// sound cues are shared, recycled across every set. The real date picks which
/// story set is "today" (see `quizSetIndexForDate`). Matches
/// `kQuizStorySets.length`.
const int kQuizSetCount = 3;

/// The feelings the quiz teaches (the five clear, teachable emotions; `neutral`
/// excluded). The quiz keeps its own list so it never depends on Mix-and-Match.
const List<Emotion> kQuizEmotions = [
  Emotion.happy,
  Emotion.sad,
  Emotion.scared,
  Emotion.angry,
  Emotion.surprised,
];

/// The quiz's own shared "look" face-art folder. Faces are NOT per-set: a few
/// variations per feeling (`happy_1.png`, `happy_2.png`, ...) live here and are
/// recycled across every daily set. The leading `<emotion>` token is the answer.
/// The quiz keeps its OWN folder (not Mix-and-Match's). Registered in pubspec.
const String kQuizLookRoot = 'assets/images/quiz/look';

/// The quiz's shared "listen" sound-cue folder. Like the faces, cues are NOT
/// per-set: the same feeling sounds are recycled across every daily set. A clip
/// named `<emotion>_<n>.mp3` (or `.wav`) becomes a Listen question; the leading
/// `<emotion>` token is the answer. Empty folder = the round uses look + story.
/// Registered in pubspec.yaml.
const String kQuizCueFolder = 'assets/audio/cues';

/// Last-resort fallback feedback, one bland line per feeling, only used if a
/// modality/story line below is somehow missing. The real spoken feedback is
/// tailored per question: faces use [kQuizLookFeedback], sounds use
/// [kQuizListenFeedback], and each story carries its own `feedback`. Teaching
/// content, English only like [kMixMatchStories] (BM is the deferred FR15 pass).
const Map<Emotion, String> kQuizFeedback = {
  Emotion.happy: "That feeling is happy.",
  Emotion.sad: "That feeling is sad.",
  Emotion.scared: "That feeling is scared.",
  Emotion.angry: "That feeling is angry.",
  Emotion.surprised: "That feeling is surprised.",
};

/// Warm spoken feedback for "look" (face) questions, one short line per feeling
/// that points at what the face is doing. Read aloud on a right answer.
const Map<Emotion, String> kQuizLookFeedback = {
  Emotion.happy: "Look at that big smile. Happy!",
  Emotion.sad: "The mouth turns down. That is sad.",
  Emotion.scared: "Those wide eyes look scared.",
  Emotion.angry: "That scrunched up face is angry.",
  Emotion.surprised: "Wide eyes, open mouth. Surprised!",
};

/// Warm spoken feedback for "listen" (sound) questions, naming the sound the
/// child just heard so the cue and the feeling connect. Read aloud on a right
/// answer.
const Map<Emotion, String> kQuizListenFeedback = {
  Emotion.happy: "Yahoo! That is a happy sound.",
  Emotion.sad: "Waah! That crying sounds sad.",
  Emotion.scared: "Aaah! That scream sounds scared.",
  Emotion.angry: "Grrr. That growl sounds angry.",
  Emotion.surprised: "Oooh! That sound is surprised.",
};

/// Three sets of short, calm scenarios for the quiz's "story" questions (FR7),
/// one set per day (today / yesterday / day before, chosen by
/// `quizSetIndexForDate`). Read aloud, the child picks the matching feeling.
/// Shaped as [EmotionContent] (the curated, offline teaching model); the short
/// spoken feedback after a right answer comes from [kQuizFeedback]. English-only
/// content like [kMixMatchStories].
const List<List<EmotionContent>> kQuizStorySets = [
  // Set 1
  [
    EmotionContent(id: 'q1_happy', emotion: Emotion.happy, prompt: 'Ari found his lost teddy under the bed.', feedback: 'Ari found his teddy. He feels happy.'),
    EmotionContent(id: 'q1_sad', emotion: Emotion.sad, prompt: 'Nina watched her ice cream fall on the floor.', feedback: "Nina's ice cream fell. She feels sad."),
    EmotionContent(id: 'q1_scared', emotion: Emotion.scared, prompt: 'The room went dark and something went bump.', feedback: 'A bump in the dark. That feels scared.'),
    EmotionContent(id: 'q1_angry', emotion: Emotion.angry, prompt: 'Someone took Omar off his turn on the swing.', feedback: 'Omar lost his turn. He feels angry.'),
    EmotionContent(id: 'q1_surprised', emotion: Emotion.surprised, prompt: 'Everyone jumped out and shouted at the party.', feedback: 'Everyone jumped out. What a surprise!'),
  ],
  // Set 2
  [
    EmotionContent(id: 'q2_happy', emotion: Emotion.happy, prompt: "Lina's puppy ran to her, wagging its tail.", feedback: 'The puppy runs to Lina. She feels happy.'),
    EmotionContent(id: 'q2_sad', emotion: Emotion.sad, prompt: "Sam's best friend moved far away today.", feedback: "Sam's friend moved away. He feels sad."),
    EmotionContent(id: 'q2_scared', emotion: Emotion.scared, prompt: 'A big dog barked loudly right behind Mia.', feedback: 'A big dog barked at Mia. She feels scared.'),
    EmotionContent(id: 'q2_angry', emotion: Emotion.angry, prompt: "Tom's little brother scribbled on his drawing.", feedback: 'Tom\'s drawing got scribbled. He feels angry.'),
    EmotionContent(id: 'q2_surprised', emotion: Emotion.surprised, prompt: 'A balloon popped with a sudden loud bang.', feedback: 'The balloon went bang. What a surprise!'),
  ],
  // Set 3
  [
    EmotionContent(id: 'q3_happy', emotion: Emotion.happy, prompt: 'Grandma baked Aziz his favourite cake.', feedback: "Grandma baked Aziz's cake. He feels happy."),
    EmotionContent(id: 'q3_sad', emotion: Emotion.sad, prompt: "Maya's balloon floated up into the sky.", feedback: "Maya's balloon floated away. She feels sad."),
    EmotionContent(id: 'q3_scared', emotion: Emotion.scared, prompt: 'All the lights went out in the house.', feedback: 'All the lights went out. That feels scared.'),
    EmotionContent(id: 'q3_angry', emotion: Emotion.angry, prompt: 'Someone knocked down the tower Eli built.', feedback: 'Eli\'s tower was knocked down. He feels angry.'),
    EmotionContent(id: 'q3_surprised', emotion: Emotion.surprised, prompt: 'Dad came home early carrying a puppy.', feedback: 'Dad came home with a puppy. What a surprise!'),
  ],
];

/// Soft accent per student-home activity, keyed by the activity's route id. Used
/// by `ActivityCard` to tint the icon badge + outline only — muted tones in the
/// same calm family as `kEmotionColor`, never a harsh fill (CLAUDE.md section 4).
const Map<String, Color> kActivityAccent = {
  'companion': Color(0xFF5DAA9C),
  'ar': Color(0xFF6B92B0),
  'story': Color(0xFFE3B23C),
  'mixmatch': Color(0xFF9385BC),
  'quiz': Color(0xFFC58579),
  'rewards': Color(0xFFE3B23C),
};

/// Resolve an activity [key] to its accent, falling back to a neutral tone.
Color activityAccent(String key) =>
    kActivityAccent[key] ?? const Color(0xFF8B97A1);

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
