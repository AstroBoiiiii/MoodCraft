import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moodcraft/l10n/app_localizations.dart';

import '../../app/theme/tokens.dart';
import '../../core/models/journal_entry.dart';
import '../../core/models/student.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/widgets/calm_scaffold.dart';
import '../../core/widgets/constrained_content.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/initial_avatar.dart';
import '../journal/journal_section.dart';

/// One feed row: whose feeling it is plus the entry itself.
typedef JournalFeedItem = ({Student student, JournalEntry entry});

/// Newest-first journal entries across every student on the teacher's roster,
/// each tagged with its student. Built by merging the existing per-student
/// streams (equality-filtered queries the security rules can prove) rather
/// than one cross-student query, so it needs no new rules or indexes.
final classJournalFeedProvider =
    Provider.autoDispose<AsyncValue<List<JournalFeedItem>>>((ref) {
      final studentsAsync = ref.watch(classStudentsStreamProvider);
      return studentsAsync.when(
        loading: () => const AsyncValue.loading(),
        error: AsyncValue.error,
        data: (students) {
          final items = <JournalFeedItem>[];
          for (final student in students) {
            final entries =
                ref.watch(studentJournalProvider(student.id)).value ?? const [];
            for (final entry in entries) {
              items.add((student: student, entry: entry));
            }
          }
          items.sort((a, b) => b.entry.timestamp.compareTo(a.entry.timestamp));
          return AsyncValue.data(items);
        },
      );
    });

/// FR12 — the teacher's own Journal tab. Opens on the latest feelings logged
/// across the whole roster (each card names its student and takes a comment
/// directly); typing in the search field finds a student, and picking one (by
/// search or by tapping a feed card) shows that child's full journal with the
/// same comment ability as before.
class TeacherJournalScreen extends ConsumerStatefulWidget {
  const TeacherJournalScreen({super.key});

  @override
  ConsumerState<TeacherJournalScreen> createState() =>
      _TeacherJournalScreenState();
}

class _TeacherJournalScreenState extends ConsumerState<TeacherJournalScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _selectedId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _select(Student student) {
    setState(() {
      _selectedId = student.id;
      _query = '';
      _searchController.clear();
    });
  }

  void _clearSelection() => setState(() => _selectedId = null);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final students =
        ref.watch(classStudentsStreamProvider).value ?? const <Student>[];

    // A stale selection (student removed from the roster) falls back to the
    // feed rather than a dead end.
    Student? selected;
    for (final s in students) {
      if (s.id == _selectedId) selected = s;
    }

    return CalmScaffold(
      title: l.navJournal,
      icon: Icons.book_rounded,
      body: ConstrainedContent(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v.trim()),
              decoration: InputDecoration(
                hintText: l.journalSearchStudents,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon:
                    _query.isEmpty
                        ? null
                        : IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed:
                              () => setState(() {
                                _query = '';
                                _searchController.clear();
                              }),
                        ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child:
                  _query.isNotEmpty
                      ? _searchResults(l, students)
                      : selected != null
                      ? _studentJournal(l, selected)
                      : _latestFeed(l),
            ),
          ],
        ),
      ),
    );
  }

  /// Students whose name contains the query, as big tap targets.
  Widget _searchResults(AppLocalizations l, List<Student> students) {
    final q = _query.toLowerCase();
    final matches =
        students.where((s) => s.name.toLowerCase().contains(q)).toList();
    if (matches.isEmpty) {
      return EmptyState(
        icon: Icons.search_off_rounded,
        message: l.noStudentsYet,
        compact: true,
      );
    }
    return ListView(
      children: [
        for (final student in matches)
          Card(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: ListTile(
              leading: InitialAvatar(name: student.name),
              title: Text(student.name),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _select(student),
            ),
          ),
      ],
    );
  }

  /// One student's full journal, with a calm way back to the feed.
  Widget _studentJournal(AppLocalizations l, Student student) {
    final theme = Theme.of(context);
    return ListView(
      children: [
        Row(
          children: [
            TextButton.icon(
              onPressed: _clearSelection,
              icon: const Icon(Icons.arrow_back_rounded),
              label: Text(l.journalAllStudents),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            InitialAvatar(name: student.name),
            const SizedBox(width: AppSpacing.md),
            Text(student.name, style: theme.textTheme.titleLarge),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        JournalHistorySection(studentId: student.id, showTitle: false),
      ],
    );
  }

  /// The latest feelings logged across the whole roster, newest first. Each
  /// card names its student, takes the teacher's comment directly, and taps
  /// through to that student's full journal.
  Widget _latestFeed(AppLocalizations l) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final feedAsync = ref.watch(classJournalFeedProvider);

    return feedAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (e, _) => EmptyState(
            icon: Icons.book_rounded,
            message: l.journalUnavailable,
            compact: true,
          ),
      data: (items) {
        if (items.isEmpty) {
          return EmptyState(
            icon: Icons.book_rounded,
            message: l.journalEmpty,
            compact: true,
          );
        }
        return ListView(
          children: [
            Text(l.journalLatestEntries, style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            for (final item in items)
              JournalEntryCard(
                entry: item.entry,
                currentRole: user?.role,
                studentName: item.student.name,
                onAnnotate:
                    user == null
                        ? null
                        : () => showJournalCommentDialog(
                          context,
                          ref,
                          item.entry,
                          user,
                        ),
                onTap: () => _select(item.student),
              ),
          ],
        );
      },
    );
  }
}
