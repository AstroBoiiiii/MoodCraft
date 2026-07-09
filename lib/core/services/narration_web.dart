import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Web narration backed directly by the browser's `SpeechSynthesis` API.
///
/// We bypass `flutter_tts` on web because its plugin guards `speak()` on an
/// internal state, drops the first utterance while the voice list is still
/// loading, and runs pause/resume timers — all flaky in Chrome. Driving the
/// browser API ourselves is predictable: cancel, build an utterance, speak.
class WebSpeech {
  /// Warm, natural-sounding voices, most-preferred first. Matched by name
  /// substring (case-insensitive) so small naming variations still hit. The aim
  /// is to avoid the flat, robotic default (eSpeak-style) that reads as creepy,
  /// and land on a calm, clear voice wherever one is installed.
  static const List<String> _preferredVoices = [
    'google us english', // Chrome desktop: network-backed, natural
    'microsoft aria', // Windows natural (online)
    'microsoft jenny', // Windows natural (online)
    'samantha', // macOS: warm and clear
    'google uk english female',
    'microsoft zira', // Windows local female, decent
    'microsoft michelle',
    'karen', // macOS
  ];

  web.SpeechSynthesis get _synth => web.window.speechSynthesis;

  void Function()? _onStart;
  void Function()? _onEnd;

  bool get isSupported => true;

  void setHandlers({void Function()? onStart, void Function()? onEnd}) {
    _onStart = onStart;
    _onEnd = onEnd;
  }

  /// Chrome loads its voice list asynchronously; the first `getVoices()` is
  /// empty. Poll briefly so an English voice is available before the first tap.
  Future<void> prewarm() async {
    var voices = _synth.getVoices().toDart;
    for (var i = 0; i < 20 && voices.isEmpty; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      voices = _synth.getVoices().toDart;
    }
  }

  void speak(
    String text, {
    double volume = 1.0,
    double rate = 0.9,
    double pitch = 1.0,
  }) {
    // Cancel anything in flight so a repeat tap restarts from the beginning.
    _synth.cancel();

    final utterance =
        web.SpeechSynthesisUtterance(text)
          ..lang = 'en-US'
          ..volume = volume
          ..rate = rate
          ..pitch = pitch;

    final voice = _pickVoice();
    if (voice != null) {
      utterance.voice = voice;
      utterance.lang = voice.lang;
    }

    utterance.onstart = ((web.Event _) => _onStart?.call()).toJS;
    utterance.onend = ((web.Event _) => _onEnd?.call()).toJS;
    utterance.onerror = ((web.Event _) => _onEnd?.call()).toJS;

    _synth.speak(utterance);
  }

  void stop() {
    _synth.cancel();
    _onEnd?.call();
  }

  /// Chooses the warmest available voice: first any [_preferredVoices] match by
  /// name, then any US English, then any English, then whatever exists.
  web.SpeechSynthesisVoice? _pickVoice() {
    final voices = _synth.getVoices().toDart;
    if (voices.isEmpty) return null;
    for (final wanted in _preferredVoices) {
      for (final voice in voices) {
        if (voice.name.toLowerCase().contains(wanted)) return voice;
      }
    }
    for (final voice in voices) {
      if (voice.lang.toLowerCase().startsWith('en-us')) return voice;
    }
    for (final voice in voices) {
      if (voice.lang.toLowerCase().startsWith('en')) return voice;
    }
    return voices.first;
  }
}
