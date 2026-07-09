import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';
import '../models/enums.dart';
import '../providers/repository_providers.dart';
import 'data/repositories.dart';

/// What the child just earned from finishing one activity round (FR11) — passed
/// to the calm celebration so it can show exactly the stars and any new badges.
/// [RewardOutcome.none] means nothing was granted (e.g. an offline read failed),
/// and the completion screen simply shows its warm "all done" with no stars.
class RewardOutcome {
  const RewardOutcome({
    this.starsEarned = 0,
    this.newBadges = const [],
    this.level = 1,
    this.leveledUp = false,
  });

  final int starsEarned;

  /// Badge ids newly earned this round (already excludes any earned before).
  final List<String> newBadges;

  /// The child's personal level after this round, and whether this round is the
  /// one that lifted them to it (crossed a 10-star boundary) — the celebration
  /// reveals the new title when [leveledUp] is true.
  final int level;
  final bool leveledUp;

  static const none = RewardOutcome();

  bool get isEmpty => starsEarned == 0 && newBadges.isEmpty;
}

/// The single place that grants rewards (FR11). Every activity calls
/// [awardForSession] once it has recorded a completed round, so the "when do you
/// earn a star" rule lives in exactly one spot.
///
/// Rewards are **participation-based**: finishing a round always grants
/// [kStarsPerRound], whatever the child answered — there is no way to lose a
/// star, so a reward can never turn into a fail state (design principle 1).
/// Story Mode is the one exception, trading per-episode stars for one bigger
/// [kStoryCompletionStars] payout on finishing the whole story. Accuracy is
/// still visible to the teacher separately via `Session.correctCount`/`retries`.
///
/// Badges focus purely on **finishing** (FR11): there is no reward for one round.
/// Each activity has a single badge, earned only when the child has worked all
/// the way through it. Every round still fills a progress bar (shown on the
/// child's Rewards wall) toward that badge. The caller owns the "is the whole
/// thing done" check for its activity and passes it as [activityCompleted], since
/// only the feature knows what "all of it" means.
class RewardsService {
  RewardsService(this._students);

  final StudentRepository _students;

  /// Grants [stars] (defaults to [kStarsPerRound]) for finishing a round and,
  /// when [activityCompleted] is true, the activity's completion badge (the
  /// first time it is fully done). Story Mode overrides [stars] to 0 for a
  /// mid-story episode and [kStoryCompletionStars] for the episode that
  /// finishes a whole story, instead of taking one per episode. A round that
  /// does not finish the whole activity earns stars (if any) but no badge — it
  /// only moves the progress bar. Best-effort: any read/write failure returns
  /// [RewardOutcome.none] and never blocks the child's completion moment (the
  /// Firestore cache syncs the write later, FR14).
  Future<RewardOutcome> awardForSession({
    required String studentId,
    required ActivityType activity,
    bool activityCompleted = false,
    int stars = kStarsPerRound,
  }) async {
    try {
      final student = await _students.getStudent(studentId);
      if (student == null) return RewardOutcome.none;

      final earned = <String>{...student.badges};
      final newBadges = <String>[];

      if (activityCompleted) {
        final badge = kActivityBadgeId[activity];
        if (badge != null && earned.add(badge)) {
          newBadges.add(badge);
        }
      }

      final newStars = student.stars + stars;
      final oldLevel = rewardLevel(student.stars);
      final newLevel = rewardLevel(newStars);
      // Keep prior order stable, just append the new ones (the wall orders
      // itself from kRewardBadges, so stored order is only for deterministic
      // round-trips).
      final badges = [...student.badges, ...newBadges];

      await _students.upsert(
        student.copyWith(stars: newStars, level: newLevel, badges: badges),
      );
      return RewardOutcome(
        starsEarned: stars,
        newBadges: newBadges,
        level: newLevel,
        leveledUp: newLevel > oldLevel,
      );
    } catch (_) {
      return RewardOutcome.none;
    }
  }
}

final rewardsServiceProvider = Provider<RewardsService>(
  (ref) => RewardsService(ref.watch(studentRepositoryProvider)),
);
