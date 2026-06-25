import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moodcraft/l10n/app_localizations.dart';

import '../../app/theme/tokens.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/widgets/calm_scaffold.dart';
import '../../core/widgets/placeholder_screen.dart';
import '../../core/widgets/sensory_settings_sheet.dart';

/// Teacher dashboard — the landing screen for the web portal. Carries the
/// account actions (sensory settings + sign out).
class TeacherDashboardScreen extends ConsumerWidget {
  const TeacherDashboardScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => PlaceholderScreen(
    title: AppLocalizations.of(context).navDashboard,
    icon: Icons.dashboard_rounded,
    actions: accountActions(context, ref),
  );
}

class TeacherProfilesScreen extends StatelessWidget {
  const TeacherProfilesScreen({super.key});
  @override
  Widget build(BuildContext context) => PlaceholderScreen(
    title: AppLocalizations.of(context).navStudents,
    icon: Icons.groups_rounded,
  );
}

class TeacherClassroomScreen extends ConsumerWidget {
  const TeacherClassroomScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final classAsync = ref.watch(teacherClassProvider);
    final studentsAsync = ref.watch(classStudentsProvider);

    return CalmScaffold(
      title: l.navClassroom,
      icon: Icons.cast_for_education_rounded,
      body: ListView(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: classAsync.when(
                loading: () => const CircularProgressIndicator(),
                error: (_, __) => Text(l.comingSoon),
                data: (classroom) {
                  if (classroom == null) return Text(l.comingSoon);
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (classroom.name.isNotEmpty)
                        Text(
                          classroom.name,
                          style: theme.textTheme.titleLarge,
                        ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        l.yourClassCode,
                        style: theme.textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                          vertical: AppSpacing.lg,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(AppRadii.lg),
                        ),
                        child: SelectableText(
                          classroom.classCode,
                          style: theme.textTheme.displaySmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                            letterSpacing: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Divider(),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l.navStudents,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          studentsAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (_, __) => Text(l.comingSoon),
            data: (students) {
              if (students.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Text(l.noStudentsYet),
                  ),
                );
              }
              return Column(
                children: [
                  for (final student in students)
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xs,
                      ),
                      leading: CircleAvatar(
                        child: Text(
                          student.name.isNotEmpty
                              ? student.name[0].toUpperCase()
                              : '?',
                        ),
                      ),
                      title: Text(student.name),
                      subtitle: Text(
                        l.levelStars(student.level, student.stars),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push(
                        '/teacher/classroom/student/${student.id}',
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class TeacherMessagesScreen extends StatelessWidget {
  const TeacherMessagesScreen({super.key});
  @override
  Widget build(BuildContext context) => PlaceholderScreen(
    title: AppLocalizations.of(context).navMessages,
    icon: Icons.message_rounded,
  );
}

class TeacherReportsScreen extends StatelessWidget {
  const TeacherReportsScreen({super.key});
  @override
  Widget build(BuildContext context) => PlaceholderScreen(
    title: AppLocalizations.of(context).navReports,
    icon: Icons.assessment_rounded,
  );
}
