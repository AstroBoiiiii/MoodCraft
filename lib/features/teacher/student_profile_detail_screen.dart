import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moodcraft/l10n/app_localizations.dart';

import '../../app/theme/tokens.dart';
import '../../core/models/app_user.dart';
import '../../core/models/message.dart';
import '../../core/models/student.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/widgets/calm_scaffold.dart';
import '../../core/widgets/constrained_content.dart';
import '../student_detail/student_detail_tabs.dart';

/// Full-screen student detail, pushed from the roster on phones and narrow
/// windows (`/teacher/students/student/:id`). The wide two-pane Students view
/// embeds [StudentDetailPanel] directly instead.
class StudentProfileDetailScreen extends ConsumerWidget {
  const StudentProfileDetailScreen({required this.studentId, super.key});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final detail = ref.watch(studentDetailProvider(studentId)).value;

    return CalmScaffold(
      title: l.studentProfile,
      icon: Icons.person_rounded,
      actions:
          detail == null
              ? null
              : [
                StudentDeleteMenu(
                  student: detail.student,
                  onDeleted: () {
                    final navigator = Navigator.of(context);
                    if (navigator.canPop()) navigator.pop();
                  },
                ),
              ],
      body: ConstrainedContent(child: StudentDetailPanel(studentId: studentId)),
    );
  }
}

/// The provider-watching tabbed detail body, shared by the pushed route screen
/// and the wide two-pane Students view. Teacher configuration: schedule
/// editable, parents removable.
class StudentDetailPanel extends ConsumerWidget {
  const StudentDetailPanel({required this.studentId, super.key});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final detailAsync = ref.watch(studentDetailProvider(studentId));
    return detailAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(child: Text(l.comingSoon)),
      data: (detail) {
        if (detail == null) return Center(child: Text(l.comingSoon));
        return StudentDetailTabs(
          key: ValueKey(detail.student.id),
          student: detail.student,
          teachers: detail.teachers,
          parents: detail.parents,
          canEditSchedule: true,
          onMessageParent:
              (parent) =>
                  openParentThread(context, ref, detail.student, parent),
          onRemoveParent:
              (parent) =>
                  confirmRemoveParent(context, ref, detail.student, parent),
        );
      },
    );
  }
}

/// The delete-student popup menu, shown in the route screen's app bar and in
/// the two-pane header. [onDeleted] runs after a confirmed delete so each host
/// can clean up its own navigation or selection state.
class StudentDeleteMenu extends ConsumerWidget {
  const StudentDeleteMenu({
    required this.student,
    required this.onDeleted,
    super.key,
  });

  final Student student;
  final VoidCallback onDeleted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded),
      onSelected: (value) {
        if (value == 'delete') {
          confirmDeleteStudent(context, ref, student, onDeleted: onDeleted);
        }
      },
      itemBuilder:
          (_) => [
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(
                    Icons.person_remove_rounded,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(l.studentDelete),
                ],
              ),
            ),
          ],
    );
  }
}

/// Deletes the student record and drops it from the teacher's own links, then
/// calls [onDeleted] (pop the route, or clear the two-pane selection). Guarded
/// by a confirm dialog (irreversible).
Future<void> confirmDeleteStudent(
  BuildContext context,
  WidgetRef ref,
  Student student, {
  VoidCallback? onDeleted,
}) async {
  final l = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final confirmed = await _confirm(
    context,
    title: l.studentDelete,
    message: l.studentDeleteConfirm(student.name),
    actionLabel: l.actionDelete,
  );
  if (!confirmed) return;

  await ref.read(studentRepositoryProvider).delete(student.id);
  // Keep the teacher's own linkedStudentIds tidy so the roster query and
  // rules stay consistent.
  final me = ref.read(currentUserProvider);
  if (me != null && me.linkedStudentIds.contains(student.id)) {
    await ref
        .read(userRepositoryProvider)
        .upsert(
          me.copyWith(
            linkedStudentIds:
                me.linkedStudentIds.where((id) => id != student.id).toList(),
          ),
        );
    ref.invalidate(userProfileProvider);
  }
  messenger.showSnackBar(SnackBar(content: Text(l.studentDeleted)));
  onDeleted?.call();
}

/// Opens (or starts) the teacher↔parent conversation about [student] from the
/// parent's contact card. The conversation id is the deterministic
/// (student, teacher, parent) trio, so it's the very same thread the parent
/// sees and the teacher inbox lists (FR10).
void openParentThread(
  BuildContext context,
  WidgetRef ref,
  Student student,
  AppUser parent,
) {
  final l = AppLocalizations.of(context);
  final myUid = ref.read(currentUserProvider)?.uid;
  if (myUid == null) return;
  context.push(
    '/teacher/messages/thread',
    extra: {
      'conversationId': Message.buildConversationId(
        student.id,
        myUid,
        parent.uid,
      ),
      'toUid': parent.uid,
      'studentId': student.id,
      'title': l.msgConversationTitle(parent.name, student.name),
    },
  );
}

/// Removes [parent] from this student's `parentIds` (the parent card and any
/// messaging target disappear). Guarded by a confirm dialog.
Future<void> confirmRemoveParent(
  BuildContext context,
  WidgetRef ref,
  Student student,
  AppUser parent,
) async {
  final l = AppLocalizations.of(context);
  final confirmed = await _confirm(
    context,
    title: l.parentRemove,
    message: l.parentRemoveConfirm(parent.name),
    actionLabel: l.actionRemove,
  );
  if (!confirmed) return;
  await ref
      .read(studentRepositoryProvider)
      .upsert(
        student.copyWith(
          parentIds: student.parentIds.where((id) => id != parent.uid).toList(),
        ),
      );
}

Future<bool> _confirm(
  BuildContext context, {
  required String title,
  required String message,
  required String actionLabel,
}) async {
  final l = AppLocalizations.of(context);
  final theme = Theme.of(context);
  final result = await showDialog<bool>(
    context: context,
    builder:
        (ctx) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.cancelEdit),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(actionLabel),
            ),
          ],
        ),
  );
  return result ?? false;
}
