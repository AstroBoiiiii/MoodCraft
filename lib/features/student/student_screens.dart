import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moodcraft/l10n/app_localizations.dart';

import '../../app/theme/tokens.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/widgets/big_button.dart';
import '../../core/widgets/calm_scaffold.dart';
import '../../core/widgets/placeholder_screen.dart';
import '../../core/widgets/sensory_settings_sheet.dart';
import '../journal/journal_section.dart';
import '../schedule/schedule_section.dart';

/// The student's home hub: a calm, icon-led menu of activities. One clear screen
/// with large tap targets (CLAUDE.md section 4.5). Activities open full-screen.
class StudentHomeScreen extends ConsumerWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final student = ref.watch(activeStudentProvider).value;

    final activities = <(String, String, IconData)>[
      ('/student/companion', l.navCompanion, Icons.chat_bubble_rounded),
      ('/student/ar', l.navAr, Icons.view_in_ar_rounded),
      ('/student/story', l.navStories, Icons.menu_book_rounded),
      ('/student/mixmatch', l.navMatch, Icons.extension_rounded),
      ('/student/quiz', l.navQuiz, Icons.emoji_objects_rounded),
      ('/student/schedule', l.navSchedule, Icons.view_agenda_rounded),
    ];

    return CalmScaffold(
      title: student == null ? l.navHome : l.greeting(student.name),
      icon: Icons.emoji_emotions_rounded,
      actions: accountActions(context, ref),
      body: ListView.separated(
        itemCount: activities.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, i) {
          final (route, label, icon) = activities[i];
          return BigButton(
            label: label,
            icon: icon,
            onPressed: () => context.push(route),
          );
        },
      ),
    );
  }
}

/// FR12 — the child's emotion journal: log a feeling with a picture (no reading
/// or writing) and see the history below. Teacher and parent view the same
/// entries from their child-detail screens.
class StudentJournalScreen extends ConsumerWidget {
  const StudentJournalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return CalmScaffold(
      title: l.navJournal,
      icon: Icons.book_rounded,
      actions: accountActions(context, ref),
      body: ref
          .watch(activeStudentProvider)
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Center(child: Text(l.comingSoon)),
            data:
                (student) =>
                    student == null
                        ? Center(child: Text(l.comingSoon))
                        : ListView(
                          children: [
                            JournalLogger(studentId: student.id),
                            const SizedBox(height: AppSpacing.lg),
                            const Divider(),
                            const SizedBox(height: AppSpacing.md),
                            JournalHistorySection(studentId: student.id),
                          ],
                        ),
          ),
    );
  }
}

class StudentRewardsScreen extends StatelessWidget {
  const StudentRewardsScreen({super.key});
  @override
  Widget build(BuildContext context) => PlaceholderScreen(
    title: AppLocalizations.of(context).navRewards,
    icon: Icons.star_rounded,
  );
}

class CompanionScreen extends StatelessWidget {
  const CompanionScreen({super.key});
  @override
  Widget build(BuildContext context) => PlaceholderScreen(
    title: AppLocalizations.of(context).navCompanion,
    icon: Icons.chat_bubble_rounded,
  );
}

class StoryScreen extends StatelessWidget {
  const StoryScreen({super.key});
  @override
  Widget build(BuildContext context) => PlaceholderScreen(
    title: AppLocalizations.of(context).navStories,
    icon: Icons.menu_book_rounded,
  );
}

class MixMatchScreen extends StatelessWidget {
  const MixMatchScreen({super.key});
  @override
  Widget build(BuildContext context) => PlaceholderScreen(
    title: AppLocalizations.of(context).navMatch,
    icon: Icons.extension_rounded,
  );
}

class QuizScreen extends StatelessWidget {
  const QuizScreen({super.key});
  @override
  Widget build(BuildContext context) => PlaceholderScreen(
    title: AppLocalizations.of(context).navQuiz,
    icon: Icons.emoji_objects_rounded,
  );
}

/// FR13 — the child's read-only "what's next" picture schedule. Set by the
/// teacher/parent; the student only views it.
class ScheduleScreen extends ConsumerWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final student = ref.watch(activeStudentProvider).value;

    return CalmScaffold(
      title: l.scheduleTitle,
      icon: Icons.view_agenda_rounded,
      body:
          student == null
              ? Center(
                child: Text(
                  l.scheduleEmpty,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
              : ListView(
                children: [
                  StudentScheduleSection(studentId: student.id, canEdit: false),
                ],
              ),
    );
  }
}
