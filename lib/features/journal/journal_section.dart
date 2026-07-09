import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moodcraft/l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';

import '../../app/theme/tokens.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/app_user.dart';
import '../../core/models/enums.dart';
import '../../core/models/journal_entry.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/widgets/narrated_text.dart';

/// FR12 — Emotion journal. The child logs how they feel with a picture (no
/// reading or writing), optionally tagging where they were. It is calm and
/// reversible: tap a face, maybe a place, then Save. There is no wrong choice
/// and no failure state. Teacher and parent see the same entries (read-only,
/// with the option to add a short note) on their child-detail screens.
///
/// Like [StudentScheduleSection] (FR13) this lives in one place and is embedded
/// by every role's screen, so the journal looks and behaves identically
/// everywhere (predictable & consistent, CLAUDE.md section 4.2).

/// The child's "How do you feel?" logger. Writes a [JournalEntry] for
/// [studentId] through the journal repository (Firestore-backed, so it appears
/// instantly from the offline cache and syncs to teacher/parent — FR14).
class JournalLogger extends ConsumerStatefulWidget {
  const JournalLogger({required this.studentId, super.key});

  final String studentId;

  @override
  ConsumerState<JournalLogger> createState() => _JournalLoggerState();
}

class _JournalLoggerState extends ConsumerState<JournalLogger> {
  Emotion? _emotion;
  String? _context; // null = no place chosen (optional)
  final _noteController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final emotion = _emotion;
    if (emotion == null || _saving) return;
    setState(() => _saving = true);
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final note = _noteController.text.trim();
    try {
      await ref
          .read(journalRepositoryProvider)
          .add(
            JournalEntry(
              id: const Uuid().v4(),
              studentId: widget.studentId,
              emotionIcon: emotion,
              contextIcon: _context,
              note: note.isEmpty ? null : note,
              timestamp: DateTime.now(),
            ),
          );
      if (!mounted) return;
      // Calm, positive confirmation — never a "well done you got it right"
      // (there is nothing to get right here).
      setState(() {
        _emotion = null;
        _context = null;
        _noteController.clear();
        _saving = false;
      });
      messenger.showSnackBar(SnackBar(content: Text(l.journalSaved)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text(l.journalSaveError)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NarratedText(l.journalHowAreYou, style: theme.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (final emotion in Emotion.values)
              _EmotionChoice(
                emotion: emotion,
                label: emotionLabel(emotion, l),
                selected: _emotion == emotion,
                onTap: () => setState(() => _emotion = emotion),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(l.journalContextPrompt, style: theme.textTheme.labelLarge),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final key in kJournalContextCatalog.keys)
              _ContextChoice(
                icon: kJournalContextCatalog[key]!,
                label: contextLabel(key, l),
                selected: _context == key,
                // Tapping the chosen place again clears it (it's optional).
                onTap:
                    () =>
                        setState(() => _context = _context == key ? null : key),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(l.journalNotePrompt, style: theme.textTheme.labelLarge),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _noteController,
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: l.journalNoteHint,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          width: double.infinity,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppConstants.minTapTarget,
            ),
            child: ElevatedButton.icon(
              onPressed: (_emotion == null || _saving) ? null : _save,
              icon:
                  _saving
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.check_rounded, size: 28),
              label: Text(l.journalSave),
            ),
          ),
        ),
      ],
    );
  }
}

/// Newest-first history of a student's feelings. Shared by the child's own
/// journal tab and the teacher/parent child-detail screens. Teacher and parent
/// can each leave one role-labelled comment per entry (shown distinctly as
/// "Teacher: …" / "Parent: …"); the child logs and reads but does not comment on
/// their own entries.
class JournalHistorySection extends ConsumerWidget {
  const JournalHistorySection({
    required this.studentId,
    this.showTitle = true,
    super.key,
  });

