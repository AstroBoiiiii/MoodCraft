import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moodcraft/l10n/app_localizations.dart';

import '../../app/theme/tokens.dart';
import '../../core/models/app_user.dart';
import '../../core/models/student.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/widgets/calm_scaffold.dart';
import '../../core/widgets/sensory_read_only_view.dart';
import '../../core/widgets/sensory_settings_sheet.dart';
import '../journal/journal_section.dart';
import '../schedule/schedule_section.dart';
import '../teacher/messaging_thread_screen.dart';

/// Parent monitoring — shows the linked child's profile and their teacher(s).
class ParentMonitoringScreen extends ConsumerWidget {
  const ParentMonitoringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final detailAsync = ref.watch(parentChildDetailProvider);

    return CalmScaffold(
      title: l.navProgress,
      icon: Icons.insights_rounded,
      actions: accountActions(context, ref),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text(l.comingSoon)),
        data: (detail) {
          if (detail == null) return Center(child: Text(l.noChildLinked));
          return _ChildProfileView(
            student: detail.student,
            teachers: detail.teachers,
          );
        },
      ),
    );
  }
}

class _ChildProfileView extends StatelessWidget {
  const _ChildProfileView({required this.student, required this.teachers});

  final Student student;
  final List<AppUser> teachers;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return ListView(
      children: [
        Center(
          child: CircleAvatar(
            radius: 40,
            child: Text(
              student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
              style: theme.textTheme.headlineSmall,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Center(child: Text(student.name, style: theme.textTheme.headlineSmall)),
        const SizedBox(height: AppSpacing.sm),
        if (student.age > 0)
          Center(
            child: Text(
              l.ageYearsOld(student.age),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        Center(
          child: Chip(
            avatar: const Icon(Icons.star_rounded, size: 18),
            label: Text(l.levelStars(student.level, student.stars)),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const Divider(),
        const SizedBox(height: AppSpacing.sm),
        Text(l.sensorySettings, style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        SensoryReadOnlyView(settings: student.sensorySettings),
        if (teachers.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          const Divider(),
          const SizedBox(height: AppSpacing.sm),
          Text(l.teacherLabel, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          for (final teacher in teachers) _ContactTile(user: teacher),
        ],
        const SizedBox(height: AppSpacing.lg),
        const Divider(),
        const SizedBox(height: AppSpacing.sm),
        StudentScheduleSection(studentId: student.id, canEdit: true),
        const SizedBox(height: AppSpacing.lg),
        const Divider(),
        const SizedBox(height: AppSpacing.sm),
        JournalHistorySection(studentId: student.id, canAnnotate: true),
      ],
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.name, style: theme.textTheme.titleSmall),
            if (user.username.isNotEmpty)
              Text('@${user.username}', style: theme.textTheme.bodySmall),
            if (user.phone.isNotEmpty)
              Text(user.phone, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class ParentMessagesScreen extends ConsumerWidget {
  const ParentMessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final convAsync = ref.watch(parentConversationProvider);

    return convAsync.when(
      loading:
          () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => Scaffold(body: Center(child: Text(l.comingSoon))),
      data: (conv) {
        if (conv == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l.navMessages)),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.forum_outlined,
                    size: 64,
                    color: theme.colorScheme.outlineVariant,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l.msgNoLinkedTeacher,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(conv.teacherName),
                Text(
                  l.msgAboutChild(
                    ref.watch(activeStudentProvider).value?.name ?? '',
                  ),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          body: MessagingThreadScreen(
            conversationId: conv.conversationId,
            toUid: conv.teacherUid,
            studentId: conv.studentId,
            displayTitle: conv.teacherName,
            showAppBar: false,
          ),
        );
      },
    );
  }
}
