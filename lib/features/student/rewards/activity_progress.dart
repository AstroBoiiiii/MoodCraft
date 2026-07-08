import 'dart:math' as math;

import '../../../core/constants/app_constants.dart';
import '../../../core/models/enums.dart';
import '../../../core/models/student.dart';
import '../../story/story_data.dart';
import '../companion/companion_data.dart';

/// How far a child has moved through one whole activity (FR11). Rewards are
/// about *finishing*, not luck, so each activity fills a progress bar one
/// segment per completed round: a story episode, a Mix-and-Match card type, a
/// daily quiz set, or a companion feeling lesson. The activity's badge lights up
/// only when [isComplete] (the bar is full). Never a fail state: [done] only ever
/// grows, so a bar can never shrink.
class ActivityProgress {
  const ActivityProgress({
    required this.activity,
    required this.done,
    required this.total,
  });

  final ActivityType activity;

  /// Segments finished so far and the total segments in the whole activity.
  final int done;
  final int total;

  bool get isComplete => total > 0 && done >= total;

  /// 0..1 fill for the bar; safe when [total] is 0.
  double get fraction => total == 0 ? 0 : (done / total).clamp(0.0, 1.0);
}

int _storyEpisodesTotal() =>
    kStoryCatalog.fold(0, (sum, s) => sum + s.episodes.length);

int _storyEpisodesDone(Student student) => kStoryCatalog.fold(0, (sum, s) {
  final done = student.storyProgress[s.id]?.levelsDone ?? 0;
  return sum + math.min(done, s.episodes.length);
});

int _mixTypesDone(Student student) =>
    MixMatchType.values
        .where((t) => student.mixMatchRounds[t.name]?.isComplete ?? false)
        .length;

int _quizSetsDone(Student student) =>
    List.generate(
      kQuizSetCount,
      (i) => student.quizRounds['$i']?.isComplete ?? false,
    ).where((d) => d).length;

int _companionLessonsDone(Student student) {
  final done = student.companionLessonsDone.toSet();
  return kCompanionEmotions.where((e) => done.contains(e.name)).length;
}

/// The four activity progress bars for one child, in the same order as
/// [kBadgeActivities] so the wall and the badges line up.
List<ActivityProgress> studentActivityProgress(Student student) => [
  ActivityProgress(
    activity: ActivityType.story,
    done: _storyEpisodesDone(student),
    total: _storyEpisodesTotal(),
  ),
  ActivityProgress(
    activity: ActivityType.mixmatch,
    done: _mixTypesDone(student),
    total: MixMatchType.values.length,
  ),
  ActivityProgress(
    activity: ActivityType.quiz,
    done: _quizSetsDone(student),
    total: kQuizSetCount,
  ),
  ActivityProgress(
    activity: ActivityType.companion,
    done: _companionLessonsDone(student),
    total: kCompanionEmotions.length,
  ),
];
