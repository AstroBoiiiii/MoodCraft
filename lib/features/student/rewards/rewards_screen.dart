import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moodcraft/l10n/app_localizations.dart';

import '../../../app/theme/tokens.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/enums.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/widgets/calm_scaffold.dart';
import '../../../core/widgets/reward_celebration.dart' show rewardLevelTitle;
import '../../../core/widgets/sensory_settings_sheet.dart' show accountActions;
import 'activity_progress.dart';

/// FR11 — the child's calm Rewards wall. A growing star count at the top, then a
/// progress bar for each activity that fills up as the child works through it
/// (a story episode, a Mix-and-Match card type, a quiz set, a feeling lesson).
/// The activity's badge lights up only when its bar is full: finishing one round
/// is not an achievement, finishing the whole thing is. Nothing here compares the
/// child to anyone, nothing can go down, and nothing says "you can't".
/// It reads the live [activeStudentProvider], so progress made in an activity
/// shows here the moment the child comes back.
class StudentRewardsScreen extends ConsumerWidget {
  const StudentRewardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final student = ref.watch(activeStudentProvider).value;
    final stars = student?.stars ?? 0;
    final progress =
        student == null
            ? const <ActivityProgress>[]
            : studentActivityProgress(student);
    final earned = student?.badges.toSet() ?? const <String>{};
    final earnedCount =
        kRewardBadges.where((b) => earned.contains(b.id)).length;

    return CalmScaffold(
      title: l.navRewards,
      icon: Icons.star_rounded,
      actions: accountActions(context, ref),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            children: [
              // Two sections side by side: the star/title card and The Grand
              // Badge. IntrinsicHeight keeps both cards the same height.
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _StarTotal(stars: stars)),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _GrandBadgeCard(
                        earned: earnedCount,
                        total: kRewardBadges.length,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(l.rewardProgressTitle, style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.md),
              for (final p in progress) ...[
                _ActivityProgressRow(progress: p),
                const SizedBox(height: AppSpacing.md),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The big, warm star total at the top of the wall, with the child's current
/// level title and a calm bar toward the next one — the purpose the stars serve:
/// every 10 stars lifts the child to a new title (never a competition, never
/// lost). At the top of the ladder it simply celebrates the top title.
class _StarTotal extends StatelessWidget {
  const _StarTotal({required this.stars});

  final int stars;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    const gold = Color(0xFFE3B23C);
    final level = rewardLevel(stars);
    final atTop = isTopRewardLevel(level);
    final intoLevel = stars % kStarsPerLevel;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: gold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.star_rounded, size: 64, color: gold),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '$stars',
            style: theme.textTheme.displaySmall?.copyWith(
              color: gold,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(l.rewardStarTotal, style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.md),
          // The title: the reward the stars build toward.
          Text(
            rewardLevelTitle(level, l),
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: gold,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            l.rewardLevelLabel(level),
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (atTop)
            Text(
              l.rewardTopLevel,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(
                color: gold,
                fontWeight: FontWeight.w700,
              ),
            )
          else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.sm),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: intoLevel / kStarsPerLevel),
                duration: AppDurations.slow,
                curve: Curves.easeOut,
                builder:
                    (context, value, _) => LinearProgressIndicator(
                      value: value,
                      minHeight: 10,
                      backgroundColor: gold.withValues(alpha: 0.15),
                      valueColor: const AlwaysStoppedAnimation(gold),
                    ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l.rewardStarsToNext(starsToNextLevel(stars)),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// One activity's row: its badge on the left (a ring that fills with progress
/// and lights fully when done), and a soft progress bar with a calm "X of Y"
/// caption on the right. The whole thing eases up gently when new progress
/// arrives, never jumping (design principle 2).
class _ActivityProgressRow extends StatelessWidget {
  const _ActivityProgressRow({required this.progress});

  final ActivityProgress progress;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final accent = activityAccent(progress.activity.name);
    final done = progress.isComplete;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: done ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: accent.withValues(alpha: done ? 0.6 : 0.15),
          width: done ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          _FillingBadge(progress: progress, accent: accent),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _activityLabel(progress.activity, l),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (done)
                      Icon(Icons.check_circle_rounded, size: 22, color: accent),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progress.fraction),
                    duration: AppDurations.slow,
                    curve: Curves.easeOut,
                    builder:
                        (context, value, _) => LinearProgressIndicator(
                          value: value,
                          minHeight: 12,
                          backgroundColor: accent.withValues(alpha: 0.15),
                          valueColor: AlwaysStoppedAnimation(accent),
                        ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  done
                      ? l.rewardActivityDone
                      : l.rewardProgressCount(progress.done, progress.total),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: done ? accent : theme.colorScheme.onSurfaceVariant,
                    fontWeight: done ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The activity's badge, drawn as a circular ring that fills with the child's
/// progress. Grey and faint at zero, fully coloured with a soft glow when the
/// activity is finished — the badge "slowly filling up" as the child plays.
class _FillingBadge extends StatelessWidget {
  const _FillingBadge({required this.progress, required this.accent});

  final ActivityProgress progress;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final done = progress.isComplete;
    // Icon stays visible from the start but brightens as the bar fills.
    final iconAlpha = 0.35 + 0.65 * progress.fraction;
    return SizedBox(
      width: 60,
      height: 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress.fraction),
            duration: AppDurations.slow,
            curve: Curves.easeOut,
            builder:
                (context, value, _) => SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    value: value,
                    strokeWidth: 5,
                    backgroundColor: accent.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation(accent),
                  ),
                ),
          ),
          Icon(
            done
                ? Icons.emoji_events_rounded
                : kActivityBadgeIcon[progress.activity],
            size: 28,
            color: accent.withValues(alpha: done ? 1 : iconAlpha),
          ),
        ],
      ),
    );
  }
}

