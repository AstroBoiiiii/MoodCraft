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
  const RewardOutcome({this.starsEarned = 0, this.newBadges = const []});

  final int starsEarned;

  /// Badge ids newly earned this round (already excludes any earned before).
  final List<String> newBadges;

  static const none = RewardOutcome();

  bool get isEmpty => starsEarned == 0 && newBadges.isEmpty;
}

/// The single place that grants rewards (FR11). Every activity calls
/// [awardForSession] once it has recorded a completed round, so the "when do you
/// earn a star" rule lives in exactly one spot.
///
/// Rewards are **participation-based**: finishing a round always grants
/// [kStarsPerRound], never anything less, whatever the child answered — there is
/// no way to lose a star, so a reward can never turn into a fail state (design
/// principle 1). Accuracy is still visible to the teacher separately via
/// `Session.correctCount`/`retries`.
class RewardsService {
  RewardsService(this._students);

  final StudentRepository _students;

  /// Grants [kStarsPerRound] and any newly-qualified badges for a finished
  /// round: the activity's badge (first completion of that activity) and a
  /// feeling badge for each of [emotionsShown] not yet earned. Best-effort — any
  /// read/write failure returns [RewardOutcome.none] and never blocks the
  /// child's completion moment (the Firestore cache syncs the write later, FR14).
  Future<RewardOutcome> awardForSession({
    required String studentId,
    required ActivityType activity,
    required List<Emotion> emotionsShown,
  }) async {
    try {
      final student = await _students.getStudent(studentId);
      if (student == null) return RewardOutcome.none;

      final earned = <String>{...student.badges};
      final newBadges = <String>[];

      final activityBadge = kActivityBadgeId[activity];
      if (activityBadge != null && earned.add(activityBadge)) {
        newBadges.add(activityBadge);
      }
      for (final emotion in emotionsShown) {
        final feelingBadge = kFeelingBadgeId[emotion];
        if (feelingBadge != null && earned.add(feelingBadge)) {
          newBadges.add(feelingBadge);
        }
      }

      final newStars = student.stars + kStarsPerRound;
      // Keep prior order stable, just append the new ones (the wall orders
      // itself from kRewardBadges, so stored order is only for deterministic
      // round-trips).
      final badges = [...student.badges, ...newBadges];

      await _students.upsert(
        student.copyWith(
          stars: newStars,
          level: rewardLevel(newStars),
          badges: badges,
        ),
      );
      return RewardOutcome(starsEarned: kStarsPerRound, newBadges: newBadges);
    } catch (_) {
      return RewardOutcome.none;
    }
  }
}

final rewardsServiceProvider = Provider<RewardsService>(
  (ref) => RewardsService(ref.watch(studentRepositoryProvider)),
);
