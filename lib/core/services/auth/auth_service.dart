import '../../models/app_user.dart';
import '../../models/enums.dart';

/// A friendly, display-ready failure from an auth call. The UI shows [message]
/// directly; raw Firebase exceptions never reach the surface.
class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
  @override
  String toString() => 'AuthException: $message';
}

/// Outcome of a successful [AuthService.register]. The account always exists;
/// [classCodeRecognised] is false only when a student supplied a class code that
/// matched no class — a calm note, not a failure (CLAUDE.md design principle 1).
class RegisterResult {
  const RegisterResult({required this.user, this.classCodeRecognised = true});
  final AppUser user;
  final bool classCodeRecognised;
}

/// Abstraction over authentication so the rest of the app never depends on
/// Firebase directly. Two implementations exist:
///  - [StubAuthService] (in-memory, for offline/dev work),
///  - FirebaseAuthService (real, used by default for the demo).
abstract interface class AuthService {
  /// Emits the signed-in [AppUser] (with resolved role), or null when signed
  /// out. Emits the current value on subscription.
  Stream<AppUser?> authStateChanges();

  /// The currently signed-in user, or null.
  AppUser? get currentUser;

  /// Create an account, persist its role/profile, and sign in. Throws
  /// [AuthException] with a human-readable message on failure.
  ///
  /// Role-specific extras drive FR1 linking and are ignored where not relevant:
  ///  - [classCode] + [parentEmail] for a student (join a class, invite a parent),
  ///  - [childEmail] for a parent (invite their child),
  ///  - [className] for a teacher (the class they create).
  /// An invalid class code does not fail registration — see [RegisterResult].
  Future<RegisterResult> register({
    required String name,
    required String username,
    required String email,
    required String password,
    required UserRole role,
    required AppLanguage language,
    required String phone,
    String? classCode,
    String? parentEmail,
    String? childEmail,
    String? className,
  });

  /// Sign in with email or username + password. Throws [AuthException] on failure.
  Future<AppUser> signIn({required String emailOrUsername, required String password});

  /// Dev/demo shortcut that drops straight into a role's shell. Only meaningful
  /// for [StubAuthService]; the real implementation throws.
  Future<void> signInAsRole(UserRole role);

  Future<void> signOut();
}
