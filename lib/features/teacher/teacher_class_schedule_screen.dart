import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moodcraft/l10n/app_localizations.dart';

import '../../app/theme/tokens.dart';
import '../../core/models/student.dart';
import '../../core/models/visual_schedule.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/widgets/calm_scaffold.dart';
import '../../core/widgets/constrained_content.dart';
import '../../core/widgets/empty_state.dart';
import '../schedule/schedule_section.dart';

/// FR13 — lets the teacher build one daily routine and apply it to every
/// student in the class at once, **replacing** each student's current
/// schedule (not merging like the per-child editor). Meant for a class that
/// shares one routine (e.g. a fixed school timetable); a student can still be
/// edited individually afterward from their own detail page.
class TeacherClassScheduleScreen extends ConsumerStatefulWidget {
  const TeacherClassScheduleScreen({super.key});

  @override
  ConsumerState<TeacherClassScheduleScreen> createState() =>
      _TeacherClassScheduleScreenState();
}

class _TeacherClassScheduleScreenState
    extends ConsumerState<TeacherClassScheduleScreen> {
  bool _saving = false;

  Future<void> _confirm(List<ScheduleItem> draft, List<Student> roster) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final uid = ref.read(currentUserProvider)?.uid ?? '';
    setState(() => _saving = true);
    try {
      await ref
          .read(visualScheduleRepositoryProvider)
          .overwriteForStudents(
            studentIds: roster.map((s) => s.id).toList(),
            createdBy: uid,
            items: draft,
          );
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l.classScheduleSaved)));
      router.pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text(l.scheduleSaveError)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final roster = ref.watch(classStudentsStreamProvider).value ?? const [];

    return CalmScaffold(
      title: l.classScheduleTitle,
      icon: Icons.view_agenda_rounded,
      body: ConstrainedContent(
        child:
            roster.isEmpty
                ? EmptyState(
                  icon: Icons.groups_rounded,
                  message: l.taskNoStudentsInClass,
                )
                : ListView(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  children: [
                    Text(
                      l.classScheduleHint,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    ScheduleEditor(
                      initialItems: const [],
                      saving: _saving,
                      onCancel: () => context.pop(),
                      onConfirm: (draft) => _confirm(draft, roster),
                    ),
                  ],
                ),
      ),
    );
  }
}
