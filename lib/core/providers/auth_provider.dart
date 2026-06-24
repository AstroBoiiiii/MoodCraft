import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import '../services/auth/auth_service.dart';
import '../services/auth/stub_auth_service.dart';

/// The active [AuthService]. Dev/stub mode for now.
///
/// TODO(firebase): after `flutterfire configure`, return
/// `FirebaseAuthService()` here instead of `StubAuthService()`.
final authServiceProvider = Provider<AuthService>((ref) {
  final service = StubAuthService();
  ref.onDispose(service.dispose);
  return service;
});

/// Streams the signed-in user (with resolved role), or null. Drives routing.
final authStateProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges();
});

/// Synchronous view of the current user (null while loading or signed out).
final currentUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(authStateProvider).value;
});
