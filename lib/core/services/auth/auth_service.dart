import '../../models/app_user.dart';
import '../../models/enums.dart';

/// Abstraction over authentication so the rest of the app never depends on
/// Firebase directly. Two implementations exist:
///  - [StubAuthService] (in-memory, wired now for dev),
///  - FirebaseAuthService (real, swapped in after `flutterfire configure`).
abstract interface class AuthService {
  /// Emits the signed-in [AppUser] (with resolved role), or null when signed
  /// out. Emits the current value on subscription.
  Stream<AppUser?> authStateChanges();

  /// The currently signed-in user, or null.
  AppUser? get currentUser;

  /// Dev/demo sign-in that drops straight into a role's shell. The real
  /// implementation uses an email/password login UI instead.
  Future<void> signInAsRole(UserRole role);

  Future<void> signOut();
}
