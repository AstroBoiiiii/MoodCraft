import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moodcraft/l10n/app_localizations.dart';

import '../../app/theme/tokens.dart';
import '../../core/models/student.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/widgets/calm_scaffold.dart';
import '../../core/widgets/constrained_content.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/initial_avatar.dart';
import '../../core/widgets/placeholder_screen.dart';
import '../../core/widgets/section_card.dart';
import '../../core/widgets/sensory_settings_sheet.dart';
import '../../core/widgets/weekly_content_banner.dart';
import '../mix_match/mix_match_screen.dart';
import '../quiz/quiz_home_screen.dart';
import '../story/story_home_screen.dart';
import 'student_profile_detail_screen.dart';

/// Teacher dashboard — the landing screen for the web portal. Carries the
/// account actions (sensory settings + sign out).
class TeacherDashboardScreen extends ConsumerWidget {
  const TeacherDashboardScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return PlaceholderScreen(
      title: l.navDashboard,
      icon: Icons.dashboard_rounded,
      message: l.previewDashboard,
      actions: accountActions(context, ref),
    );
  }
}

/// The teacher's classroom-projection layer (**web only** — hidden from teacher
/// mobile, which is for managing students and messaging parents). Launches an
/// activity to play on the projected screen for the whole class. Mix-and-Match
/// (FR6) runs here in "classroom mode": every level is open and no per-child
/// session is recorded — it's a group demo, not one student's record. Story
/// (FR5) runs with every episode unlocked so the teacher can jump straight to
/// any episode on the big screen.
class TeacherProfilesScreen extends StatelessWidget {
  const TeacherProfilesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return CalmScaffold(
      title: l.navClassroom,
      icon: Icons.cast_for_education_rounded,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            children: [
              Text(l.previewClassroom, style: theme.textTheme.bodyLarge),
              const SizedBox(height: AppSpacing.lg),
              SectionCard(
                title: l.navMatch,
                icon: Icons.extension_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Text(
                        l.mixMatchClassroomHint,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const WeeklyContentBanner(),
                    MixMatchTypeGrid(
                      onPick:
                          (type) => context.push(
                            '/teacher/mixmatch/play',
                            extra: type,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SectionCard(
                title: l.navStories,
                icon: Icons.menu_book_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Text(
                        l.storyClassroomHint,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    StoryPicker(
                      onPick:
                          (storyId, level) => context.push(
                            '/teacher/story/play',
                            extra: (
                              studentId: null,
                              storyId: storyId,
                              level: level,
                            ),
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SectionCard(
                title: l.navQuiz,
                icon: Icons.emoji_objects_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Text(
                        l.quizClassroomHint,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    QuizDayPicker(
                      onPick:
                          (setIndex) => context.push(
                            '/teacher/quiz/play',
                            extra: setIndex,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TeacherClassroomScreen extends ConsumerStatefulWidget {
  const TeacherClassroomScreen({super.key});

  @override
  ConsumerState<TeacherClassroomScreen> createState() =>
      _TeacherClassroomScreenState();
}

class _TeacherClassroomScreenState
    extends ConsumerState<TeacherClassroomScreen> {
  bool _codeVisible = false;
  String? _selectedStudentId;

  /// Body width (not window width — the shell rail already eats ~80px at its
  /// own 720 breakpoint) at which the roster and the selected student's detail
  /// sit side by side instead of the roster pushing a full-screen detail.
  static const double _twoPaneBreakpoint = 840;
  static const double _rosterPaneWidth = 360;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final studentsAsync = ref.watch(classStudentsStreamProvider);

    return CalmScaffold(
      title: l.navStudents,
      icon: Icons.groups_rounded,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < _twoPaneBreakpoint) {
            return ConstrainedContent(
              child: _rosterList(
                onStudentTap:
                    (student) =>
                        context.push('/teacher/students/student/${student.id}'),
              ),
            );
          }

          // Wide (web/projector): master-detail. Selection is plain local
          // state; the pushed /teacher/students/student/:id route still serves
          // narrow windows and direct links unchanged. A stale selection (e.g.
          // a deleted student) simply resolves to null and shows the hint.
          final students = studentsAsync.value ?? const <Student>[];
          Student? selected;
          for (final student in students) {
            if (student.id == _selectedStudentId) selected = student;
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: _rosterPaneWidth,
                child: _rosterList(
                  onStudentTap:
                      (student) =>
                          setState(() => _selectedStudentId = student.id),
                  selectedId: _selectedStudentId,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              const VerticalDivider(width: 1),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child:
                    selected == null
                        ? EmptyState(
                          icon: Icons.groups_rounded,
                          message: l.selectStudentHint,
                        )
                        : _StudentDetailPane(
                          student: selected,
                          onDeleted:
                              () => setState(() => _selectedStudentId = null),
                        ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// The class-code card + student roster, shared by the narrow single-column
  /// layout and the wide master pane. [selectedId] highlights the student shown
  /// in the detail pane.
  Widget _rosterList({
    required void Function(Student student) onStudentTap,
    String? selectedId,
  }) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final classAsync = ref.watch(teacherClassProvider);
    final studentsAsync = ref.watch(classStudentsStreamProvider);

    return ListView(
      children: [
        // ── Class code ────────────────────────────────────────────────────
        classAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (classroom) {
            if (classroom == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: SectionCard(
                title: l.yourClassCode,
                icon: Icons.tag_rounded,
                trailing: TextButton.icon(
                  onPressed: () => setState(() => _codeVisible = !_codeVisible),
                  icon: Icon(
                    _codeVisible
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    size: 18,
                  ),
                  label: Text(_codeVisible ? l.hideCode : l.showCode),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (classroom.name.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Text(
                          classroom.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    Center(
                      child: SelectableText(
                        _codeVisible ? classroom.classCode : '••••••',
                        style: theme.textTheme.displaySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          letterSpacing: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        // ── Students ──────────────────────────────────────────────────────
        Text(l.navStudents, style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        studentsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => EmptyState(message: l.comingSoon, compact: true),
          data: (students) {
            if (students.isEmpty) {
              return EmptyState(
                icon: Icons.groups_rounded,
                message: l.noStudentsYet,
                compact: true,
              );
            }
            return Column(
              children: [
                for (final student in students)
                  Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: ListTile(
                      selected: student.id == selectedId,
                      leading: InitialAvatar(name: student.name),
                      title: Text(student.name),
                      subtitle: Text(
                        student.age > 0
                            ? '${l.ageYearsOld(student.age)} · ${l.levelStars(student.level, student.stars)}'
                            : l.levelStars(student.level, student.stars),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => onStudentTap(student),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// The right pane of the wide Students view: a small title row with the
/// delete menu over the shared tabbed detail. Deleting clears the selection
/// instead of popping (this pane lives inside the shell, not on a pushed
/// route).
class _StudentDetailPane extends StatelessWidget {
  const _StudentDetailPane({required this.student, required this.onDeleted});

  final Student student;
  final VoidCallback onDeleted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ConstrainedContent(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  student.name,
                  style: theme.textTheme.titleLarge,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              StudentDeleteMenu(student: student, onDeleted: onDeleted),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(child: StudentDetailPanel(studentId: student.id)),
        ],
      ),
    );
  }
}

class TeacherMessagesScreen extends ConsumerWidget {
  const TeacherMessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final conversationsAsync = ref.watch(teacherConversationsProvider);

    return CalmScaffold(
      title: l.navMessages,
      icon: Icons.message_rounded,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewMessageSheet(context, ref, l),
        icon: const Icon(Icons.edit_rounded),
        label: Text(l.msgNewMessage),
      ),
      body: conversationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text(l.comingSoon)),
        data: (conversations) {
          if (conversations.isEmpty) {
            return EmptyState(
              icon: Icons.forum_outlined,
              message: l.msgNoConversations,
            );
          }
          return ConstrainedContent(
            child: ListView.separated(
              itemCount: conversations.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final conv = conversations[i];
                return _ConversationTile(
                  conv: conv,
                  myUid: ref.watch(currentUserProvider)?.uid,
                  onTap:
                      () => context.push(
                        '/teacher/messages/thread',
                        extra: {
                          'conversationId': conv.conversationId,
                          'toUid': conv.parentUid,
                          'studentId': conv.studentId,
                          'title': l.msgConversationTitle(
                            conv.parentName,
                            conv.studentName,
                          ),
                        },
                      ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

/// Lets the teacher pick a parent and open a thread even before any message
/// exists — the conversation id is derived from the (student, teacher, parent)
/// trio, so the same thread the parent sees opens up (FR10).
void _showNewMessageSheet(
  BuildContext context,
  WidgetRef ref,
  AppLocalizations l,
) {
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder:
        (_) => Consumer(
          builder: (sheetCtx, sheetRef, __) {
            final targetsAsync = sheetRef.watch(teacherMessageTargetsProvider);
            return SafeArea(
              child: targetsAsync.when(
                loading:
                    () => const Padding(
                      padding: EdgeInsets.all(AppSpacing.xl),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                error:
                    (_, __) => Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Text(l.comingSoon),
                    ),
                data: (targets) {
                  if (targets.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Text(
                        l.msgNoParentsToMessage,
                        textAlign: TextAlign.center,
                        style: Theme.of(sheetCtx).textTheme.bodyLarge,
                      ),
                    );
                  }
                  return ListView(
                    shrinkWrap: true,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Text(
                          l.msgStartConversation,
                          style: Theme.of(sheetCtx).textTheme.titleMedium,
                        ),
                      ),
                      for (final t in targets)
                        ListTile(
                          leading: CircleAvatar(
                            child: Text(
                              t.parentName.isNotEmpty
                                  ? t.parentName[0].toUpperCase()
                                  : '?',
                            ),
                          ),
                          title: Text(t.parentName),
                          subtitle: Text(t.studentName),
                          onTap: () {
                            Navigator.pop(sheetCtx);
                            context.push(
                              '/teacher/messages/thread',
                              extra: {
                                'conversationId': t.conversationId,
                                'toUid': t.parentUid,
                                'studentId': t.studentId,
                                'title': l.msgConversationTitle(
                                  t.parentName,
                                  t.studentName,
                                ),
                              },
                            );
                          },
                        ),
                    ],
                  );
                },
              ),
            );
          },
        ),
  );
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conv,
    required this.onTap,
    this.myUid,
  });

  final ConversationSummary conv;
  final String? myUid;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final time = conv.lastMessage.timestamp;
    final now = DateTime.now();
    final timeStr =
        now.difference(time).inHours < 24
            ? '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
            : '${time.day}/${time.month}';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Text(
          conv.parentName.isNotEmpty ? conv.parentName[0].toUpperCase() : '?',
          style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              conv.parentName,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight:
                    conv.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            timeStr,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  conv.studentName,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text:
                            '${conv.lastMessage.fromUid == myUid ? l.msgYou : conv.parentName}: ',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(text: conv.lastMessage.text),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight:
                        conv.unreadCount > 0
                            ? FontWeight.w600
                            : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          if (conv.unreadCount > 0) ...[
            const SizedBox(width: AppSpacing.sm),
            CircleAvatar(
              radius: 10,
              backgroundColor: theme.colorScheme.primary,
              child: Text(
                conv.unreadCount > 9 ? '9+' : '${conv.unreadCount}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ],
      ),
      onTap: onTap,
    );
  }
}

class TeacherReportsScreen extends StatelessWidget {
  const TeacherReportsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PlaceholderScreen(
      title: l.navReports,
      icon: Icons.assessment_rounded,
      message: l.previewReports,
    );
  }
}
