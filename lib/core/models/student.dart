import '../utils/json_utils.dart';
import 'sensory_settings.dart';

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
    this.mixMatchLevel = 0,
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

  /// Furthest unlocked Mix-and-Match level (FR6): highest [MixMatchType] index
  /// the child may play. 0 = only the first level (Face) is open; finishing a
  /// level bumps this so the next unlocks. Levels stay replayable; never a fail
  /// gate.
  final int mixMatchLevel;

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
    int? mixMatchLevel,
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
      mixMatchLevel: mixMatchLevel ?? this.mixMatchLevel,
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
    'mixMatchLevel': mixMatchLevel,
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
    mixMatchLevel: (json['mixMatchLevel'] as num?)?.toInt() ?? 0,
  );
}
