import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moodcraft/l10n/app_localizations.dart';

import '../../app/theme/tokens.dart';
import '../constants/app_constants.dart';
import '../models/enums.dart';
import '../services/rewards_service.dart';

/// Localised name for a reward badge (FR11). Feeling badges read as the feeling
/// ("Happy"), activity badges as the activity ("Stories"). Kept here so the
/// celebration, the Rewards wall and the progress card all label badges the same
/// way. Lives in core (no feature import) by resolving l10n keys directly.
String rewardBadgeLabel(RewardBadge badge, AppLocalizations l) {
  final emotion = badge.emotion;
  if (emotion != null) {
    return switch (emotion) {
      Emotion.happy => l.emotionHappy,
      Emotion.sad => l.emotionSad,
      Emotion.scared => l.emotionScared,
      Emotion.angry => l.emotionAngry,
      Emotion.surprised => l.emotionSurprised,
      Emotion.neutral => l.emotionOkay,
    };
  }
  return switch (badge.activity!) {
    ActivityType.story => l.navStories,
    ActivityType.mixmatch => l.navMatch,
    ActivityType.quiz => l.navQuiz,
    ActivityType.companion => l.navCompanion,
    ActivityType.ar => l.navAr,
  };
}

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
