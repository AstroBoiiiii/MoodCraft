/// Non-web stub for [WebSpeech]. Selected on native platforms (Android) via the
/// conditional import in `narration_service.dart`, so `package:web` is never
/// pulled into the mobile build. Mobile narration uses `flutter_tts` instead, so
/// none of these methods are ever called at runtime.
class WebSpeech {
  bool get isSupported => false;

  void setHandlers({void Function()? onStart, void Function()? onEnd}) {}

  Future<void> prewarm() async {}

  void speak(
    String text, {
    double volume = 1.0,
    double rate = 0.9,
    double pitch = 1.0,
  }) {}

  void stop() {}
}
