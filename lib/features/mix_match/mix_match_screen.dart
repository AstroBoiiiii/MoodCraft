import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moodcraft/l10n/app_localizations.dart';

import '../../app/theme/tokens.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/mix_match_round.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/widgets/calm_scaffold.dart';
import '../../core/widgets/sensory_settings_sheet.dart' show accountActions;

/// Arguments for the Mix-and-Match play route. [studentId] null = teacher
/// classroom/projection mode (no session, no count bump).
typedef MixMatchArgs = ({MixMatchType type, String? studentId});

/// FR6 entry screen for the student: pick a way to match feelings. The four card
/// types (faces → bodies → situations → short stories, concrete → abstract) are
/// all open — there's no level gate. A calm count shows how many rounds the
/// child has finished so far. Never a fail or lock state.
class MixMatchHomeScreen extends ConsumerWidget {
  const MixMatchHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final student = ref.watch(activeStudentProvider).value;

    return CalmScaffold(
      title: l.navMatch,
      icon: Icons.extension_rounded,
      actions: accountActions(context, ref),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            children: [
              Text(l.mixMatchIntro, style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.md),
              _OverallProgress(rounds: student?.mixMatchRounds ?? const {}),
              const SizedBox(height: AppSpacing.md),
              MixMatchTypeGrid(
                progressFor:
                    (type) => student?.mixMatchRounds[type.name]?.placed ?? 0,
                onPick: (type) {
                  if (student == null) return;
                  context.push(
                    '/student/mixmatch/play',
                    extra: (type: type, studentId: student.id),
                  );
                },
              ),
              // Dev-only: clear all category progress back to 0/5. Hidden in
              // release/demo builds.
              if (kDebugMode && student != null) ...[
                const SizedBox(height: AppSpacing.lg),
                Center(
                  child: TextButton.icon(
                    onPressed:
                        () => ref
                            .read(studentRepositoryProvider)
                            .upsert(student.copyWith(mixMatchRounds: {})),
                    icon: const Icon(Icons.restart_alt_rounded),
                    label: const Text('Reset progress (dev)'),
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

/// Overall "complete everything to earn badges" bar across all card types
/// (4 types × [kMixMatchRoundSize] = the total). A gentle goal toward the FR11
/// rewards pass — no pressure, just shows how far along the child is.
class _OverallProgress extends StatelessWidget {
  const _OverallProgress({required this.rounds});

  final Map<String, MixMatchRound> rounds;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final accent = activityAccent('mixmatch');
    final total = MixMatchType.values.length * kMixMatchRoundSize;
    var done = 0;
    for (final type in MixMatchType.values) {
      done += (rounds[type.name]?.placed ?? 0).clamp(0, kMixMatchRoundSize);
    }
    final complete = done >= total;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events_rounded, size: 22, color: accent),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  complete ? l.mixMatchAllDoneHint : l.mixMatchBadgeHint,
                  style: theme.textTheme.labelLarge?.copyWith(color: accent),
                ),
              ),
              Text(
                '$done/$total',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.sm),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : done / total,
              minHeight: 10,
              backgroundColor: accent.withValues(alpha: 0.18),
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
        ],
      ),
    );
  }
}

/// Reusable 2-column grid of the four Mix-and-Match card types. Shared by the
/// student picker and the teacher's classroom launcher. All types are always
/// tappable — no level gating.
///
/// [progressFor] returns how many of the round's [kMixMatchRoundSize] cards the
/// child has done in that category, shown on the tile as "X/5". Null (the
/// teacher's classroom launcher) hides the count.
class MixMatchTypeGrid extends StatelessWidget {
  const MixMatchTypeGrid({required this.onPick, this.progressFor, super.key});

  final void Function(MixMatchType type) onPick;
  final int Function(MixMatchType type)? progressFor;

  @override
  Widget build(BuildContext context) {
    // Fixed tile height (taller when the "X/5" count is shown) so tiles stay
    // compact on a wide window instead of growing into big empty squares.
    final tileHeight = progressFor != null ? 168.0 : 140.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth = (constraints.maxWidth - AppSpacing.md) / 2;
        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: tileWidth / tileHeight,
          children: [
            for (final type in MixMatchType.values)
              _TypeTile(
                type: type,
                onTap: () => onPick(type),
                progress: progressFor?.call(type),
              ),
          ],
        );
      },
    );
  }
}

class _TypeTile extends StatelessWidget {
  const _TypeTile({required this.type, required this.onTap, this.progress});

  final MixMatchType type;
  final VoidCallback onTap;

  /// Cards done in this category (0–[kMixMatchRoundSize]); null hides the count.
  final int? progress;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final accent = activityAccent('mixmatch');
    final done = progress != null && progress! >= kMixMatchRoundSize;
    final surface = theme.colorScheme.surface;
    final wash = Color.alphaBlend(accent.withValues(alpha: 0.10), surface);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [wash, surface],
          ),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: accent.withValues(alpha: 0.35), width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(mixMatchTypeIcon(type), size: 30, color: accent),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                mixMatchTypeLabel(type, l),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
              if (progress != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (done)
                      Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.xs),
                        child: Icon(
                          Icons.check_circle_rounded,
                          size: 16,
                          color: accent,
                        ),
                      ),
                    Text(
                      '$progress/$kMixMatchRoundSize',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Friendly label for a card type.
String mixMatchTypeLabel(MixMatchType type, AppLocalizations l) =>
    switch (type) {
      MixMatchType.face => l.mixMatchTypeFace,
      MixMatchType.body => l.mixMatchTypeBody,
      MixMatchType.situation => l.mixMatchTypeSituation,
      MixMatchType.story => l.mixMatchTypeStory,
    };

/// Placeholder icon per card type (real art swaps in later).
IconData mixMatchTypeIcon(MixMatchType type) => switch (type) {
  MixMatchType.face => Icons.face_rounded,
  MixMatchType.body => Icons.accessibility_new_rounded,
  MixMatchType.situation => Icons.image_rounded,
  MixMatchType.story => Icons.menu_book_rounded,
};
