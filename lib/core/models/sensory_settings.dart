import 'enums.dart';

/// Per-student sensory preferences. Every activity must respect these
/// (CLAUDE.md sections 4 & 8). Immutable with value equality so Riverpod can
/// minimise rebuilds when settings are unchanged.
class SensorySettings {
  const SensorySettings({
    this.musicEnabled = false,
    this.masterVolume = 0.6,
    this.colorTheme = AppColorTheme.calmBlue,
    this.backgroundTrack = BackgroundTrack.track1,
    this.quizFeedbackNarration = true,
  });

  /// Calm-by-default settings (music off, gentle volume).
  static const SensorySettings defaults = SensorySettings();

  final bool musicEnabled;

  /// 0.0–1.0.
  final double masterVolume;
  final AppColorTheme colorTheme;

  /// Which of the three background music tracks is selected.
  final BackgroundTrack backgroundTrack;
  final bool quizFeedbackNarration;

  SensorySettings copyWith({
    bool? musicEnabled,
    double? masterVolume,
    AppColorTheme? colorTheme,
    BackgroundTrack? backgroundTrack,
    bool? quizFeedbackNarration,
  }) {
    return SensorySettings(
      musicEnabled: musicEnabled ?? this.musicEnabled,
      masterVolume: masterVolume ?? this.masterVolume,
      colorTheme: colorTheme ?? this.colorTheme,
      backgroundTrack: backgroundTrack ?? this.backgroundTrack,
      quizFeedbackNarration:
          quizFeedbackNarration ?? this.quizFeedbackNarration,
    );
  }

  Map<String, dynamic> toJson() => {
    'musicEnabled': musicEnabled,
    'masterVolume': masterVolume,
    'colorTheme': colorTheme.name,
    'backgroundTrack': backgroundTrack.name,
    'quizFeedbackNarration': quizFeedbackNarration,
  };

  factory SensorySettings.fromJson(Map<String, dynamic>? json) {
    if (json == null) return defaults;
    return SensorySettings(
      musicEnabled: (json['musicEnabled'] as bool?) ?? false,
      masterVolume: (json['masterVolume'] as num?)?.toDouble() ?? 0.6,
      colorTheme: enumFromName(
        AppColorTheme.values,
        json['colorTheme'],
        AppColorTheme.calmBlue,
      ),
      backgroundTrack: enumFromName(
        BackgroundTrack.values,
        json['backgroundTrack'],
        BackgroundTrack.track1,
      ),
      quizFeedbackNarration: (json['quizFeedbackNarration'] as bool?) ?? true,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SensorySettings &&
      other.musicEnabled == musicEnabled &&
      other.masterVolume == masterVolume &&
      other.colorTheme == colorTheme &&
      other.backgroundTrack == backgroundTrack &&
      other.quizFeedbackNarration == quizFeedbackNarration;

  @override
  int get hashCode => Object.hash(
    musicEnabled,
    masterVolume,
    colorTheme,
    backgroundTrack,
    quizFeedbackNarration,
  );
}
