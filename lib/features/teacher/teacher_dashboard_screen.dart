import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moodcraft/l10n/app_localizations.dart';

import '../../app/theme/tokens.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/assignment.dart';
import '../../core/models/student.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/widgets/calm_scaffold.dart';
import '../../core/widgets/constrained_content.dart';
import '../../core/widgets/initial_avatar.dart';
import '../../core/widgets/reward_celebration.dart';
import '../../core/widgets/section_card.dart';
import '../../core/widgets/sensory_settings_sheet.dart';
import '../assignments/assignment_providers.dart';
import '../journal/journal_section.dart';
import 'teacher_journal_screen.dart';

/// FR8 — the teacher dashboard, the landing screen of the portal. One calm
/// column of live class summaries, each linking through to its full page:
/// the star leader (→ Students), the badge wall with per-badge earner counts
/// (tap a badge for who earned it), the latest journal entries (→ Journal),
/// and the newest homework tasks with live completion (tap one for who has
/// finished it, → Tasks).
class TeacherDashboardScreen extends ConsumerWidget {
  const TeacherDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return CalmScaffold(
      title: l.navDashboard,
      icon: Icons.dashboard_rounded,
      actions: accountActions(context, ref),
      body: ConstrainedContent(
        maxWidth: 720,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          children: const [
            _StarLeaderCard(),
            SizedBox(height: AppSpacing.lg),
            _BadgesCard(),
            SizedBox(height: AppSpacing.lg),
            _JournalCard(),
            SizedBox(height: AppSpacing.lg),
            _TasksCard(),
          ],
        ),
      ),
    );
  }
}

/// Muted single-line placeholder used by every card for its empty state.
class _MutedLine extends StatelessWidget {
  const _MutedLine(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// A small header-row action that opens the section's full page.
class _ViewAllButton extends StatelessWidget {
  const _ViewAllButton({required this.location});
  final String location;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return TextButton.icon(
      onPressed: () => context.go(location),
      icon: const Icon(Icons.chevron_right_rounded, size: 20),
      iconAlignment: IconAlignment.end,
      label: Text(l.dashViewAll),
    );
  }
}

/// The student(s) with the most stars in the class. Ties all share the spot.
/// Tapping a name opens that student's detail page.
class _StarLeaderCard extends ConsumerWidget {
  const _StarLeaderCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final studentsAsync = ref.watch(classStudentsStreamProvider);

