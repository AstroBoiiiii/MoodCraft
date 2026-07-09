import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Plays the short "listen" sound cues for the stress-free quiz (FR7). Separate
/// from the TTS narration service: these are real audio clips
/// bundled under `assets/audio/cues/`, played through `audioplayers` on both
/// web and Android. One clip at a time; a second tap replays from the start.
///
/// Calm by design: the child taps to play — a cue never autoplays on its own.
class SoundCueService {
  final AudioPlayer _player = AudioPlayer();

  // Per-cue loudness lift for clips that sit quieter than the rest, keyed by the
  // `<emotion>` token in the filename. None need a lift right now; add an entry
  // (e.g. {'sad': 1.3}) only if a clip plays noticeably quiet.
  static const Map<String, double> _cueGain = {};

  /// True while a cue is playing — drives the Listen button's "playing" look.
  final ValueNotifier<bool> playing = ValueNotifier(false);

  SoundCueService() {
    _player.onPlayerComplete.listen((_) => playing.value = false);
  }

  /// Plays the clip at [assetPath] (a full `assets/...` path) from the start at
  /// the student's master [volume]. Best-effort: a missing/unsupported clip just
  /// leaves the button idle, never throws into the activity.
  Future<void> play(String assetPath, {double volume = 1.0}) async {
    try {
      await _player.stop();
      await _player.setVolume((volume * _gainFor(assetPath)).clamp(0.0, 1.0));
      // AssetSource expects the path relative to assets/.
      await _player.play(AssetSource(assetPath.replaceFirst('assets/', '')));
      playing.value = true;
    } catch (_) {
      playing.value = false;
    }
  }

  /// Per-cue loudness lift from the filename's `<emotion>` token (1.0 = none).
  double _gainFor(String assetPath) {
    var file = assetPath.split('/').last;
    final dot = file.lastIndexOf('.');
    if (dot > 0) file = file.substring(0, dot);
    final token = file.split('_').first.toLowerCase();
    return _cueGain[token] ?? 1.0;
  }

  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {
      // Best-effort.
    }
    playing.value = false;
  }

  void dispose() {
    _player.dispose();
    playing.dispose();
  }
}

final soundCueServiceProvider = Provider<SoundCueService>((ref) {
  final service = SoundCueService();
  ref.onDispose(service.dispose);
  return service;
});
