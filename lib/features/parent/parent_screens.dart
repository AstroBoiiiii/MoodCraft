import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moodcraft/l10n/app_localizations.dart';

import '../../app/theme/tokens.dart';
import '../../core/models/app_user.dart';
import '../../core/models/student.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/widgets/calm_scaffold.dart';
import '../../core/widgets/contact_card.dart';
import '../../core/widgets/profile_header.dart';
import '../../core/widgets/section_card.dart';
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

    return ListView(
      children: [
        ProfileHeader(
          name: student.name,
          subtitle: student.age > 0 ? l.ageYearsOld(student.age) : null,
          chipLabel: l.levelStars(student.level, student.stars),
        ),
        const SizedBox(height: AppSpacing.lg),
        SectionCard(
          title: l.sensorySettings,
          icon: Icons.tune_rounded,
          child: SensoryReadOnlyView(settings: student.sensorySettings),
        ),
        if (teachers.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          SectionCard(
            title: l.teacherLabel,
            icon: Icons.person_rounded,
            child: Column(
              children: [
                for (final teacher in teachers) ContactCard(user: teacher),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        StudentScheduleSection(studentId: student.id, canEdit: true),
        const SizedBox(height: AppSpacing.lg),
        JournalHistorySection(studentId: student.id),
      ],
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
