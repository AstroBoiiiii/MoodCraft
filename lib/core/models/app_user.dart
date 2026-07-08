import '../utils/json_utils.dart';
import 'enums.dart';

/// `users/{uid}` — the account record. [role] decides which app shell loads.
class AppUser {
  const AppUser({
    required this.uid,
    required this.role,
    required this.name,
    required this.email,
    this.username = '',
    this.phone = '',
    this.language = AppLanguage.en,
    this.linkedStudentIds = const [],
    this.seenBadgeCounts = const {},
    this.seenLevelCounts = const {},
    this.seenJournalCounts = const {},
    this.seenTaskAt = const {},
  });

  final String uid;
  final UserRole role;
  final String name;
  final String email;

  /// Unique handle chosen at registration. Used as an alternative sign-in
  /// identifier (lowercase, letters/digits/underscores only).
  final String username;

  /// Contact phone captured at registration (FR1). Stored only — never
  /// SMS-verified (that needs Blaze/release work, which is out of scope).
  final String phone;
  final AppLanguage language;

  /// Students this user is linked to (for teacher/parent roles).
  final List<String> linkedStudentIds;

  /// Per-child count of reward badges the user has already seen, keyed by
  /// student id. Drives the "your child achieved something new" dot on the
  /// parent's Progress tab: a dot shows while the child's badge total is higher
  /// than the value here, and opening Progress catches this up. UI last-seen
  /// state only — never a fail state, never shown to the child.
  final Map<String, int> seenBadgeCounts;

  /// Per-child personal level (FR11 title ladder) the user last saw, keyed by
  /// student id. Mirrors [seenBadgeCounts]: a dot/popup shows while the
  /// child's current `level` is higher than the value here, and acknowledging
  /// it catches this up. UI last-seen state only, never shown to the child.
  final Map<String, int> seenLevelCounts;

  /// Per-child emotion journal entry count (FR12) the user last saw, keyed by
  /// student id. Same shape as [seenBadgeCounts]/[seenLevelCounts]: a dot/popup
  /// shows while the child has logged more entries than this count, and
  /// acknowledging it catches this up.
  final Map<String, int> seenJournalCounts;

  /// Per-student "last acknowledged" moment for homework tasks (assignments),
  /// keyed by student id, stored as `millisecondsSinceEpoch`. Drives the
  /// child's "new task from your teacher" banner: a task counts as new while
  /// its `createdAt` is after this. Timestamp-based rather than a count like
  /// the others above because a teacher can delete a task, so a plain count
  /// could misfire after a deletion.
  final Map<String, int> seenTaskAt;

  AppUser copyWith({
    String? uid,
    UserRole? role,
    String? name,
    String? email,
    String? username,
    String? phone,
    AppLanguage? language,
    List<String>? linkedStudentIds,
    Map<String, int>? seenBadgeCounts,
    Map<String, int>? seenLevelCounts,
    Map<String, int>? seenJournalCounts,
    Map<String, int>? seenTaskAt,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      role: role ?? this.role,
      name: name ?? this.name,
      email: email ?? this.email,
      username: username ?? this.username,
      phone: phone ?? this.phone,
      language: language ?? this.language,
      linkedStudentIds: linkedStudentIds ?? this.linkedStudentIds,
      seenBadgeCounts: seenBadgeCounts ?? this.seenBadgeCounts,
      seenLevelCounts: seenLevelCounts ?? this.seenLevelCounts,
      seenJournalCounts: seenJournalCounts ?? this.seenJournalCounts,
      seenTaskAt: seenTaskAt ?? this.seenTaskAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'role': role.name,
    'name': name,
    'email': email,
    'username': username,
    'phone': phone,
    'language': language.name,
    'linkedStudentIds': linkedStudentIds,
    'seenBadgeCounts': seenBadgeCounts,
    'seenLevelCounts': seenLevelCounts,
    'seenJournalCounts': seenJournalCounts,
    'seenTaskAt': seenTaskAt,
  };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    uid: (json['uid'] as String?) ?? '',
    role: enumFromName(UserRole.values, json['role'], UserRole.student),
    name: (json['name'] as String?) ?? '',
    email: (json['email'] as String?) ?? '',
    username: (json['username'] as String?) ?? '',
    phone: (json['phone'] as String?) ?? '',
    language: enumFromName(
      AppLanguage.values,
      json['language'],
      AppLanguage.en,
    ),
    linkedStudentIds: stringListFromJson(json['linkedStudentIds']),
    seenBadgeCounts: intMapFromJson(json['seenBadgeCounts']),
    seenLevelCounts: intMapFromJson(json['seenLevelCounts']),
    seenJournalCounts: intMapFromJson(json['seenJournalCounts']),
    seenTaskAt: intMapFromJson(json['seenTaskAt']),
  );
}
