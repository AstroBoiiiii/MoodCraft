/// Holds the active [SensorySettings] for the running session. Defaults are
/// calm; later this is hydrated from the signed-in student's profile via
/// [SensorySettingsController.replace]. Every activity reads this provider so
/// sound, animation, and theme preferences are honoured everywhere.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/enums.dart';
import '../models/sensory_settings.dart';
import '../services/data/repositories.dart';

class SensorySettingsController extends Notifier<SensorySettings> {
  @override
  SensorySettings build() => SensorySettings.defaults;

  void setColorTheme(AppColorTheme theme) =>
      state = state.copyWith(colorTheme: theme);

  void setMusicEnabled(bool enabled) =>
      state = state.copyWith(musicEnabled: enabled);

  void setMasterVolume(double volume) =>
      state = state.copyWith(masterVolume: volume.clamp(0.0, 1.0));

  void setBackgroundTrack(BackgroundTrack track) =>
      state = state.copyWith(backgroundTrack: track);

  void setQuizFeedbackNarration(bool enabled) =>
      state = state.copyWith(quizFeedbackNarration: enabled);

  /// Replace all settings at once — used when a student profile loads.
  void replace(SensorySettings settings) => state = settings;

  /// Persist current settings back to the student's Firestore record.
  /// Called from [SensorySettingsSheet] when the student taps Save.
  Future<void> saveToStudent(StudentRepository repo, String studentId) async {
    final student = await repo.getStudent(studentId);
    if (student == null) return;
    await repo.upsert(student.copyWith(sensorySettings: state));
  }
}

final sensorySettingsProvider =
    NotifierProvider<SensorySettingsController, SensorySettings>(
      SensorySettingsController.new,
    );
