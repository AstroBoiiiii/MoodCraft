/// Centralised asset paths. Per CLAUDE.md section 9 (placeholders first), every
/// asset path lives here so swapping real art for placeholders is a one-file
/// change with zero edits at call sites.
library;

class AppAssets {
  AppAssets._();

  // Base directories (registered in pubspec.yaml).
  static const String _rive = 'assets/rive';
  static const String _models = 'assets/models';
  static const String _images = 'assets/images';
  static const String _audio = 'assets/audio';

  /// 2D companion character (Rive). Placeholder until real art lands; the app
  /// drives expressions by state-machine input name, not by file, so the real
  /// character drops in by matching input names.
  static const String companionRive = '$_rive/companion.riv';
  static const String companionStateMachine = 'CompanionState';

  /// Default 3D model for AR (placeholder primitive until real .glb art lands).
  static const String arPlaceholderModel = '$_models/placeholder.glb';

  // Generic placeholders.
  static const String imagesDir = _images;
  static const String audioDir = _audio;
}