  final String studentId;
  final bool showTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final entriesAsync = ref.watch(studentJournalProvider(studentId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle) ...[
          Text(l.journalSectionTitle, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
        ],
        entriesAsync.when(
          loading:
              () => const Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Center(child: CircularProgressIndicator()),
              ),
          // Surface a sync/permission problem rather than masking it as empty.
          error:
              (_, __) => Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Text(
                  l.journalUnavailable,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          data: (entries) {
            if (entries.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Text(
                  l.journalEmpty,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            }
            return Column(
              children: [
                for (final entry in entries)
                  JournalEntryCard(
                    entry: entry,
                    currentRole: user?.role,
                    // Only teacher/parent annotate. The child logs and reads
                    // their feelings but doesn't comment on their own entry.
                    onAnnotate:
                        (user == null || user.role == UserRole.student)
                            ? null
                            : () => showJournalCommentDialog(
                              context,
                              ref,
                              entry,
                              user,
                            ),
                    // The child can remove their own entries; it's their
                    // journal. Teacher/parent keep their read + comment view.
                    onDelete:
                        user?.role == UserRole.student
                            ? () => _confirmDelete(context, ref, entry)
                            : null,
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  /// Removes a journal entry after a calm confirm. Reversible in spirit — the
  /// child simply chooses to take a feeling back; no scolding, no failure tone.
  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    JournalEntry entry,
  ) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(l.journalDeleteTitle),
            content: Text(l.journalDeleteConfirm),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l.cancelEdit),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(ctx).colorScheme.error,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l.actionDelete),
              ),
            ],
          ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(journalRepositoryProvider).delete(entry.id);
      messenger.showSnackBar(SnackBar(content: Text(l.journalDeleted)));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l.journalSaveError)));
    }
  }
}

/// The teacher/parent "add or edit my comment" dialog for one journal entry.
/// Each role edits only its own comment (one per role); an empty save clears
/// it. Shared by [JournalHistorySection] and the teacher's journal feed.
Future<void> showJournalCommentDialog(
  BuildContext context,
  WidgetRef ref,
  JournalEntry entry,
  AppUser user,
) async {
  final l = AppLocalizations.of(context);
  final existing = entry.commentBy(user.role);
  final controller = TextEditingController(text: existing?.text ?? '');
  final text = await showDialog<String>(
    context: context,
    builder:
        (ctx) => AlertDialog(
          title: Text(l.journalCommentTitle),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: l.journalCommentHint,
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            // Only when a comment already exists — clears just this role's
            // comment (passing an empty string through withComment below).
            if (existing != null)
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(ctx).colorScheme.error,
                ),
                onPressed: () => Navigator.pop(ctx, ''),
                child: Text(l.actionDelete),
              ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l.cancelEdit),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: Text(l.confirmEdit),
            ),
          ],
        ),
  );
  controller.dispose();
  if (text == null) return; // cancelled
  // The journal repo writes by document id, so re-adding the edited entry
  // updates it in place. withComment replaces just this role's comment (an
  // empty text clears it), leaving the other roles' comments untouched.
  await ref
      .read(journalRepositoryProvider)
      .add(
        entry.withComment(
          JournalComment(
            authorUid: user.uid,
            authorRole: user.role,
            authorName: user.name,
            text: text,
            timestamp: DateTime.now(),
          ),
        ),
      );
}

/// Friendly role label for a journal comment author.
String roleLabel(UserRole role, AppLocalizations l) => switch (role) {
  UserRole.student => l.roleStudent,
  UserRole.teacher => l.roleTeacher,
  UserRole.parent => l.roleParent,
};

/// Friendly emotion label (kept gentle: neutral reads as "Okay", not "Neutral").
String emotionLabel(Emotion emotion, AppLocalizations l) => switch (emotion) {
  Emotion.happy => l.emotionHappy,
  Emotion.sad => l.emotionSad,
  Emotion.scared => l.emotionScared,
  Emotion.angry => l.emotionAngry,
  Emotion.surprised => l.emotionSurprised,
  Emotion.neutral => l.emotionOkay,
};

/// Label for a journal context key; falls back to the raw key if unrecognised.
String contextLabel(String key, AppLocalizations l) => switch (key) {
  'home' => l.journalCtxHome,
  'class' => l.journalCtxClass,
  'play' => l.journalCtxPlay,
  'outside' => l.journalCtxOutside,
  'meal' => l.journalCtxMeal,
  'friends' => l.journalCtxFriends,
  _ => key,
};

