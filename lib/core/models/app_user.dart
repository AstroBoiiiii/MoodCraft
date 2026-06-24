import '../utils/json_utils.dart';
import 'enums.dart';

/// `users/{uid}` — the account record. [role] decides which app shell loads.
class AppUser {
  const AppUser({
    required this.uid,
    required this.role,
    required this.name,
    required this.email,
    this.language = AppLanguage.en,
    this.linkedStudentIds = const [],
  });

  final String uid;
  final UserRole role;
  final String name;
  final String email;
  final AppLanguage language;

  /// Students this user is linked to (for teacher/parent roles).
  final List<String> linkedStudentIds;

  AppUser copyWith({
    String? uid,
    UserRole? role,
    String? name,
    String? email,
    AppLanguage? language,
    List<String>? linkedStudentIds,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      role: role ?? this.role,
      name: name ?? this.name,
      email: email ?? this.email,
      language: language ?? this.language,
      linkedStudentIds: linkedStudentIds ?? this.linkedStudentIds,
    );
  }

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'role': role.name,
    'name': name,
    'email': email,
    'language': language.name,
    'linkedStudentIds': linkedStudentIds,
  };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    uid: (json['uid'] as String?) ?? '',
    role: enumFromName(UserRole.values, json['role'], UserRole.student),
    name: (json['name'] as String?) ?? '',
    email: (json['email'] as String?) ?? '',
    language: enumFromName(AppLanguage.values, json['language'], AppLanguage.en),
    linkedStudentIds: stringListFromJson(json['linkedStudentIds']),
  );
}
