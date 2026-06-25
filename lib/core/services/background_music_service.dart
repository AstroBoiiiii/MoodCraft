import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_assets.dart';
import '../models/enums.dart';

// Gentle Piano (track3) is recorded quieter than the other tracks — boost it.
const Map<BackgroundTrack, double> _trackGain = {BackgroundTrack.track3: 1.2};

class BackgroundMusicService {
  final AudioPlayer _player = AudioPlayer();
  BackgroundTrack _currentTrack = BackgroundTrack.track1;

  // Gentle Piano has a long silent/quiet intro — skip past it.
  static const Map<BackgroundTrack, Duration> _trackStartOffset = {
    BackgroundTrack.track3: Duration(milliseconds: 22800),
  };

  Future<void> play(BackgroundTrack track, double volume) async {
    _currentTrack = track;
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.setVolume(_effectiveVolume(track, volume));
    await _player.play(AssetSource(_assetPath(track)));
    final offset = _trackStartOffset[track];
    if (offset != null) {
      await _player.seek(offset);
    }
  }

  Future<void> stop() async {
    await _player.stop();
  }

  Future<void> setVolume(double volume) async {
    await _player.setVolume(_effectiveVolume(_currentTrack, volume));
  }

  static double _effectiveVolume(BackgroundTrack track, double master) =>
      (master * (_trackGain[track] ?? 1.0)).clamp(0.0, 1.0);

  void dispose() {
    _player.dispose();
  }

  static String _assetPath(BackgroundTrack track) {
    // AssetSource expects the path relative to the assets/ directory.
    final full = switch (track) {
      BackgroundTrack.track1 => AppAssets.bgMusic1,
      BackgroundTrack.track2 => AppAssets.bgMusic2,
      BackgroundTrack.track3 => AppAssets.bgMusic3,
    };
    return full.replaceFirst('assets/', '');
  }
}

final backgroundMusicServiceProvider = Provider<BackgroundMusicService>((ref) {
  final service = BackgroundMusicService();
  ref.onDispose(service.dispose);
  return service;
});
