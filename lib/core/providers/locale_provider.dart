/// The app's active UI [Locale], driven by the signed-in user's chosen
/// [AppLanguage] (FR15) rather than the device's system locale. `null` means
/// "follow the device locale" — used before sign-in and right after sign-out.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/enums.dart';
import 'auth_provider.dart';

class AppLocaleController extends Notifier<Locale?> {
  // Seeded from the signed-in user's saved language so a cold start (or a
  // fresh sign-in/out) always resolves correctly without waiting on a manual
  // override below.
  @override
  Locale? build() {
    final user = ref.watch(currentUserProvider);
    return user != null ? Locale(user.language.name) : null;
  }

  /// Applies a language change immediately, without waiting for the auth
  /// stream to re-emit (it only fires on sign-in/out, not on profile edits).
  void setFromLanguage(AppLanguage language) =>
      state = Locale(language.name);

  void reset() => state = null;
}

final appLocaleProvider = NotifierProvider<AppLocaleController, Locale?>(
  AppLocaleController.new,
);
