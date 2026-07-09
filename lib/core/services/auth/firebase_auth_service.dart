import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../../constants/app_constants.dart';
import '../../models/app_user.dart';
import '../../models/enums.dart';
import '../../models/student.dart';
import '../data/linking_service.dart';
import 'auth_service.dart';

/// Real Firebase implementation (FR1). Email/password auth, with the role and
/// profile persisted to `users/{uid}` at registration and resolved from that
/// same document whenever Firebase reports a signed-in user. Relationship
/// building (class join, parent<->student invites) is delegated to
/// [LinkingService].
class FirebaseAuthService implements AuthService {
  FirebaseAuthService({
    fb.FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    LinkingService? linking,
  }) : _auth = auth ?? fb.FirebaseAuth.instance,
       _db = firestore ?? FirebaseFirestore.instance,
       _linking = linking ?? FirebaseLinkingService(firestore: firestore);

  final fb.FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final LinkingService _linking;
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
      _current = await _resolveUser(user);
      yield _current;
    }
  }

  /// Reads the `users/{uid}` profile. Just after registration the auth-state
  /// event can arrive before the profile write lands, so retry briefly before
  /// concluding the profile is missing.
  Future<AppUser?> _resolveUser(fb.User user) async {
    for (var attempt = 0; attempt < 4; attempt++) {
      final snap =
          await _db.collection(FirestoreCollections.users).doc(user.uid).get();
      final data = snap.data();
      if (data != null) return AppUser.fromJson({...data, 'uid': user.uid});
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    return null;
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
    final fb.UserCredential cred;
    try {
      cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e));
    }

    final uid = cred.user!.uid;
    final cleanEmail = email.trim();
    final cleanUsername = username.trim().toLowerCase();
    // A student is linked to their own profile so the same "is linked to this
    // student" check covers the child reading their own records.
    final user = AppUser(
      uid: uid,
      role: role,
      name: name.trim(),
      email: cleanEmail,
      username: cleanUsername,
      phone: phone.trim(),
      language: language,
      linkedStudentIds: role == UserRole.student ? [uid] : const [],
    );
    await _db
        .collection(FirestoreCollections.users)
        .doc(uid)
        .set(user.toJson());
    await _linking.recordDirectoryEntry(
      uid: uid,
      role: role,
      email: cleanEmail,
      username: cleanUsername,
    );
    _current = user;

    // Linking is best-effort: it must never undo a created account. Each step
    // is guarded so a hiccup leaves the user signed in, just not yet linked.
    var classCodeRecognised = true;
    try {
      switch (role) {
        case UserRole.teacher:
          await _linking.createClassForTeacher(
            teacherUid: uid,
            className:
                (className == null || className.trim().isEmpty)
                    ? name.trim()
                    : className.trim(),
          );
        case UserRole.student:
          await _db
              .collection(FirestoreCollections.students)
              .doc(uid)
              .set(
                Student(id: uid, name: name.trim(), age: age).toJson()
                  ..remove('id'),
              );
          final code = classCode?.trim() ?? '';
          if (code.isNotEmpty) {
            classCodeRecognised = await _linking.joinClassByCode(
              studentUid: uid,
              classCode: code,
            );
          }
          final pEmail = parentEmail?.trim() ?? '';
          if (pEmail.isNotEmpty) {
            await _linking.linkStudentToParent(
              studentUid: uid,
              studentEmail: cleanEmail,
              parentEmail: pEmail,
            );
          }
        case UserRole.parent:
          final cEmail = childEmail?.trim() ?? '';
          if (cEmail.isNotEmpty) {
            await _linking.linkParentToChild(
              parentUid: uid,
              parentEmail: cleanEmail,
              childEmail: cEmail,
            );
          }
      }
      await _linking.resolvePendingLinks(
        uid: uid,
        role: role,
        email: cleanEmail,
      );
    } catch (_) {
      // Swallow linking errors — the account is created and usable; linking can
      // be retried/repaired later. Never surface as a registration failure.
    }

    return RegisterResult(user: user, classCodeRecognised: classCodeRecognised);
  }

  @override
  Future<AppUser> signIn({
    required String emailOrUsername,
    required String password,
  }) async {
    try {
      final resolvedEmail = await _resolveEmail(emailOrUsername.trim());
      final cred = await _auth.signInWithEmailAndPassword(
        email: resolvedEmail,
        password: password,
      );
      final user = await _resolveUser(cred.user!);
      if (user == null) {
        throw const AuthException(
          'Your account has no profile yet. Please register again.',
        );
      }
      _current = user;
      return user;
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e));
    }
  }

  /// Returns the email for a given input. If the input looks like an email,
  /// it's returned as-is. Otherwise it's treated as a username and looked up
  /// in [usernameDirectory].
  Future<String> _resolveEmail(String input) async {
    if (input.contains('@')) return input;
    final snap =
        await _db
            .collection(FirestoreCollections.usernameDirectory)
            .doc(input.toLowerCase())
            .get();
    final email = snap.data()?['email'] as String?;
    if (email == null || email.isEmpty) {
      throw const AuthException(
        'Username not found. Please check and try again.',
      );
    }
    return email;
  }

  String _messageFor(fb.FirebaseAuthException e) => switch (e.code) {
    'email-already-in-use' =>
      'That email is already registered. Try signing in.',
    'invalid-email' => 'That email address does not look right.',
    'weak-password' => 'Please choose a password of at least 6 characters.',
    'user-not-found' ||
    'wrong-password' ||
    'invalid-credential' => 'Email or password is incorrect.',
    'user-disabled' => 'This account has been disabled.',
    'too-many-requests' => 'Too many attempts. Please wait a moment and retry.',
    'network-request-failed' => 'No connection. Check the network and retry.',
    _ => 'Something went wrong. Please try again.',
  };

  @override
  Future<void> signInAsRole(UserRole role) {
    throw UnimplementedError(
      'signInAsRole is a dev-only shortcut on StubAuthService.',
    );
  }

  @override
  Future<void> signOut() => _auth.signOut();
}
