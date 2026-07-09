import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moodcraft/l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';

import '../../app/theme/tokens.dart';
import '../../core/models/assignment.dart';
import '../../core/models/enums.dart';
import '../../core/models/session.dart';
import '../../core/models/student.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/widgets/calm_scaffold.dart';
import '../../core/widgets/constrained_content.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/initial_avatar.dart';
import '../../core/widgets/section_card.dart';
import 'assignment_providers.dart';
import 'assignment_ui.dart';

/// FR8/FR10 — the teacher's homework hub. Lists every task they've handed out
/// (announcement to the whole class, or personal to chosen students) with a live
/// "who's done it" summary, and a button to hand out a new one. Tapping a task
/// opens the per-student completion detail.
class TeacherTasksScreen extends ConsumerWidget {
  const TeacherTasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final tasksAsync = ref.watch(teacherAssignmentsProvider);

    return CalmScaffold(
      title: l.navTasks,
      icon: Icons.assignment_turned_in_rounded,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/teacher/tasks/new'),
        icon: const Icon(Icons.add_rounded),
        label: Text(l.taskNewTitle),
      ),
      body: tasksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text(l.comingSoon)),
        data: (tasks) {
          if (tasks.isEmpty) {
            return EmptyState(
              icon: Icons.assignment_outlined,
              message: l.taskEmptyTeacher,
            );
          }
          return ConstrainedContent(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              itemCount: tasks.length,
              separatorBuilder:
                  (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (_, i) => _TaskCard(task: tasks[i]),
            ),
          );
        },
      ),
    );
  }
}

/// One task in the teacher's list: name, audience chip, activity chips, and a
/// live "X/Y finished it" line drawn from the target students' sessions.
class _TaskCard extends ConsumerWidget {
  const _TaskCard({required this.task});

