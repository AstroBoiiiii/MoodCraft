import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moodcraft/l10n/app_localizations.dart';

import '../../app/theme/tokens.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/widgets/calm_scaffold.dart';
import '../../core/widgets/constrained_content.dart';
import '../../core/widgets/sensory_settings_sheet.dart';
import '../student_detail/student_detail_tabs.dart';
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
          // Same tabbed child view the teacher gets, minus teacher-only
          // actions: no parent removal and no delete menu. The schedule stays
          // editable (FR13 — set by teacher or parent).
          return ConstrainedContent(
            child: StudentDetailTabs(
              key: ValueKey(detail.student.id),
              student: detail.student,
              teachers: detail.teachers,
              parents: const [],
              canEditSchedule: true,
            ),
          );
        },
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
