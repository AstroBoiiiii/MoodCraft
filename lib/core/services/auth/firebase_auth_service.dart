import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../../constants/app_constants.dart';
import '../../models/app_user.dart';
import '../../models/enums.dart';
import 'auth_service.dart';

/// Real Firebase implementation. Present and compiling, but NOT wired yet — the
/// providers point at [StubAuthService] until `flutterfire configure` is run.
/// At that point: enable init in firebase/bootstrap.dart and swap the provider
/// in providers/auth_provider.dart.
///
/// Resolves the role by reading the `users/{uid}` document for the signed-in
/// Firebase user.
class FirebaseAuthService implements AuthService {
  FirebaseAuthService({fb.FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? fb.FirebaseAuth.instance,
      _db = firestore ?? FirebaseFirestore.instance;

  final fb.FirebaseAuth _auth;
  final FirebaseFirestore _db;
  AppUser? _current;

  @override
  AppUser? get currentUser => _current;

  @override
  Stream<AppUser?> authStateChanges() async* {
    await for (final user in _auth.authStateChanges()) {
      if (user == null) {
        _current = null;
        yield null;
        continue;
      }
      final snap =
          await _db.collection(FirestoreCollections.users).doc(user.uid).get();
      final data = snap.data();
      _current = data == null
          ? null
          : AppUser.fromJson({...data, 'uid': user.uid});
      yield _current;
    }
  }

  @override
  Future<void> signInAsRole(UserRole role) {
    throw UnimplementedError(
      'Real auth uses an email/password login UI; build it when wiring '
      'Firebase. signInAsRole is a dev-only shortcut on StubAuthService.',
    );
  }

  @override
  Future<void> signOut() => _auth.signOut();
}
