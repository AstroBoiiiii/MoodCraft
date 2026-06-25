import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';
import '../models/app_user.dart';
import '../services/auth/auth_service.dart';
import '../services/auth/firebase_auth_service.dart';
import '../services/auth/stub_auth_service.dart';

/// The active [AuthService]. Real Firebase auth by default; the in-memory stub
/// when [kUseStubAuth] is set (e.g. `--dart-define=USE_STUB_AUTH=true`).
final authServiceProvider = Provider<AuthService>((ref) {
  if (kUseStubAuth) {
    final service = StubAuthService();
    ref.onDispose(service.dispose);
    return service;
  }
  return FirebaseAuthService();
});

/// Streams the signed-in user (with resolved role), or null. Drives routing.
final authStateProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges();
});

/// Synchronous view of the current user (null while loading or signed out).
final currentUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(authStateProvider).value;
});
