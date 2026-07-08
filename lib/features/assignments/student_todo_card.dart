import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moodcraft/l10n/app_localizations.dart';

import '../../app/theme/tokens.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/assignment.dart';
import '../../core/models/enums.dart';
import '../../core/models/session.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/widgets/section_card.dart';
import 'assignment_providers.dart';
import 'assignment_ui.dart';

/// FR8/FR11 tie-in — a calm, icon-led "things to do" card on the student home.
/// It gathers the activities still to finish across every task the child was
/// handed, and offers each as a big tap target that launches the activity. When
/// the child finishes one (records a session), it drops off on its own. The card
/// hides itself entirely when there is nothing left to do, so it never nags.
///
/// When the teacher hands out a task the child has not seen yet, a calm inline
/// banner announces it ("New task from your teacher!") — never a startling
/// popup, matching design principle 2. Tapping "Got it" dismisses it and
/// acknowledges every task handed out so far (`AppUser.seenTaskAt`), so it
/// only ever announces what is actually new.
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

    final unseen = ref.watch(studentUnseenTasksProvider(studentId));

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: SectionCard(
        title: l.todoHeading,
        icon: Icons.checklist_rounded,
        child: Column(
          children: [
            if (unseen.isNotEmpty) ...[
              _NewTaskBanner(onDismiss: () => _acknowledge(ref, tasks)),
              const SizedBox(height: AppSpacing.sm),
            ],
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

  /// Marks every task handed out so far as seen (the newest `createdAt` among
  /// them), clearing the banner. Best-effort: if the write fails the banner
  /// simply shows again next time, never blocking the child.
  Future<void> _acknowledge(WidgetRef ref, List<Assignment> tasks) async {
    final me = ref.read(currentUserDocProvider).value;
    if (me == null) return;
    final newestMs = tasks
        .map((t) => t.createdAt.millisecondsSinceEpoch)
        .reduce((a, b) => a > b ? a : b);
    try {
      await ref
          .read(userRepositoryProvider)
          .upsert(
            me.copyWith(seenTaskAt: {...me.seenTaskAt, studentId: newestMs}),
          );
    } catch (_) {
      // Best-effort — see doc comment above.
    }
  }
}

/// The calm "something new from your teacher" banner: an inline row (never a
/// popup) with a friendly icon, a short line, and a "Got it" tap to dismiss.
class _NewTaskBanner extends StatelessWidget {
  const _NewTaskBanner({required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final accent = activityAccent('rewards');
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Row(
        children: [
          Icon(Icons.notifications_active_rounded, color: accent),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              l.todoNewTaskBanner,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(onPressed: onDismiss, child: Text(l.todoNewTaskGotIt)),
        ],
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
