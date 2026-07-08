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

  AppUser copyWith({
    String? uid,
    UserRole? role,
    String? name,
    String? email,
    String? username,
    String? phone,
    AppLanguage? language,
    List<String>? linkedStudentIds,
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
  );
}
