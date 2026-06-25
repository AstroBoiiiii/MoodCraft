import '../utils/json_utils.dart';
import 'sensory_settings.dart';

/// `students/{studentId}` — the learner profile, owning the sensory settings
/// and gentle progression (level/stars).
class Student {
  const Student({
    required this.id,
    required this.name,
    this.avatar = '',
    this.teacherIds = const [],
    this.parentIds = const [],
    this.sensorySettings = SensorySettings.defaults,
    this.level = 1,
    this.stars = 0,
  });

  final String id;
  final String name;

  /// Placeholder avatar key/path; real art swaps in via [AppAssets].
  final String avatar;
  final List<String> teacherIds;
  final List<String> parentIds;
  final SensorySettings sensorySettings;
  final int level;
  final int stars;

  Student copyWith({
    String? id,
    String? name,
    String? avatar,
    List<String>? teacherIds,
    List<String>? parentIds,
    SensorySettings? sensorySettings,
    int? level,
    int? stars,
  }) {
    return Student(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      teacherIds: teacherIds ?? this.teacherIds,
      parentIds: parentIds ?? this.parentIds,
      sensorySettings: sensorySettings ?? this.sensorySettings,
      level: level ?? this.level,
      stars: stars ?? this.stars,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'avatar': avatar,
    'teacherIds': teacherIds,
    'parentIds': parentIds,
    'sensorySettings': sensorySettings.toJson(),
    'level': level,
    'stars': stars,
  };

  factory Student.fromJson(Map<String, dynamic> json) => Student(
    id: (json['id'] as String?) ?? '',
    name: (json['name'] as String?) ?? '',
    avatar: (json['avatar'] as String?) ?? '',
    teacherIds: stringListFromJson(json['teacherIds']),
    parentIds: stringListFromJson(json['parentIds']),
    sensorySettings: SensorySettings.fromJson(
      json['sensorySettings'] as Map<String, dynamic>?,
    ),
    level: (json['level'] as num?)?.toInt() ?? 1,
    stars: (json['stars'] as num?)?.toInt() ?? 0,
  );
}