    return SectionCard(
      title: l.dashStarLeader,
      icon: Icons.star_rounded,
      trailing: const _ViewAllButton(location: '/teacher/students'),
      child: studentsAsync.when(
        loading: () => const _CardSpinner(),
        error: (_, __) => _MutedLine(l.comingSoon),
        data: (students) {
          if (students.isEmpty) return _MutedLine(l.noStudentsYet);
          var max = 0;
          for (final s in students) {
            if (s.stars > max) max = s.stars;
          }
          if (max == 0) return _MutedLine(l.dashStarLeaderEmpty);
          final leaders = students.where((s) => s.stars == max).toList();
          return Column(
            children: [
              for (final s in leaders)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: InitialAvatar(name: s.name),
                  title: Text(s.name),
                  subtitle: Text(l.levelStars(s.level, s.stars)),
                  trailing: const Icon(Icons.star_rounded, color: Colors.amber),
                  onTap:
                      () => context.push('/teacher/students/student/${s.id}'),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// The four completion badges with a live "X of Y" earner count each. Tapping
/// a badge pops up the names of the students who have earned it.
class _BadgesCard extends ConsumerWidget {
  const _BadgesCard();

  void _showEarners(
    BuildContext context,
    RewardBadge badge,
    List<Student> earners,
  ) {
    final l = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            icon: Icon(badge.icon, color: badge.color),
            title: Text(rewardBadgeLabel(badge, l)),
            content:
                earners.isEmpty
                    ? Text(l.dashBadgeNoOneYet)
                    : SizedBox(
                      width: double.maxFinite,
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          for (final s in earners)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: InitialAvatar(name: s.name),
                              title: Text(s.name),
                            ),
                        ],
                      ),
                    ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l.actionClose),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final studentsAsync = ref.watch(classStudentsStreamProvider);

    return SectionCard(
      title: l.progressBadgesCaption,
      icon: Icons.emoji_events_rounded,
      child: studentsAsync.when(
        loading: () => const _CardSpinner(),
        error: (_, __) => _MutedLine(l.comingSoon),
        data: (students) {
          if (students.isEmpty) return _MutedLine(l.noStudentsYet);
          return Column(
            children: [
              for (final badge in kRewardBadges)
                Builder(
                  builder: (context) {
                    final earners =
                        students
                            .where((s) => s.badges.contains(badge.id))
                            .toList();
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: badge.color.withValues(alpha: 0.15),
                        child: Icon(badge.icon, color: badge.color),
                      ),
                      title: Text(rewardBadgeLabel(badge, l)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l.dashStudentsEarned(
                              earners.length,
                              students.length,
                            ),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded),
                        ],
                      ),
                      onTap: () => _showEarners(context, badge, earners),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}

/// The latest feelings logged across the roster, in short form (three entries).
/// The header button and each card open the full Journal tab.
class _JournalCard extends ConsumerWidget {
  const _JournalCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final user = ref.watch(currentUserProvider);
    final feedAsync = ref.watch(classJournalFeedProvider);

    return SectionCard(
      title: l.navJournal,
      icon: Icons.book_rounded,
      trailing: const _ViewAllButton(location: '/teacher/journal'),
      child: feedAsync.when(
        loading: () => const _CardSpinner(),
        error: (_, __) => _MutedLine(l.journalUnavailable),
        data: (items) {
          if (items.isEmpty) return _MutedLine(l.journalEmpty);
          return Column(
            children: [
              for (final item in items.take(3))
                JournalEntryCard(
                  entry: item.entry,
                  currentRole: user?.role,
                  studentName: item.student.name,
                  onTap: () => context.go('/teacher/journal'),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// The newest homework tasks with a live "X/Y finished it" line each. Tapping
/// a task pops up who has finished; the header button opens the Tasks tab.
class _TasksCard extends ConsumerWidget {
  const _TasksCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final tasksAsync = ref.watch(teacherAssignmentsProvider);

    return SectionCard(
      title: l.navTasks,
      icon: Icons.assignment_turned_in_rounded,
      trailing: const _ViewAllButton(location: '/teacher/tasks'),
      child: tasksAsync.when(
        loading: () => const _CardSpinner(),
        error: (_, __) => _MutedLine(l.comingSoon),
        data: (tasks) {
          if (tasks.isEmpty) return _MutedLine(l.dashNoTasks);
          return Column(
            children: [for (final task in tasks.take(3)) _TaskRow(task: task)],
          );
        },
      ),
    );
  }
}

/// One task line: name plus how many of its students have finished it, drawn
/// live from their sessions (the same participation-based check the Tasks tab
/// uses). Tap opens the who-finished popup.
class _TaskRow extends ConsumerWidget {
  const _TaskRow({required this.task});
  final Assignment task;

  void _showWhoFinished(BuildContext context) {
    final l = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder:
          (ctx) => Consumer(
            builder: (ctx, ref, _) {
              final theme = Theme.of(ctx);
              final roster =
                  ref.watch(classStudentsStreamProvider).value ??
                  const <Student>[];
              final nameById = {for (final s in roster) s.id: s.name};
              return AlertDialog(
                title: Text(task.title.isEmpty ? l.taskUntitled : task.title),
                content: SizedBox(
                  width: double.maxFinite,
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final id in task.studentIds)
                        Builder(
                          builder: (context) {
                            final sessions =
                                ref.watch(studentSessionsProvider(id)).value;
                            final done =
                                sessions != null &&
                                isAssignmentComplete(task, sessions);
                            final name = nameById[id] ?? id;
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: InitialAvatar(name: name),
                              title: Text(name),
                              trailing:
                                  done
                                      ? Icon(
                                        Icons.check_circle_rounded,
                                        color: theme.colorScheme.primary,
                                      )
                                      : Icon(
                                        Icons.radio_button_unchecked_rounded,
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(l.actionClose),
                  ),
                ],
              );
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);

    var finished = 0;
    var counted = 0;
    for (final id in task.studentIds) {
      final sessions = ref.watch(studentSessionsProvider(id)).value;
      if (sessions == null) continue;
      counted++;
      if (isAssignmentComplete(task, sessions)) finished++;
    }

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.assignment_rounded),
      title: Text(task.title.isEmpty ? l.taskUntitled : task.title),
      subtitle: Text(
        counted == 0
            ? l.taskForStudents(task.studentIds.length)
            : l.taskStudentsFinished(finished, task.studentIds.length),
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => _showWhoFinished(context),
    );
  }
}

/// A small centered spinner that keeps a loading card at a calm height.
class _CardSpinner extends StatelessWidget {
  const _CardSpinner();
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.md),
      child: Center(
        child: SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}