String _activityLabel(ActivityType t, AppLocalizations l) => switch (t) {
  ActivityType.story => l.navStories,
  ActivityType.mixmatch => l.navMatch,
  ActivityType.quiz => l.navQuiz,
  ActivityType.companion => l.navCompanion,
  ActivityType.ar => l.navAr,
};

/// The Grand Badge section (beside the star card): its title, the mythical
/// unlock hint, and the filling trophy. A gold card that mirrors the star card
/// so the two read as one pair of sections.
class _GrandBadgeCard extends StatelessWidget {
  const _GrandBadgeCard({required this.earned, required this.total});

  final int earned;
  final int total;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    const gold = Color(0xFFE3B23C);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: gold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            l.rewardTopBadgeTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l.rewardGrandBadgeHint,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _TopBadge(earned: earned, total: total),
        ],
      ),
    );
  }
}

/// The Grand Badge trophy itself: a single trophy that fills as the child
/// obtains each of the activity badges (0/4 → 4/4). Grey and faint until every
/// activity is finished, then a warm gold "you got them all". A ring shows how
/// many of the four badges are in, so it always feels close.
class _TopBadge extends StatelessWidget {
  const _TopBadge({required this.earned, required this.total});

  /// How many activity badges are earned, and how many there are in all.
  final int earned;
  final int total;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    const gold = Color(0xFFE3B23C);
    final complete = total > 0 && earned >= total;
    final fraction = total == 0 ? 0.0 : (earned / total).clamp(0.0, 1.0);
    final trophyColor =
        complete
            ? gold
            : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4);

    return Column(
      children: [
        SizedBox(
          width: 100,
          height: 100,
          child: Stack(
            alignment: Alignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: fraction),
                duration: AppDurations.slow,
                curve: Curves.easeOut,
                builder:
                    (context, value, _) => SizedBox(
                      width: 100,
                      height: 100,
                      child: CircularProgressIndicator(
                        value: value,
                        strokeWidth: 8,
                        backgroundColor: gold.withValues(alpha: 0.15),
                        valueColor: const AlwaysStoppedAnimation(gold),
                      ),
                    ),
              ),
              Icon(Icons.emoji_events_rounded, size: 52, color: trophyColor),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          complete ? l.rewardAllBadges : l.rewardBadgesCount(earned, total),
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            color: complete ? gold : theme.colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
