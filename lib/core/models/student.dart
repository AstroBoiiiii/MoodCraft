import '../utils/json_utils.dart';
import 'mix_match_round.dart';
import 'quiz_round.dart';
import 'sensory_settings.dart';
import 'story_progress.dart';

/// `students/{studentId}` — the learner profile, owning the sensory settings
/// and gentle progression (level/stars).
class Student {
  const Student({
    required this.id,
    required this.name,
    this.age = 0,
    this.avatar = '',
    this.teacherIds = const [],
    this.parentIds = const [],
    this.sensorySettings = SensorySettings.defaults,
    this.level = 1,
    this.stars = 0,
    this.mixMatchRounds = const {},
    this.quizRounds = const {},
    this.storyProgress = const {},
  });

  final String id;
  final String name;

  /// Age in years. 0 means not set.
  final int age;

  /// Placeholder avatar key/path; real art swaps in via [AppAssets].
  final String avatar;
  final List<String> teacherIds;
  final List<String> parentIds;
  final SensorySettings sensorySettings;
  final int level;
  final int stars;

  /// Per card-type saved Mix-and-Match rounds (FR6): `MixMatchType.name` →
  /// the child's in-progress (or finished) round for that category. Persisted so
  /// play resumes on the exact same question after navigating away or signing
  /// out. `round.placed` drives the "X/5" tile and the overall badge bar.
  final Map<String, MixMatchRound> mixMatchRounds;

  /// Per daily-set saved stress-free quiz rounds (FR7): set index (as a string)
  /// → the child's in-progress (or finished) round. Persisted so the quiz
  /// resumes on the exact same question after navigating away or signing out.
  final Map<String, QuizRound> quizRounds;

  /// Per-story saved Story Mode progress (FR5): story id → episodes finished
  /// plus the exact pause point of the in-progress episode. Persisted so
  /// episodes unlock in order and play resumes where the child left off.
  final Map<String, StoryProgress> storyProgress;

  Student copyWith({
    String? id,
    String? name,
    int? age,
    String? avatar,
    List<String>? teacherIds,
    List<String>? parentIds,
    SensorySettings? sensorySettings,
    int? level,
    int? stars,
    Map<String, MixMatchRound>? mixMatchRounds,
    Map<String, QuizRound>? quizRounds,
    Map<String, StoryProgress>? storyProgress,
  }) {
    return Student(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      avatar: avatar ?? this.avatar,
      teacherIds: teacherIds ?? this.teacherIds,
      parentIds: parentIds ?? this.parentIds,
      sensorySettings: sensorySettings ?? this.sensorySettings,
      level: level ?? this.level,
      stars: stars ?? this.stars,
      mixMatchRounds: mixMatchRounds ?? this.mixMatchRounds,
      quizRounds: quizRounds ?? this.quizRounds,
      storyProgress: storyProgress ?? this.storyProgress,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'age': age,
    'avatar': avatar,
    'teacherIds': teacherIds,
    'parentIds': parentIds,
    'sensorySettings': sensorySettings.toJson(),
    'level': level,
    'stars': stars,
    'mixMatchRounds': mixMatchRounds.map((k, v) => MapEntry(k, v.toJson())),
    'quizRounds': quizRounds.map((k, v) => MapEntry(k, v.toJson())),
    'storyProgress': storyProgress.map((k, v) => MapEntry(k, v.toJson())),
  };

  factory Student.fromJson(Map<String, dynamic> json) => Student(
    id: (json['id'] as String?) ?? '',
    name: (json['name'] as String?) ?? '',
    age: (json['age'] as num?)?.toInt() ?? 0,
    avatar: (json['avatar'] as String?) ?? '',
    teacherIds: stringListFromJson(json['teacherIds']),
    parentIds: stringListFromJson(json['parentIds']),
    sensorySettings: SensorySettings.fromJson(
      json['sensorySettings'] as Map<String, dynamic>?,
    ),
    level: (json['level'] as num?)?.toInt() ?? 1,
    stars: (json['stars'] as num?)?.toInt() ?? 0,
    mixMatchRounds: mixMatchRoundsFromJson(json['mixMatchRounds']),
    quizRounds: quizRoundsFromJson(json['quizRounds']),
    storyProgress: storyProgressFromJson(json['storyProgress']),
  );
}
