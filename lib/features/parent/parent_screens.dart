import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moodcraft/l10n/app_localizations.dart';

import '../../core/providers/repository_providers.dart';
import '../../core/widgets/calm_scaffold.dart';
import '../../core/widgets/constrained_content.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/sensory_settings_sheet.dart';
import '../journal/journal_section.dart';
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
        error:
            (_, __) =>
                EmptyState(icon: Icons.insights_rounded, message: l.comingSoon),
        data: (detail) {
          if (detail == null) {
            return EmptyState(
              icon: Icons.family_restroom_rounded,
              message: l.noChildLinked,
            );
          }
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
              showHomework: true,
            ),
          );
        },
      ),
    );
  }
}

/// FR12 — the parent's own Journal tab: their child's logged feelings, newest
/// first, with the parent's role-labelled comment on any entry (the same
/// shared journal view the teacher gets on their Journal tab).
class ParentJournalScreen extends ConsumerWidget {
  const ParentJournalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final childAsync = ref.watch(activeStudentProvider);

    return CalmScaffold(
      title: l.navJournal,
      icon: Icons.book_rounded,
      body: childAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (_, __) => EmptyState(
              icon: Icons.book_rounded,
              message: l.journalUnavailable,
            ),
        data: (child) {
          if (child == null) {
            return EmptyState(
              icon: Icons.family_restroom_rounded,
              message: l.noChildLinked,
            );
          }
          return ConstrainedContent(
            child: ListView(
              children: [JournalHistorySection(studentId: child.id)],
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
            body: EmptyState(
              icon: Icons.forum_outlined,
              message: l.msgNoLinkedTeacher,
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
