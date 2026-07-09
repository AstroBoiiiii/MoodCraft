import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moodcraft/l10n/app_localizations.dart';

import '../../app/theme/tokens.dart';
import '../../core/models/assignment.dart';
import '../../core/models/session.dart';
import '../../core/widgets/section_card.dart';
import 'assignment_providers.dart';
import 'assignment_ui.dart';

/// A calm, read-only view of the homework a child has been handed: every task
/// the teacher handed out (announcement or personal) with a live tick per
/// activity showing what the child has already finished.
///
/// Tasks are never assigned to a parent — this only ever shows the **child's**
/// tasks, so a parent can see what's going on and whether it's done. Completion
/// tracks the child's own play, so there is nothing to mark here. Embedded in
/// the parent's monitoring (Progress) view.
class ChildHomeworkSection extends ConsumerWidget {
  const ChildHomeworkSection({required this.studentId, super.key});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final tasksAsync = ref.watch(studentAssignmentsProvider(studentId));
    final sessions =
        ref.watch(studentSessionsProvider(studentId)).value ??
        const <Session>[];

    return SectionCard(
      title: l.homeworkHeading,
      icon: Icons.assignment_turned_in_rounded,
      child: tasksAsync.when(
        loading:
            () => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Center(child: CircularProgressIndicator()),
            ),
        error:
            (_, __) => Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(l.comingSoon),
            ),
        data: (tasks) {
          if (tasks.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(
                l.taskEmptyParent,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }
          return Column(
            children: [
              for (var i = 0; i < tasks.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.sm),
                _HomeworkTaskCard(task: tasks[i], sessions: sessions),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// One task tile inside [ChildHomeworkSection]: the task name, an optional note,
/// a chip per activity (ticked when the child has finished it), and a calm
/// "X of Y done" line. An all-done task gets a soft tick by its name.
class _HomeworkTaskCard extends StatelessWidget {
  const _HomeworkTaskCard({required this.task, required this.sessions});

  final Assignment task;
  final List<Session> sessions;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final done = completedCountFor(task, sessions);
    final total = task.activities.length;
    final allDone = total > 0 && done == total;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
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
    );
  }
}
