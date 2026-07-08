import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moodcraft/l10n/app_localizations.dart';

import '../../app/theme/tokens.dart';
import '../constants/app_constants.dart';
import '../models/enums.dart';
import '../services/rewards_service.dart';

/// Localised name for a reward badge (FR11). One badge per activity, earned by
/// finishing all of it, so it reads as the whole thing ("All Stories"). Kept
/// here so the celebration, the Rewards wall and the progress card all label
/// badges the same way. Lives in core (no feature import) by resolving l10n keys
/// directly.
String rewardBadgeLabel(RewardBadge badge, AppLocalizations l) {
  return switch (badge.activity) {
    ActivityType.story => l.rewardBadgeAllStories,
    ActivityType.mixmatch => l.rewardBadgeAllMatched,
    ActivityType.quiz => l.rewardBadgeAllQuizzes,
    ActivityType.companion => l.rewardBadgeAllFeelings,
    ActivityType.ar => l.navAr,
  };
}

/// The child's title for a personal [level] (FR11) — the reward that gives
/// stars a purpose: every 10 stars lifts them up the ladder. Capped at the top
/// title so there is always a name. Resolves l10n keys directly so it can be
/// used by both the Rewards wall and the celebration.
String rewardLevelTitle(int level, AppLocalizations l) =>
    switch (rewardTitleIndex(level)) {
      0 => l.rewardTitle1,
      1 => l.rewardTitle2,
      2 => l.rewardTitle3,
      3 => l.rewardTitle4,
      4 => l.rewardTitle5,
      5 => l.rewardTitle6,
      6 => l.rewardTitle7,
      _ => l.rewardTitle8,
    };

/// Find a badge in the taxonomy by id (used to render a just-earned badge).
RewardBadge? rewardBadgeById(String id) {
  for (final b in kRewardBadges) {
    if (b.id == id) return b;
  }
  return null;
}

/// The calm completion moment shown when a child finishes an activity round
/// (FR11). It keeps the same warm "all done" as before, and *adds* the stars
/// just earned and a soft reveal of any new badge. Nothing flashes and nothing
/// is ever taken away — a gentle, predictable celebration (design principles 1
/// and 2).
///
/// [outcome] null means the award is still being written (or failed offline): the
/// moment shows without stars, never blocking the child.
class RewardCelebration extends ConsumerStatefulWidget {
  const RewardCelebration({
    required this.outcome,
    required this.title,
    required this.body,
    required this.doneLabel,
    required this.onDone,
    this.secondaryLabel,
    this.onSecondary,
    super.key,
  });

  final RewardOutcome? outcome;
  final String title;
  final String body;
  final String doneLabel;
  final VoidCallback onDone;

  /// Optional extra action above Done (e.g. Story's "Next Episode").
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  ConsumerState<RewardCelebration> createState() => _RewardCelebrationState();
}

class _RewardCelebrationState extends ConsumerState<RewardCelebration> {
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    // Animate in on the next frame so the gentle fade/scale plays once.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _shown = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    const motion = AppDurations.slow;
    final outcome = widget.outcome;
    final newBadges = [
      for (final id in outcome?.newBadges ?? const <String>[])
        if (rewardBadgeById(id) != null) rewardBadgeById(id)!,
    ];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: AnimatedOpacity(
          opacity: _shown ? 1 : 0,
          duration: motion,
          curve: Curves.easeOut,
          child: AnimatedScale(
            scale: _shown ? 1 : 0.9,
            duration: motion,
            curve: Curves.easeOut,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 88,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  widget.title,
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  widget.body,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (outcome != null && outcome.starsEarned > 0) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _StarsRow(
                    count: outcome.starsEarned,
                    label: l.rewardStarsEarned(outcome.starsEarned),
                  ),
                ],
                if (outcome != null && outcome.leveledUp) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _LevelUp(title: rewardLevelTitle(outcome.level, l)),
                ],
                if (newBadges.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    l.rewardNewBadge,
                    style: theme.textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final badge in newBadges)
                        _BadgeChip(
                          badge: badge,
                          label: rewardBadgeLabel(badge, l),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                if (widget.secondaryLabel != null &&
                    widget.onSecondary != null) ...[
                  FilledButton(
                    onPressed: widget.onSecondary,
                    child: Text(widget.secondaryLabel!),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  FilledButton.tonal(
                    onPressed: widget.onDone,
                    child: Text(widget.doneLabel),
                  ),
                ] else
                  FilledButton(
                    onPressed: widget.onDone,
                    child: Text(widget.doneLabel),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A soft row of star icons for the stars just earned, with a calm caption.
class _StarsRow extends StatelessWidget {
  const _StarsRow({required this.count, required this.label});

  final int count;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const gold = Color(0xFFE3B23C);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < count; i++)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: Icon(Icons.star_rounded, size: 40, color: gold),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: theme.textTheme.titleMedium?.copyWith(
            color: gold,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// The gentle "you reached a new title" reveal, shown when a round lifts the
/// child to a new level. A soft medal, the warm "New title!" line, and the title.
class _LevelUp extends StatelessWidget {
  const _LevelUp({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    const gold = Color(0xFFE3B23C);
    return Column(
      children: [
        const Icon(Icons.military_tech_rounded, size: 44, color: gold),
        const SizedBox(height: AppSpacing.xs),
        Text(l.rewardNewTitle, style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: gold,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

/// A newly-earned badge shown as its coloured icon plus its name.
class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.badge, required this.label});

  final RewardBadge badge;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: badge.color.withValues(alpha: 0.18),
            shape: BoxShape.circle,
            border: Border.all(
              color: badge.color.withValues(alpha: 0.6),
              width: 2,
            ),
          ),
          child: Icon(badge.icon, size: 34, color: badge.color),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(color: badge.color),
        ),
      ],
    );
  }
}
