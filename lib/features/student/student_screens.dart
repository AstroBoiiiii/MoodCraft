import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moodcraft/l10n/app_localizations.dart';

import '../../app/theme/tokens.dart';
import '../../core/constants/app_constants.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/widgets/activity_card.dart';
import '../../core/widgets/calm_scaffold.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/sensory_settings_sheet.dart';
import '../assignments/student_todo_card.dart';
import '../journal/journal_section.dart';
import '../quiz/quiz_home_screen.dart';
import '../schedule/schedule_section.dart';

/// The student's home hub: a calm, icon-led menu of activities. One clear screen
/// with large tap targets (CLAUDE.md section 4.5). Activities open full-screen.
class StudentHomeScreen extends ConsumerWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final student = ref.watch(activeStudentProvider).value;
    // The Now/Next card renders nothing without a routine, so only show its
    // "Today" heading when there is something for it to head.
    final hasSchedule =
        student != null &&
        (ref
                .watch(studentScheduleProvider(student.id))
                .value
                ?.sortedItems
                .isNotEmpty ??
            false);

    // (route, accent key, label, icon). Schedule is no longer a tile here — the
    // "what's next" routine lives in the Now/Next card at the top. The companion
    // (FR3) and AR (FR4) are mobile-only, so their tiles are hidden on the web
    // build (both screens also fall back to a calm "on mobile" placeholder if
    // reached directly).
    final activities = <(String, String, String, IconData)>[
      ('/student/story', 'story', l.navStories, Icons.menu_book_rounded),
      ('/student/mixmatch', 'mixmatch', l.navMatch, Icons.extension_rounded),
      ('/student/quiz', 'quiz', l.navQuiz, Icons.emoji_objects_rounded),
      if (!kIsWeb)
        (
          '/student/companion',
          'companion',
          l.navCompanion,
          Icons.chat_bubble_rounded,
        ),
      if (!kIsWeb) ('/student/ar', 'ar', l.navAr, Icons.view_in_ar_rounded),
    ];

    return CalmScaffold(
      title: student == null ? l.navHome : l.greeting(student.name),
      icon: Icons.emoji_emotions_rounded,
      actions: accountActions(context, ref),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            children: [
              if (student != null) ...[
                if (hasSchedule) ...[
                  Text(l.homeTodayHeading, style: theme.textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.sm),
                ],
                // Carries its own bottom spacing and hides without a routine.
                ScheduleNowNextCard(
                  studentId: student.id,
                  onTap: () => context.push('/student/schedule'),
                ),
                // Homework handed out by the teacher. Carries its own bottom
                // spacing and hides itself when there's nothing left to do.
                StudentTodoCard(studentId: student.id),
              ],
              Text(l.homeActivities, style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                childAspectRatio: 0.95,
                children: [
                  for (final (route, key, label, icon) in activities)
                    ActivityCard(
                      label: label,
                      icon: icon,
                      accent: activityAccent(key),
                      onTap: () => context.push(route),
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
            error:
                (_, __) =>
                    EmptyState(icon: Icons.book_rounded, message: l.comingSoon),
            data:
                (student) =>
                    student == null
                        ? EmptyState(
                          icon: Icons.book_rounded,
                          message: l.comingSoon,
                        )
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

/// FR7 — the stress-free feelings quiz entry. Pick a day (Today / Yesterday /
/// Day before) to play that day's set; the real date decides which set each day
/// shows. Each day's round is one calm mix of look / listen / story, no score,
/// no timer, and resumes where the child left off.
class QuizScreen extends ConsumerWidget {
  const QuizScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final student = ref.watch(activeStudentProvider).value;
    return CalmScaffold(
      title: l.navQuiz,
      icon: Icons.emoji_objects_rounded,
      actions: accountActions(context, ref),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            children: [
              Text(l.quizPickDay, style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.md),
              QuizDayPicker(
                progressFor:
                    (setIndex) =>
                        (student?.quizRounds[setIndex.toString()]?.answered ??
                                0)
                            .clamp(0, kQuizRoundSize),
                onPick:
                    (setIndex) => context.push(
                      '/student/quiz/play',
                      extra: (studentId: student?.id, setIndex: setIndex),
                    ),
              ),
              // Dev-only: clear all quiz progress back to 0/5. Compiled out of
              // release/demo builds (kDebugMode), so it disappears when done.
              if (kDebugMode && student != null) ...[
                const SizedBox(height: AppSpacing.lg),
                Center(
                  child: TextButton.icon(
                    onPressed:
                        () => ref
                            .read(studentRepositoryProvider)
                            .upsert(student.copyWith(quizRounds: {})),
                    icon: const Icon(Icons.restart_alt_rounded),
                    label: const Text('Reset progress (dev)'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
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
