import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moodcraft/l10n/app_localizations.dart';

import '../../app/theme/tokens.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/enums.dart';
import '../../core/models/session.dart';
import '../../core/widgets/section_card.dart';
import 'assignment_providers.dart';
import 'assignment_ui.dart';

/// FR8/FR11 tie-in — a calm, icon-led "things to do" card on the student home.
/// It gathers the activities still to finish across every task the child was
/// handed, and offers each as a big tap target that launches the activity. When
/// the child finishes one (records a session), it drops off on its own. The card
/// hides itself entirely when there is nothing left to do, so it never nags.
class StudentTodoCard extends ConsumerWidget {
  const StudentTodoCard({required this.studentId, super.key});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final tasks = ref.watch(studentAssignmentsProvider(studentId)).value;
    final sessions =
        ref.watch(studentSessionsProvider(studentId)).value ??
        const <Session>[];

    // Still loading, or nothing assigned — show nothing at all.
    if (tasks == null || tasks.isEmpty) return const SizedBox.shrink();

    // Union of activities that any task still needs done, in the app's usual
    // activity order so the list is stable and predictable.
    final pending = <ActivityType>{};
    for (final task in tasks) {
      for (final a in task.activities) {
        if (!activityDoneFor(
          assignment: task,
          activity: a,
          sessions: sessions,
        )) {
          pending.add(a);
        }
      }
    }
    final ordered = kAssignableActivities.where(pending.contains).toList();
    if (ordered.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: SectionCard(
        title: l.todoHeading,
        icon: Icons.checklist_rounded,
        child: Column(
          children: [
            for (final a in ordered)
              _TodoTile(
                activity: a,
                onTap: () => context.push(activityRoute(a)),
              ),
          ],
        ),
      ),
    );
  }
}

class _TodoTile extends StatelessWidget {
  const _TodoTile({required this.activity, required this.onTap});

  final ActivityType activity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final accent = activityAccent(activityAccentKey(activity));
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.md),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.20),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(activityIcon(activity), color: accent),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    activityLabel(activity, l),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Icon(Icons.play_circle_fill_rounded, color: accent, size: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
