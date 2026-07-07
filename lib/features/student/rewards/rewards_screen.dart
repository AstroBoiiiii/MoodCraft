import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moodcraft/l10n/app_localizations.dart';

import '../../../app/theme/tokens.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/widgets/calm_scaffold.dart';
import '../../../core/widgets/reward_celebration.dart' show rewardBadgeLabel;
import '../../../core/widgets/sensory_settings_sheet.dart' show accountActions;

/// FR11 — the child's calm Rewards wall. A growing star count at the top, then a
/// collection of badges: earned ones in their colour, not-yet-earned ones as a
/// soft grey shape (never a lock — nothing here says "you can't"). There is no
/// comparison to other children, no score to beat, nothing that can go down.
/// It reads the live [activeStudentProvider], so a star earned in an activity
/// shows here the moment the child comes back.
class StudentRewardsScreen extends ConsumerWidget {
  const StudentRewardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final student = ref.watch(activeStudentProvider).value;
    final stars = student?.stars ?? 0;
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
              _StarTotal(stars: stars),
              const SizedBox(height: AppSpacing.lg),
              Text(l.rewardBadgesTitle, style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l.rewardBadgesCount(earnedCount, kRewardBadges.length),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _BadgeWall(earned: earned),
              // Dev-only: clear stars + badges back to zero for testing (stars
              // never drop in normal play). Compiled out of release/demo builds.
              if (kDebugMode && student != null) ...[
                const SizedBox(height: AppSpacing.lg),
                Center(
                  child: TextButton.icon(
                    onPressed:
                        () => ref
                            .read(studentRepositoryProvider)
                            .upsert(
                              student.copyWith(
                                stars: 0,
                                level: 1,
                                badges: const [],
                              ),
                            ),
                    icon: const Icon(Icons.restart_alt_rounded),
                    label: const Text('Reset rewards (dev)'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The big, warm star total at the top of the wall.
class _StarTotal extends StatelessWidget {
  const _StarTotal({required this.stars});

  final int stars;

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
          const SizedBox(height: AppSpacing.xs),
          Text(
            l.rewardStarTotal,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

/// The badge collection grid: every badge in [kRewardBadges], drawn in its
/// colour when earned and as a soft grey shape when not.
class _BadgeWall extends StatelessWidget {
  const _BadgeWall({required this.earned});

  final Set<String> earned;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      childAspectRatio: 0.85,
      children: [
        for (final badge in kRewardBadges)
          _BadgeTile(badge: badge, earned: earned.contains(badge.id)),
      ],
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.badge, required this.earned});

  final RewardBadge badge;
  final bool earned;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final color = earned ? badge.color : muted;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: color.withValues(alpha: earned ? 0.18 : 0.08),
            shape: BoxShape.circle,
            border: Border.all(
              color: color.withValues(alpha: earned ? 0.7 : 0.3),
              width: 2,
            ),
          ),
          child: Icon(badge.icon, size: 38, color: color),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          rewardBadgeLabel(badge, l),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelLarge?.copyWith(
            color: earned ? theme.colorScheme.onSurface : muted,
            fontWeight: earned ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
