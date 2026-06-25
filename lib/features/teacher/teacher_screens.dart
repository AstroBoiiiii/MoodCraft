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
    title: AppLocalizations.of(context).navClassroom,
    icon: Icons.cast_for_education_rounded,
  );
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

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final classAsync = ref.watch(teacherClassProvider);
    final studentsAsync = ref.watch(classStudentsStreamProvider);

    return CalmScaffold(
      title: l.navStudents,
      icon: Icons.groups_rounded,
      body: ListView(
        children: [
          // ── Class code row ────────────────────────────────────────────────
          classAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (classroom) {
              if (classroom == null) return const SizedBox.shrink();
              return Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (classroom.name.isNotEmpty) ...[
                      Text(classroom.name, style: theme.textTheme.titleMedium),
                      const SizedBox(height: AppSpacing.xs),
                    ],
                    Row(
                      children: [
                        Icon(
                          Icons.tag_rounded,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          l.yourClassCode,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const Spacer(),
                        // Reveal / hide toggle
                        TextButton.icon(
                          onPressed:
                              () =>
                                  setState(() => _codeVisible = !_codeVisible),
                          icon: Icon(
                            _codeVisible
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            size: 16,
                          ),
                          label: Text(
                            _codeVisible ? l.hideCode : l.showCode,
                            style: theme.textTheme.labelSmall,
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_codeVisible) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Center(
                        child: SelectableText(
                          classroom.classCode,
                          style: theme.textTheme.displaySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            letterSpacing: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                    ],
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          // ── Students ──────────────────────────────────────────────────────
          Text(l.navStudents, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          studentsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
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
                        student.age > 0
                            ? '${l.ageYearsOld(student.age)} · ${l.levelStars(student.level, student.stars)}'
                            : l.levelStars(student.level, student.stars),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap:
                          () => context.push(
                            '/teacher/students/student/${student.id}',
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

class TeacherMessagesScreen extends ConsumerWidget {
  const TeacherMessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final conversationsAsync = ref.watch(teacherConversationsProvider);

    return CalmScaffold(
      title: l.navMessages,
      icon: Icons.message_rounded,
      body: conversationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text(l.comingSoon)),
        data: (conversations) {
          if (conversations.isEmpty) {
            return Center(
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
                    l.msgNoConversations,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            itemCount: conversations.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final conv = conversations[i];
              return _ConversationTile(
                conv: conv,
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
          );
        },
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.conv, required this.onTap});

  final ConversationSummary conv;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                Text(
                  conv.lastMessage.text,
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
  Widget build(BuildContext context) => PlaceholderScreen(
    title: AppLocalizations.of(context).navReports,
    icon: Icons.assessment_rounded,
  );
}
