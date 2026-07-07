import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moodcraft/l10n/app_localizations.dart';

import '../../app/theme/tokens.dart';
import '../../core/models/assignment.dart';
import '../../core/models/session.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/widgets/calm_scaffold.dart';
import '../../core/widgets/constrained_content.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/sensory_settings_sheet.dart';
import 'assignment_providers.dart';
import 'assignment_ui.dart';

/// FR9/FR10 — the parent's view of homework: every task the teacher handed their
/// child (announcement or personal), with a live tick per activity showing what
/// the child has already finished. Read-only; completion tracks the child's own
/// play, so there is nothing for the parent to mark.
class ParentTasksScreen extends ConsumerWidget {
  const ParentTasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final childAsync = ref.watch(activeStudentProvider);

    return CalmScaffold(
      title: l.navTasks,
      icon: Icons.assignment_turned_in_rounded,
      actions: accountActions(context, ref),
      body: childAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (_, __) => EmptyState(
              icon: Icons.assignment_outlined,
              message: l.comingSoon,
            ),
        data: (child) {
          if (child == null) {
            return EmptyState(
              icon: Icons.family_restroom_rounded,
              message: l.noChildLinked,
            );
          }
          final tasksAsync = ref.watch(studentAssignmentsProvider(child.id));
          final sessions =
              ref.watch(studentSessionsProvider(child.id)).value ??
              const <Session>[];
          return tasksAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Center(child: Text(l.comingSoon)),
            data: (tasks) {
              if (tasks.isEmpty) {
                return EmptyState(
                  icon: Icons.assignment_outlined,
                  message: l.taskEmptyParent,
                );
              }
              return ConstrainedContent(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  itemCount: tasks.length,
                  separatorBuilder:
                      (_, __) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder:
                      (_, i) =>
                          _ParentTaskCard(task: tasks[i], sessions: sessions),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ParentTaskCard extends StatelessWidget {
  const _ParentTaskCard({required this.task, required this.sessions});

  final Assignment task;
  final List<Session> sessions;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final done = completedCountFor(task, sessions);
    final total = task.activities.length;
    final allDone = total > 0 && done == total;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.title.isEmpty ? l.taskUntitled : task.title,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                if (allDone)
                  Icon(
                    Icons.check_circle_rounded,
                    color: theme.colorScheme.primary,
                  ),
              ],
            ),
            if (task.note.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                task.note,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                for (final a in task.activities)
                  ActivityChip(
                    activity: a,
                    done: activityDoneFor(
                      assignment: task,
                      activity: a,
                      sessions: sessions,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l.taskDoneOf(done, total),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
