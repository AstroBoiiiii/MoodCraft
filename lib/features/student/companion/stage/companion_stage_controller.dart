/// Lets the companion screen talk to whichever stage is mounted, without
/// knowing the platform. The mobile stage binds real implementations once the
/// avatar (and its TTS key) are ready; the web stage never binds, so
/// [canSpeak] stays false and the screen keeps using device narration.
class CompanionStageController {
  Future<void> Function(String text)? _speak;
  void Function()? _stop;

  /// True when the mounted stage can voice lines itself (avatar + lip-sync).
  bool get canSpeak => _speak != null;

  Future<void> speak(String text) async {
    final speak = _speak;
    if (speak != null) await speak(text);
  }

  void stop() => _stop?.call();

  /// Called by the stage implementation; not for screen code.
  void bind({
    required Future<void> Function(String text) speak,
    required void Function() stop,
  }) {
    _speak = speak;
    _stop = stop;
  }

  void unbind() {
    _speak = null;
    _stop = null;
  }
}
