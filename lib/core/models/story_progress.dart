/// A student's saved Story Mode progress for one story (FR5), persisted on the
/// student so episodes unlock in order and play resumes at the exact pause the
/// child left on, even after a sign-out.
///
/// [levelsDone] is how many episodes of the story are finished (0..episodes);
/// the next playable episode is `levels[levelsDone]`. [pausesDone] and
/// [positionMs] describe the in-progress frontier episode only: how many of its
/// pause questions are answered and where the video should resume. Replaying an
/// already-finished episode never touches any of these.
class StoryProgress {
  const StoryProgress({
    this.levelsDone = 0,
    this.pausesDone = 0,
    this.positionMs = 0,
  });

  final int levelsDone;
  final int pausesDone;
  final int positionMs;

  Map<String, dynamic> toJson() => {
    'levelsDone': levelsDone,
    'pausesDone': pausesDone,
    'positionMs': positionMs,
  };

  factory StoryProgress.fromJson(Map<String, dynamic> json) => StoryProgress(
    levelsDone: (json['levelsDone'] as num?)?.toInt() ?? 0,
    pausesDone: (json['pausesDone'] as num?)?.toInt() ?? 0,
    positionMs: (json['positionMs'] as num?)?.toInt() ?? 0,
  );
}

/// Parse a stored story-id → [StoryProgress] map defensively.
Map<String, StoryProgress> storyProgressFromJson(Object? value) {
  if (value is! Map) return const {};
  final out = <String, StoryProgress>{};
  value.forEach((k, v) {
    if (v is Map) {
      out[k.toString()] = StoryProgress.fromJson(Map<String, dynamic>.from(v));
    }
  });
  return out;
}