class _EmotionChoice extends StatelessWidget {
  const _EmotionChoice({
    required this.emotion,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final Emotion emotion;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = kEmotionColor[emotion] ?? theme.colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color:
              selected
                  ? color.withValues(alpha: 0.18)
                  : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
            color: selected ? color : theme.colorScheme.outlineVariant,
            width: selected ? 3 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(kEmotionIcon[emotion], size: 48, color: color),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContextChoice extends StatelessWidget {
  const _ContextChoice({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color:
              selected
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadii.sm),
          border: Border.all(
            color:
                selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color:
                  selected
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color:
                    selected
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One journal entry as a calm card: emotion, place, time, the child's note
/// and any role-labelled comments. Shared by [JournalHistorySection] and the
/// teacher's cross-student journal feed (which names the student on each card).
class JournalEntryCard extends StatelessWidget {
  const JournalEntryCard({
    required this.entry,
    this.currentRole,
    this.studentName,
    this.onAnnotate,
    this.onDelete,
    this.onTap,
    super.key,
  });

  final JournalEntry entry;

  /// Role of the signed-in viewer, so the comment button reads "add" vs "edit"
  /// for their own comment. Null = nobody signed in (read-only).
  final UserRole? currentRole;

  /// Shown above the feeling when the card sits in a mixed feed (the teacher's
  /// latest-entries view), so it is clear whose feeling this is. Null hides it.
  final String? studentName;
  final VoidCallback? onAnnotate;

  /// Provided only when the viewer may delete this entry (the student's own
  /// journal). Null hides the delete affordance.
  final VoidCallback? onDelete;

  /// Optional tap-through (the teacher's feed opens that student's journal).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final color = kEmotionColor[entry.emotionIcon] ?? theme.colorScheme.primary;
    final contextIcon = journalContextIcon(entry.contextIcon);
    // Comments oldest-first so the conversation reads top to bottom.
    final comments =
        entry.comments.toList()
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final hasOwnComment =
        currentRole != null && entry.commentBy(currentRole!) != null;
    final hasNote = entry.note != null && entry.note!.trim().isNotEmpty;

    // A custom Card/Row (not a ListTile): the note + comments make the entry an
    // arbitrary height, which a ListTile's fixed-height layout overflows. This
    // grows to fit its content.
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.18),
                child: Icon(kEmotionIcon[entry.emotionIcon], color: color),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (studentName != null)
                      Text(
                        studentName!,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    Text(
                      emotionLabel(entry.emotionIcon, l),
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: AppSpacing.sm,
                      children: [
                        if (contextIcon != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                contextIcon,
                                size: 16,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Text(contextLabel(entry.contextIcon!, l)),
                            ],
                          ),
                        Text(
                          _friendlyTime(entry.timestamp, l),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    if (hasNote)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Text(
                          entry.note!,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    for (final c in comments)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: RichText(
                          text: TextSpan(
                            style: theme.textTheme.bodyMedium,
                            children: [
                              TextSpan(
                                text: '${roleLabel(c.authorRole, l)}: ',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              TextSpan(
                                text: c.text,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (onAnnotate != null || onDelete != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onAnnotate != null)
                      IconButton(
                        tooltip: l.journalCommentTitle,
                        icon: Icon(
                          hasOwnComment
                              ? Icons.edit_note_rounded
                              : Icons.add_comment_outlined,
                        ),
                        onPressed: onAnnotate,
                      ),
                    if (onDelete != null)
                      IconButton(
                        tooltip: l.journalDeleteTitle,
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          color: theme.colorScheme.error,
                        ),
                        onPressed: onDelete,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A gentle, locale-light timestamp: "Today HH:mm" / "Yesterday HH:mm" /
/// "DD/MM HH:mm". Avoids exposing raw dates the child can't read.
String _friendlyTime(DateTime t, AppLocalizations l) {
  String two(int n) => n.toString().padLeft(2, '0');
  final hhmm = '${two(t.hour)}:${two(t.minute)}';
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(t.year, t.month, t.day);
  final diff = today.difference(day).inDays;
  if (diff <= 0) return '${l.journalToday} $hhmm';
  if (diff == 1) return '${l.journalYesterday} $hhmm';
  return '${t.day}/${t.month} $hhmm';
}
