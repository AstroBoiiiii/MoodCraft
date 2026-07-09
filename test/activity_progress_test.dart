import 'package:flutter_test/flutter_test.dart';
import 'package:moodcraft/core/constants/app_constants.dart';
import 'package:moodcraft/core/models/enums.dart';
import 'package:moodcraft/core/models/mix_match_round.dart';
import 'package:moodcraft/core/models/story_progress.dart';
import 'package:moodcraft/core/models/student.dart';
import 'package:moodcraft/features/story/story_data.dart';
import 'package:moodcraft/features/student/companion/companion_data.dart';
import 'package:moodcraft/features/student/rewards/activity_progress.dart';

/// The child's Rewards wall fills one bar segment per finished round and only
/// lights the badge when the bar is full (FR11 — completion, not luck).
void main() {
  ActivityProgress forActivity(Student s, ActivityType a) =>
      studentActivityProgress(s).firstWhere((p) => p.activity == a);

  test('an empty student has every bar at zero, none complete', () {
    const s = Student(id: 's1', name: 'A');
    final all = studentActivityProgress(s);
    expect(all.length, kBadgeActivities.length);
    for (final p in all) {
      expect(p.done, 0);
      expect(p.total, greaterThan(0));
      expect(p.isComplete, isFalse);
      expect(p.fraction, 0);
    }
  });

  test('mix-and-match fills one segment per completed card type', () {
    const complete = MixMatchRound(
      cards: [MixMatchRoundCard(answer: Emotion.happy)],
      placed: 1,
    );
    const inProgress = MixMatchRound(
      cards: [MixMatchRoundCard(answer: Emotion.happy)],
      placed: 0,
    );
    final s = Student(
      id: 's1',
      name: 'A',
      mixMatchRounds: {
        MixMatchType.face.name: complete,
        MixMatchType.body.name: inProgress,
      },
    );
    final p = forActivity(s, ActivityType.mixmatch);
    expect(p.total, MixMatchType.values.length);
    expect(p.done, 1); // only the finished type counts
    expect(p.isComplete, isFalse);
  });

  test('companion completes only when every feeling lesson is done', () {
    final s = Student(
      id: 's1',
      name: 'A',
      companionLessonsDone: kCompanionEmotions.map((e) => e.name).toList(),
    );
    final p = forActivity(s, ActivityType.companion);
    expect(p.done, kCompanionEmotions.length);
    expect(p.isComplete, isTrue);
    expect(p.fraction, 1);
  });

  test('story counts finished episodes across the catalog, clamped', () {
    final first = kStoryCatalog.first;
    final s = Student(
      id: 's1',
      name: 'A',
      storyProgress: {
        first.id: StoryProgress(levelsDone: first.episodes.length + 5),
      },
    );
    final p = forActivity(s, ActivityType.story);
    expect(p.done, first.episodes.length); // clamped, never over-counts
    expect(p.total, greaterThanOrEqualTo(first.episodes.length));
  });
}
