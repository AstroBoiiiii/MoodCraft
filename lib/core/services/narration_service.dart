import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

// Native browser SpeechSynthesis on web; a no-op stub on mobile (so package:web
// never enters the Android build). dart.library.io is present only on native, so
// the default (web) file is used on web and overridden by the stub on mobile.
import 'narration_web.dart' if (dart.library.io) 'narration_web_stub.dart';

/// Reads short story/situation text aloud for the child (FR6 Mix-and-Match, and
/// the audio-first, "narration everywhere" design principle).
///
/// Calm and predictable: a slow, even voice, and tapping again restarts from the
/// beginning of the text. One utterance at a time. No audio files.
///
/// Two backends: on **web** the browser's `SpeechSynthesis` API directly (the
/// `flutter_tts` web plugin is unreliable in Chrome); on **Android** the
/// `flutter_tts` device engine. [prewarm] loads the web voice list up front so
/// the first tap speaks.
class NarrationService {
  NarrationService() {
    if (kIsWeb) {
      _web.setHandlers(
        onStart: () => speaking.value = true,
        onEnd: () => speaking.value = false,
      );
    } else {
      _tts = FlutterTts();
      _tts!
        ..setStartHandler(() => speaking.value = true)
        ..setCompletionHandler(() => speaking.value = false)
        ..setCancelHandler(() => speaking.value = false)
        ..setErrorHandler((_) => speaking.value = false);
    }
  }

  final WebSpeech _web = WebSpeech();
  FlutterTts? _tts; // mobile only

  /// True while narration is playing — drives the button's "playing" look.
  final ValueNotifier<bool> speaking = ValueNotifier(false);

  bool _ready = false;

  /// Loads voices / applies the calm voice settings once. Safe to call again
  /// (no-op after the first success). Call it when the activity opens so the
  /// first tap on a card speaks immediately.
  Future<void> prewarm() async {
    if (_ready) return;
    try {
      if (kIsWeb) {
        await _web.prewarm();
      } else {
        final tts = _tts!;
        await tts.awaitSpeakCompletion(true);
        await tts.setLanguage('en-US');
        await tts.setSpeechRate(0.45); // slow, gentle pace for young learners
        await tts.setPitch(1.0);
      }
      _ready = true;
    } catch (_) {
      // TTS unavailable — narration is an aid, never a blocker (text stays on
      // screen to read).
    }
  }

  /// Speaks [text] from the start. Any current narration is stopped first, so a
  /// second tap on the same card replays it from the beginning.
  Future<void> narrate(String text, {double volume = 1.0}) async {
    if (text.trim().isEmpty) return;
    final vol = volume.clamp(0.0, 1.0);
    try {
      await prewarm();
      if (kIsWeb) {
        // The browser API cancels + restarts internally — no settle delay.
        // Calm but natural pace; a neutral pitch avoids the uncanny low drone.
        _web.speak(text, volume: vol, rate: 0.95, pitch: 1.0);
      } else {
        final tts = _tts!;
        await tts.stop();
        await tts.setVolume(vol);
        await tts.speak(text);
      }
    } catch (_) {
      speaking.value = false;
    }
  }

  Future<void> stop() async {
    try {
      if (kIsWeb) {
        _web.stop();
      } else {
        await _tts?.stop();
      }
    } catch (_) {
      // Best-effort.
    }
    speaking.value = false;
  }

  void dispose() {
    if (kIsWeb) {
      _web.stop();
    } else {
      _tts?.stop();
    }
    speaking.dispose();
  }
}

final narrationServiceProvider = Provider<NarrationService>((ref) {
  final service = NarrationService();
  ref.onDispose(service.dispose);
  return service;
});
