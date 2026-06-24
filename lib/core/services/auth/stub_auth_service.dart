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
