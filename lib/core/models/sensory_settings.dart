import 'enums.dart';

/// Per-student sensory preferences. Every activity must respect these
/// (CLAUDE.md sections 4 & 8). Immutable with value equality so Riverpod can
/// minimise rebuilds when settings are unchanged.
class SensorySettings {
  const SensorySettings({
    this.musicEnabled = false,
    this.masterVolume = 0.6,
    this.colorTheme = AppColorTheme.calmBlue,
    this.animationIntensity = AnimationIntensity.full,
    this.backgroundTrack = BackgroundTrack.track1,
  });

  /// Calm-by-default settings (music off, gentle volume).
  static const SensorySettings defaults = SensorySettings();

  final bool musicEnabled;

  /// 0.0–1.0.
  final double masterVolume;
  final AppColorTheme colorTheme;
  final AnimationIntensity animationIntensity;

  /// Which of the three background music tracks is selected.
  final BackgroundTrack backgroundTrack;

  SensorySettings copyWith({
    bool? musicEnabled,
    double? masterVolume,
    AppColorTheme? colorTheme,
    AnimationIntensity? animationIntensity,
    BackgroundTrack? backgroundTrack,
  }) {
    return SensorySettings(
      musicEnabled: musicEnabled ?? this.musicEnabled,
      masterVolume: masterVolume ?? this.masterVolume,
      colorTheme: colorTheme ?? this.colorTheme,
      animationIntensity: animationIntensity ?? this.animationIntensity,
      backgroundTrack: backgroundTrack ?? this.backgroundTrack,
    );
  }

  Map<String, dynamic> toJson() => {
    'musicEnabled': musicEnabled,
    'masterVolume': masterVolume,
    'colorTheme': colorTheme.name,
    'animationIntensity': animationIntensity.name,
    'backgroundTrack': backgroundTrack.name,
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
      animationIntensity: enumFromName(
        AnimationIntensity.values,
        json['animationIntensity'],
        AnimationIntensity.full,
      ),
      backgroundTrack: enumFromName(
        BackgroundTrack.values,
        json['backgroundTrack'],
        BackgroundTrack.track1,
      ),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SensorySettings &&
      other.musicEnabled == musicEnabled &&
      other.masterVolume == masterVolume &&
      other.colorTheme == colorTheme &&
      other.animationIntensity == animationIntensity &&
      other.backgroundTrack == backgroundTrack;

  @override
  int get hashCode => Object.hash(
    musicEnabled,
    masterVolume,
    colorTheme,
    animationIntensity,
    backgroundTrack,
  );
}
