/// Holds the active [SensorySettings] for the running session. Defaults are
/// calm; later this is hydrated from the signed-in student's profile via
/// [SensorySettingsController.replace]. Every activity reads this provider so
/// sound, animation, and theme preferences are honoured everywhere.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/enums.dart';
import '../models/sensory_settings.dart';

class SensorySettingsController extends Notifier<SensorySettings> {
  @override
  SensorySettings build() => SensorySettings.defaults;

  void setColorTheme(AppColorTheme theme) =>
      state = state.copyWith(colorTheme: theme);

  void setAnimationIntensity(AnimationIntensity intensity) =>
      state = state.copyWith(animationIntensity: intensity);

  void setMusicEnabled(bool enabled) =>
      state = state.copyWith(musicEnabled: enabled);

  void setMasterVolume(double volume) =>
      state = state.copyWith(masterVolume: volume.clamp(0.0, 1.0));

  /// Replace all settings at once — used when a student profile loads.
  void replace(SensorySettings settings) => state = settings;
}

final sensorySettingsProvider =
    NotifierProvider<SensorySettingsController, SensorySettings>(
  SensorySettingsController.new,
);

/// Scales a base motion [Duration] by the current animation-intensity setting:
/// full = unchanged, reduced = halved, off = zero (instant).
Duration effectiveDuration(AnimationIntensity intensity, Duration base) {
  switch (intensity) {
    case AnimationIntensity.full:
      return base;
    case AnimationIntensity.reduced:
      return base * 0.5;
    case AnimationIntensity.off:
      return Duration.zero;
  }
}
