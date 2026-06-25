import 'dart:async';

import '../../models/app_user.dart';
import '../../models/enums.dart';
import '../data/dev_seed.dart';
import 'auth_service.dart';

/// In-memory [AuthService] for development. "Signing in as a role" maps to a
/// canned [AppUser] from [DevSeed] and emits it on the auth stream — enough to
/// exercise role-based routing and all three shells without a backend.
class StubAuthService implements AuthService {
  AppUser? _current;
  final StreamController<AppUser?> _controller =
      StreamController<AppUser?>.broadcast();

  @override
  AppUser? get currentUser => _current;

  @override
  Stream<AppUser?> authStateChanges() async* {
    yield _current;
    yield* _controller.stream;
  }

  @override
  Future<RegisterResult> register({
    required String name,
    required String username,
    required String email,
    required String password,
    required UserRole role,
    required AppLanguage language,
    required String phone,
    int age = 0,
    String? classCode,
    String? parentEmail,
    String? childEmail,
    String? className,
  }) async {
    _current = AppUser(
      uid: 'stub-${DateTime.now().millisecondsSinceEpoch}',
      role: role,
      name: name.trim(),
      username: username.trim().toLowerCase(),
      email: email.trim(),
      phone: phone.trim(),
      language: language,
      linkedStudentIds:
          role == UserRole.student ? const [DevSeed.studentId] : const [],
    );
    _controller.add(_current);
    return RegisterResult(user: _current!);
  }

  @override
  Future<AppUser> signIn({
    required String emailOrUsername,
    required String password,
  }) async {
    // Match by email, username prefix, or fall back to student.
    final input = emailOrUsername.trim().toLowerCase();
    final role =
        (input.startsWith('teacher') || input == DevSeed.teacherUser.username)
            ? UserRole.teacher
            : (input.startsWith('parent') ||
                input == DevSeed.parentUser.username)
            ? UserRole.parent
            : UserRole.student;
    _current = DevSeed.userForRole(role);
    _controller.add(_current);
    return _current!;
  }

  @override
  Future<void> signInAsRole(UserRole role) async {
    _current = DevSeed.userForRole(role);
    _controller.add(_current);
  }

  @override
  Future<void> signOut() async {
    _current = null;
    _controller.add(null);
  }

  void dispose() => _controller.close();
}
