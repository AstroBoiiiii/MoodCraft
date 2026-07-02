import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moodcraft/l10n/app_localizations.dart';

import '../../app/theme/tokens.dart';
import '../../core/models/app_user.dart';
import '../../core/models/student.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/widgets/contact_card.dart';
import '../../core/widgets/profile_header.dart';
import '../../core/widgets/section_card.dart';
import '../../core/widgets/sensory_read_only_view.dart';
import '../journal/journal_section.dart';
import '../schedule/schedule_section.dart';

/// A student plus their resolved teacher/parent contacts — everything the
/// detail view needs. Shared by the teacher's detail screen (pushed route and
/// wide two-pane) so both watch the same stream.
class StudentDetail {
  const StudentDetail({
    required this.student,
    required this.teachers,
    required this.parents,
  });
  final Student student;
  final List<AppUser> teachers;
  final List<AppUser> parents;
}

final studentDetailProvider = StreamProvider.autoDispose
    .family<StudentDetail?, String>((ref, id) async* {
      final repo = ref.watch(studentRepositoryProvider);
      final userRepo = ref.watch(userRepositoryProvider);
      await for (final student in repo.watchStudent(id)) {
        if (student == null) {
          yield null;
          continue;
        }
        final teachers = await userRepo.getUsersFor(student.teacherIds);
        final parents = await userRepo.getUsersFor(student.parentIds);
        yield StudentDetail(
          student: student,
          teachers: teachers,
          parents: parents,
        );
      }
    });

enum _DetailTab { overview, schedule, journal }

/// The tabbed student/child detail body shared by the teacher's detail screen
/// and the parent's monitoring tab: Overview (profile, sensory settings,
/// contacts), Schedule and Journal, one concern per tab so nothing is crammed
/// into a single scroll (CLAUDE.md section 4.5 — one action per screen).
/// Switching uses a [SegmentedButton] like the rest of the app: no swipe
/// gestures, no surprises. Tabs live in an [IndexedStack] so an in-progress
/// schedule edit survives a tab switch.
///
/// Callers MUST pass `key: ValueKey(student.id)`: [StudentScheduleSection]
/// keeps its edit draft across `studentId` changes, so without the key a draft
/// started for one student could be saved onto another when the two-pane
/// roster switches students.
class StudentDetailTabs extends StatefulWidget {
  const StudentDetailTabs({
    required this.student,
    required this.teachers,
    required this.parents,
    required this.canEditSchedule,
    this.onRemoveParent,
    super.key,
  });

  final Student student;
  final List<AppUser> teachers;
  final List<AppUser> parents;
  final bool canEditSchedule;

  /// When set (teacher view), parent contact cards get a remove button.
  final void Function(AppUser parent)? onRemoveParent;

  @override
  State<StudentDetailTabs> createState() => _StudentDetailTabsState();
}

class _StudentDetailTabsState extends State<StudentDetailTabs> {
  _DetailTab _tab = _DetailTab.overview;

  @override
  void didUpdateWidget(StudentDetailTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A different student means a fresh start on Overview — predictable when
    // switching students in the wide two-pane roster.
    if (oldWidget.student.id != widget.student.id) {
      _tab = _DetailTab.overview;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<_DetailTab>(
          segments: [
            ButtonSegment(
              value: _DetailTab.overview,
              label: Text(l.tabOverview),
              icon: const Icon(Icons.person_rounded),
            ),
            ButtonSegment(
              value: _DetailTab.schedule,
              label: Text(l.tabSchedule),
              icon: const Icon(Icons.today_rounded),
            ),
            ButtonSegment(
              value: _DetailTab.journal,
              label: Text(l.tabJournal),
              icon: const Icon(Icons.book_rounded),
            ),
          ],
          selected: {_tab},
          onSelectionChanged: (s) => setState(() => _tab = s.first),
        ),
        const SizedBox(height: AppSpacing.lg),
        Expanded(
          child: IndexedStack(
            index: _tab.index,
            children: [
              ListView(children: _overviewChildren(l)),
              ListView(
                children: [
                  StudentScheduleSection(
                    studentId: widget.student.id,
                    canEdit: widget.canEditSchedule,
                  ),
                ],
              ),
              ListView(
                children: [JournalHistorySection(studentId: widget.student.id)],
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _overviewChildren(AppLocalizations l) {
    final student = widget.student;
    return [
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
      if (widget.teachers.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.lg),
        SectionCard(
          title: l.teacherLabel,
          icon: Icons.person_rounded,
          child: Column(
            children: [for (final u in widget.teachers) ContactCard(user: u)],
          ),
        ),
      ],
      if (widget.parents.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.lg),
        SectionCard(
          title: l.parentLabel,
          icon: Icons.people_rounded,
          child: Column(
            children: [
              for (final u in widget.parents)
                ContactCard(
                  user: u,
                  onRemove:
                      widget.onRemoveParent == null
                          ? null
                          : () => widget.onRemoveParent!(u),
                  removeTooltip: l.parentRemove,
                ),
            ],
          ),
        ),
      ],
      const SizedBox(height: AppSpacing.lg),
      // FR8 hook: the report itself is not built yet, so this stays a calm
      // disabled button rather than a dead end.
      SectionCard(
        title: l.progressReport,
        icon: Icons.assessment_rounded,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.progressReportSoon,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            FilledButton.tonalIcon(
              onPressed: null,
              icon: const Icon(Icons.assessment_rounded),
              label: Text(l.comingSoon),
            ),
          ],
        ),
      ),
    ];
  }
}