  final Assignment task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);

    var finished = 0;
    var counted = 0;
    for (final id in task.studentIds) {
      final async = ref.watch(studentSessionsProvider(id));
      final sessions = async.value;
      if (sessions == null) continue;
      counted++;
      if (isAssignmentComplete(task, sessions)) finished++;
    }

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.md),
        onTap: () => context.push('/teacher/tasks/detail', extra: task),
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
                  _AudienceChip(audience: task.audience),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final a in task.activities) ActivityChip(activity: a),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Icon(
                    Icons.groups_rounded,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    // Only shows the count once at least one student's sessions
                    // have loaded, so it never flashes a misleading 0.
                    counted == 0
                        ? l.taskForStudents(task.studentIds.length)
                        : l.taskStudentsFinished(
                          finished,
                          task.studentIds.length,
                        ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AudienceChip extends StatelessWidget {
  const _AudienceChip({required this.audience});

  final AssignmentAudience audience;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isAnnouncement = audience == AssignmentAudience.announcement;
    final color =
        isAnnouncement ? theme.colorScheme.primary : theme.colorScheme.tertiary;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAnnouncement ? Icons.campaign_rounded : Icons.person_pin_rounded,
            size: 14,
            color: color,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            isAnnouncement ? l.taskAnnouncement : l.taskPersonal,
            style: theme.textTheme.labelSmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

/// The create-a-task form: audience (whole class or chosen students) and the
/// activities to do, no name or note needed. Announcements snapshot the
/// current class roster so the target never shifts after it's handed out.
class TeacherCreateTaskScreen extends ConsumerStatefulWidget {
  const TeacherCreateTaskScreen({super.key});

  @override
  ConsumerState<TeacherCreateTaskScreen> createState() =>
      _TeacherCreateTaskScreenState();
}

class _TeacherCreateTaskScreenState
    extends ConsumerState<TeacherCreateTaskScreen> {
  AssignmentAudience _audience = AssignmentAudience.announcement;
  final Set<ActivityType> _activities = {};
  final Set<String> _studentIds = {};
  bool _saving = false;

  Future<void> _save(List<Student> roster) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final me = ref.read(currentUserProvider);
    if (me == null || _saving) return;

    if (_activities.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(l.taskNeedActivity)));
      return;
    }
    final targetIds =
        _audience == AssignmentAudience.announcement
            ? roster.map((s) => s.id).toList()
            : _studentIds.toList();
    if (targetIds.isEmpty) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _audience == AssignmentAudience.announcement
                ? l.taskNoStudentsInClass
                : l.taskNeedStudent,
          ),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    final classId = ref.read(teacherClassProvider).value?.id;
    final assignment = Assignment(
      id: const Uuid().v4(),
      teacherId: me.uid,
      classId: _audience == AssignmentAudience.announcement ? classId : null,
      audience: _audience,
      title: '',
      note: '',
      studentIds: targetIds,
      activities: kAssignableActivities.where(_activities.contains).toList(),
      createdAt: DateTime.now(),
    );
    try {
      await ref.read(assignmentRepositoryProvider).upsert(assignment);
    } catch (_) {
      // Offline/transient — Firestore cache will sync later (FR14).
    }
    if (!mounted) return;
    messenger.showSnackBar(SnackBar(content: Text(l.taskCreated)));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final roster = ref.watch(classStudentsStreamProvider).value ?? const [];

    return CalmScaffold(
      title: l.taskNewTitle,
      icon: Icons.assignment_rounded,
      body: ConstrainedContent(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          children: [
            Text(l.taskAudienceQuestion, style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            SegmentedButton<AssignmentAudience>(
              segments: [
                ButtonSegment(
                  value: AssignmentAudience.announcement,
                  label: Text(l.taskAudienceClass),
                  icon: const Icon(Icons.campaign_rounded),
                ),
                ButtonSegment(
                  value: AssignmentAudience.personalized,
                  label: Text(l.taskAudienceStudents),
                  icon: const Icon(Icons.person_pin_rounded),
                ),
              ],
              selected: {_audience},
              onSelectionChanged: (s) => setState(() => _audience = s.first),
            ),
            if (_audience == AssignmentAudience.personalized) ...[
              const SizedBox(height: AppSpacing.md),
              SectionCard(
                title: l.taskStudentsHeading,
                icon: Icons.groups_rounded,
                child:
                    roster.isEmpty
                        ? Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.sm,
                          ),
                          child: Text(
                            l.taskNoStudentsInClass,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                        : Column(
                          children: [
                            for (final s in roster)
                              CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                value: _studentIds.contains(s.id),
                                title: Text(s.name),
                                secondary: InitialAvatar(name: s.name),
                                onChanged:
                                    (v) => setState(() {
                                      if (v == true) {
                                        _studentIds.add(s.id);
                                      } else {
                                        _studentIds.remove(s.id);
                                      }
                                    }),
                              ),
                          ],
                        ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            Text(l.taskActivitiesHeading, style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final a in kAssignableActivities)
                  FilterChip(
                    avatar: Icon(activityIcon(a), size: 18),
                    label: Text(activityLabel(a, l)),
                    selected: _activities.contains(a),
                    onSelected:
                        (v) => setState(() {
                          if (v) {
                            _activities.add(a);
                          } else {
                            _activities.remove(a);
                          }
                        }),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: _saving ? null : () => _save(roster),
              icon: const Icon(Icons.send_rounded),
              label: Text(l.taskHandOut),
            ),
          ],
        ),
      ),
    );
  }
}

/// Per-student completion for one task: every target student with a tick per
/// activity they've finished (drawn live from their sessions). Delete lives in
/// the app bar.
class TeacherTaskDetailScreen extends ConsumerWidget {
  const TeacherTaskDetailScreen({required this.assignment, super.key});

  final Assignment assignment;

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(l.taskDelete),
            content: Text(l.taskDeleteConfirm),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l.cancelEdit),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l.actionDelete),
              ),
            ],
          ),
    );
    if (confirmed != true) return;
    await ref.read(assignmentRepositoryProvider).delete(assignment.id);
    messenger.showSnackBar(SnackBar(content: Text(l.taskDeleted)));
    if (navigator.canPop()) navigator.pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final roster = ref.watch(classStudentsStreamProvider).value ?? const [];
    final nameById = {for (final s in roster) s.id: s.name};

    // Watch each target student's sessions once; reuse for the header count and
    // the rows so nothing is watched twice.
    final sessionsById = <String, List<Session>?>{
      for (final id in assignment.studentIds)
        id: ref.watch(studentSessionsProvider(id)).value,
    };
    final loaded = sessionsById.values.where((v) => v != null).length;
    final finished =
        sessionsById.entries
            .where(
              (e) =>
                  e.value != null && isAssignmentComplete(assignment, e.value!),
            )
            .length;

    return CalmScaffold(
      title: assignment.title.isEmpty ? l.taskUntitled : assignment.title,
      icon: Icons.assignment_turned_in_rounded,
      actions: [
        IconButton(
          tooltip: l.taskDelete,
          icon: Icon(
            Icons.delete_outline_rounded,
            color: theme.colorScheme.error,
          ),
          onPressed: () => _confirmDelete(context, ref),
        ),
      ],
      body: ConstrainedContent(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          children: [
            Row(
              children: [
                _AudienceChip(audience: assignment.audience),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  loaded == 0
                      ? l.taskForStudents(assignment.studentIds.length)
                      : l.taskStudentsFinished(
                        finished,
                        assignment.studentIds.length,
                      ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            if (assignment.note.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Text(assignment.note, style: theme.textTheme.bodyMedium),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                for (final a in assignment.activities)
                  ActivityChip(activity: a),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(l.taskProgressHeading, style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            for (final id in assignment.studentIds)
              _StudentProgressRow(
                assignment: assignment,
                name: nameById[id] ?? id,
                sessions: sessionsById[id],
              ),
          ],
        ),
      ),
    );
  }
}

/// One student's row in the task detail: their name and a chip per activity
/// showing done/not done, plus a soft "all done" tick when every activity is
/// finished.
class _StudentProgressRow extends StatelessWidget {
  const _StudentProgressRow({
    required this.assignment,
    required this.name,
    required this.sessions,
  });

  final Assignment assignment;
  final String name;
  final List<Session>? sessions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = sessions;
    final allDone = data != null && isAssignmentComplete(assignment, data);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
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
                InitialAvatar(name: name),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(name, style: theme.textTheme.titleSmall)),
                if (allDone)
                  Icon(
                    Icons.check_circle_rounded,
                    color: theme.colorScheme.primary,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                for (final a in assignment.activities)
                  ActivityChip(
                    activity: a,
                    done:
                        data == null
                            ? null
                            : activityDoneFor(
                              assignment: assignment,
                              activity: a,
                              sessions: data,
                            ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
