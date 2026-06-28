import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moodcraft/l10n/app_localizations.dart';

import '../../app/theme/tokens.dart';
import '../../core/models/app_user.dart';
import '../../core/models/student.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/widgets/calm_scaffold.dart';
import '../../core/widgets/contact_card.dart';
import '../../core/widgets/profile_header.dart';
import '../../core/widgets/section_card.dart';
import '../../core/widgets/sensory_read_only_view.dart';
import '../journal/journal_section.dart';
import '../schedule/schedule_section.dart';

class _StudentDetail {
  const _StudentDetail({
    required this.student,
    required this.teachers,
    required this.parents,
  });
  final Student student;
  final List<AppUser> teachers;
  final List<AppUser> parents;
}

final _studentDetailProvider = StreamProvider.family<_StudentDetail?, String>((
  ref,
  id,
) async* {
  final repo = ref.watch(studentRepositoryProvider);
  final userRepo = ref.watch(userRepositoryProvider);
  await for (final student in repo.watchStudent(id)) {
    if (student == null) {
      yield null;
      continue;
    }
    final teachers = await userRepo.getUsersFor(student.teacherIds);
    final parents = await userRepo.getUsersFor(student.parentIds);
    yield _StudentDetail(
      student: student,
      teachers: teachers,
      parents: parents,
    );
  }
});

class StudentProfileDetailScreen extends ConsumerWidget {
  const StudentProfileDetailScreen({required this.studentId, super.key});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final detailAsync = ref.watch(_studentDetailProvider(studentId));
    final detail = detailAsync.value;

    return CalmScaffold(
      title: l.studentProfile,
      icon: Icons.person_rounded,
      actions:
          detail == null
              ? null
              : [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded),
                  onSelected: (value) {
                    if (value == 'delete') {
                      _confirmDeleteStudent(context, ref, detail.student);
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
                ),
              ],
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text(l.comingSoon)),
        data: (detail) {
          if (detail == null) return Center(child: Text(l.comingSoon));
          return _DetailBody(
            detail: detail,
            l: l,
            onRemoveParent:
                (parent) =>
                    _confirmRemoveParent(context, ref, detail.student, parent),
          );
        },
      ),
    );
  }

  /// Deletes the student record and drops it from the teacher's own links, then
  /// returns to the roster. Guarded by a confirm dialog (irreversible).
  Future<void> _confirmDeleteStudent(
    BuildContext context,
    WidgetRef ref,
    Student student,
  ) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
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
    if (navigator.canPop()) navigator.pop();
  }

  /// Removes [parent] from this student's `parentIds` (the parent card and any
  /// messaging target disappear). Guarded by a confirm dialog.
  Future<void> _confirmRemoveParent(
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
            parentIds:
                student.parentIds.where((id) => id != parent.uid).toList(),
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
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.detail,
    required this.l,
    required this.onRemoveParent,
  });

  final _StudentDetail detail;
  final AppLocalizations l;
  final void Function(AppUser parent) onRemoveParent;

  @override
  Widget build(BuildContext context) {
    final student = detail.student;
    return ListView(
      children: [
        ProfileHeader(
          name: student.name,
          subtitle: student.age > 0 ? l.ageYearsOld(student.age) : null,
          chipLabel: l.levelStars(student.level, student.stars),
          avatarRadius: 48,
        ),
        const SizedBox(height: AppSpacing.lg),
        SectionCard(
          title: l.sensorySettings,
          icon: Icons.tune_rounded,
          child: SensoryReadOnlyView(settings: student.sensorySettings),
        ),
        if (detail.teachers.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          SectionCard(
            title: l.teacherLabel,
            icon: Icons.person_rounded,
            child: Column(
              children: [for (final u in detail.teachers) ContactCard(user: u)],
            ),
          ),
        ],
        if (detail.parents.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          SectionCard(
            title: l.parentLabel,
            icon: Icons.people_rounded,
            child: Column(
              children: [
                for (final u in detail.parents)
                  ContactCard(
                    user: u,
                    onRemove: () => onRemoveParent(u),
                    removeTooltip: l.parentRemove,
                  ),
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
