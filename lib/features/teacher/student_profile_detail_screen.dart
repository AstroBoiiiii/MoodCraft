import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moodcraft/l10n/app_localizations.dart';

import '../../app/theme/tokens.dart';
import '../../core/models/app_user.dart';
import '../../core/models/student.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/widgets/calm_scaffold.dart';
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

    return CalmScaffold(
      title: l.studentProfile,
      icon: Icons.person_rounded,
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text(l.comingSoon)),
        data: (detail) {
          if (detail == null) return Center(child: Text(l.comingSoon));
          return _DetailBody(detail: detail, theme: theme, l: l);
        },
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.detail,
    required this.theme,
    required this.l,
  });

  final _StudentDetail detail;
  final ThemeData theme;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final student = detail.student;
    return ListView(
      children: [
        Center(
          child: CircleAvatar(
            radius: 48,
            child: Text(
              student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
              style: theme.textTheme.headlineMedium,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Center(child: Text(student.name, style: theme.textTheme.titleLarge)),
        const SizedBox(height: AppSpacing.sm),
        if (student.age > 0)
          Center(
            child: Text(
              l.ageYearsOld(student.age),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        Center(
          child: Chip(
            avatar: const Icon(Icons.star_rounded, size: 18),
            label: Text(l.levelStars(student.level, student.stars)),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const Divider(),
        const SizedBox(height: AppSpacing.sm),
        Text(l.sensorySettings, style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        SensoryReadOnlyView(settings: student.sensorySettings),
        if (detail.teachers.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          const Divider(),
          const SizedBox(height: AppSpacing.sm),
          Text(l.teacherLabel, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          for (final u in detail.teachers) _ContactTile(user: u),
        ],
        if (detail.parents.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          const Divider(),
          const SizedBox(height: AppSpacing.sm),
          Text(l.parentLabel, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          for (final u in detail.parents) _ContactTile(user: u),
        ],
        const SizedBox(height: AppSpacing.lg),
        const Divider(),
        const SizedBox(height: AppSpacing.sm),
        StudentScheduleSection(studentId: student.id, canEdit: true),
        const SizedBox(height: AppSpacing.lg),
        const Divider(),
        const SizedBox(height: AppSpacing.sm),
        JournalHistorySection(studentId: student.id, canAnnotate: true),
      ],
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.name, style: theme.textTheme.titleSmall),
            if (user.username.isNotEmpty)
              Text('@${user.username}', style: theme.textTheme.bodySmall),
            if (user.phone.isNotEmpty)
              Text(user.phone, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
