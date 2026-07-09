import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moodcraft/l10n/app_localizations.dart';

import '../../app/theme/tokens.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/visual_schedule.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/repository_providers.dart';

/// FR13 — the child's repeating daily routine, shown the same calm way to every
/// role and embeddable inside any scrolling parent (teacher/parent detail
/// screens, or the student's full-screen view). Pass [canEdit] true for
/// teacher/parent.
///
/// The routine is set once and shown every day (predictable + consistent).
/// Each activity has a time and a label, with an optional picture. The child
/// view sorts by time and highlights the activity happening **now** and the one
/// coming **next**, derived purely from the device clock.
class StudentScheduleSection extends ConsumerStatefulWidget {
  const StudentScheduleSection({
    required this.studentId,
    required this.canEdit,
    super.key,
  });

  final String studentId;
  final bool canEdit;

  @override
  ConsumerState<StudentScheduleSection> createState() =>
      _StudentScheduleSectionState();
}

class _StudentScheduleSectionState
    extends ConsumerState<StudentScheduleSection> {
  bool _editing = false;
  // The server schedule captured when editing started, so _confirm can rebase
  // this role's add/remove delta onto the latest copy instead of overwriting.
  List<ScheduleItem> _baseline = [];
  bool _saving = false;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Refresh once a minute so the "Now"/"Next" highlight advances live.
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted && !_editing) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _startEdit(VisualSchedule? current) {
    setState(() {
      _baseline = List<ScheduleItem>.from(current?.sortedItems ?? const []);
      _editing = true;
    });
  }

  void _cancel() {
    setState(() {
      _editing = false;
      _baseline = [];
    });
  }

  Future<void> _confirm(List<ScheduleItem> draft) async {
    setState(() => _saving = true);
    final uid = ref.read(currentUserProvider)?.uid ?? '';
    try {
      // Rebase this role's changes onto the latest server schedule (transaction)
      // so a teacher/parent editing the same child don't overwrite each other,
      // and a slot taken meanwhile is rejected rather than double-booked.
      await ref
          .read(visualScheduleRepositoryProvider)
          .reconcile(
            studentId: widget.studentId,
            createdBy: uid,
            baseline: _baseline,
            draft: draft,
          );
      if (!mounted) return;
      setState(() {
        _saving = false;
        _editing = false;
        _baseline = [];
      });
    } on ScheduleConflictException {
      if (!mounted) return;
      setState(() => _saving = false);
      // Keep the editor open so the user can adjust the clashing time.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).scheduleClashError),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      final l = AppLocalizations.of(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.scheduleSaveError)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheduleAsync = ref.watch(studentScheduleProvider(widget.studentId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l.scheduleSectionTitle,
                style: theme.textTheme.titleMedium,
              ),
            ),
            if (widget.canEdit && !_editing)
              TextButton.icon(
                onPressed: () => _startEdit(scheduleAsync.value),
                icon: const Icon(Icons.edit_rounded, size: 20),
                label: Text(l.editProfile),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (_editing)
          ScheduleEditor(
            initialItems: _baseline,
            saving: _saving,
            onCancel: _cancel,
            onConfirm: _confirm,
          )
        else
          scheduleAsync.when(
            loading:
                () => const Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: Center(child: CircularProgressIndicator()),
                ),
            // Surface a sync/permission problem instead of masking it as empty.
            error:
                (_, __) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Text(
                    l.scheduleUnavailable,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            data: (schedule) => _buildView(schedule, l, theme),
          ),
      ],
    );
  }

  Widget _buildView(
    VisualSchedule? schedule,
    AppLocalizations l,
    ThemeData theme,
  ) {
    final items = schedule?.sortedItems ?? const [];
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Text(
          l.scheduleEmpty,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    // Now/next derived from the device clock (shared with [ScheduleNowNextCard]).
    final nn = resolveNowNext(items);
    final currentIndex = nn.current;
    final nextIndex = nn.next;

    return Column(
      children: [
        for (var i = 0; i < items.length; i++)
          _ActivityTile(
            item: items[i],
            isNow: i == currentIndex,
            isNext: i == nextIndex,
          ),
      ],
    );
  }
}

/// The draft schedule editor (FR13): the working list of activities, an
/// add-activity panel (start/end time, label, optional picture; time slots
/// can never overlap), and Cancel/Confirm buttons. What Confirm *means* is the
/// caller's business: [StudentScheduleSection] rebases the draft onto one
/// child's schedule, the teacher's class-schedule screen writes it to every
/// student. [saving] disables the buttons while the caller commits; the editor
/// stays open on a failed save so nothing typed is lost.
class ScheduleEditor extends StatefulWidget {
  const ScheduleEditor({
    required this.initialItems,
    required this.onConfirm,
    required this.onCancel,
    this.saving = false,
    super.key,
  });

  final List<ScheduleItem> initialItems;
  final ValueChanged<List<ScheduleItem>> onConfirm;
  final VoidCallback onCancel;
  final bool saving;

  @override
  State<ScheduleEditor> createState() => _ScheduleEditorState();
}

class _ScheduleEditorState extends State<ScheduleEditor> {
  late final List<ScheduleItem> _draft = List<ScheduleItem>.from(
    widget.initialItems,
  );
  TimeOfDay? _pickedTime;
  TimeOfDay? _pickedEndTime;
  String? _pickedIcon; // null = no picture
  final TextEditingController _labelController = TextEditingController();

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime({required bool isEnd}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: (isEnd ? _pickedEndTime : _pickedTime) ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isEnd) {
          _pickedEndTime = picked;
        } else {
          _pickedTime = picked;
        }
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _addActivity() {
    final l = AppLocalizations.of(context);
    final label = _labelController.text.trim();
    if (label.isEmpty || _pickedTime == null || _pickedEndTime == null) return;

    final candidate = ScheduleItem(
      time: _formatTime(_pickedTime!),
      endTime: _formatTime(_pickedEndTime!),
      label: label,
      iconKey: _pickedIcon,
    );

    // End must be after start.
    if (candidate.endMinutesOfDay <= candidate.minutesOfDay) {
      _showError(l.scheduleEndError);
      return;
    }
    // No overlap with any existing activity.
    if (_draft.any((existing) => existing.overlaps(candidate))) {
      _showError(l.scheduleClashError);
      return;
    }

    setState(() {
      _draft.add(candidate);
      _draft.sort((a, b) => a.minutesOfDay.compareTo(b.minutesOfDay));
      _labelController.clear();
      _pickedTime = null;
      _pickedEndTime = null;
      _pickedIcon = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_draft.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              l.scheduleEmpty,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        for (var i = 0; i < _draft.length; i++)
          Card(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: ListTile(
              leading: _TimeChip(
                time: _draft[i].time,
                endTime: _draft[i].endTime,
                theme: theme,
              ),
              title: Text(_draft[i].label),
              subtitle:
                  (_draft[i].iconKey?.isNotEmpty ?? false)
                      ? Icon(
                        scheduleIcon(_draft[i].iconKey!),
                        color: theme.colorScheme.primary,
                      )
                      : null,
              trailing: IconButton(
                tooltip: l.cancelEdit,
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: theme.colorScheme.error,
                ),
                onPressed: () => setState(() => _draft.removeAt(i)),
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
        const Divider(),
        const SizedBox(height: AppSpacing.sm),
        // Add-activity panel: start + end time (required), label (required),
        // picture (optional). Times can't overlap another activity.
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickTime(isEnd: false),
                icon: const Icon(Icons.schedule_rounded),
                label: Text(
                  _pickedTime == null
                      ? l.scheduleTimeLabel
                      : _pickedTime!.format(context),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickTime(isEnd: true),
                icon: const Icon(Icons.schedule_outlined),
                label: Text(
                  _pickedEndTime == null
                      ? l.scheduleEndTimeLabel
                      : _pickedEndTime!.format(context),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _labelController,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: l.scheduleActivityHint,
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (_) => _addActivity(),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(l.schedulePictureOptional, style: theme.textTheme.labelLarge),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _NoneChoice(
              selected: _pickedIcon == null,
              label: l.schedulePictureNone,
              onTap: () => setState(() => _pickedIcon = null),
            ),
            for (final key in kScheduleIconCatalog.keys)
              _IconChoice(
                icon: kScheduleIconCatalog[key]!,
                selected: key == _pickedIcon,
                onTap: () => setState(() => _pickedIcon = key),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.tonalIcon(
            onPressed: _addActivity,
            icon: const Icon(Icons.add_rounded),
            label: Text(l.scheduleAddActivity),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.saving ? null : widget.onCancel,
                child: Text(l.cancelEdit),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: FilledButton(
                onPressed:
                    widget.saving ? null : () => widget.onConfirm(_draft),
                child:
                    widget.saving
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : Text(l.confirmEdit),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Index of the activity happening now and the first one still to come, derived
/// from the device clock. -1 when none. Untimed items (minutesOfDay > 24h) are
/// ignored. Shared by the full schedule view and the home [ScheduleNowNextCard].
({int current, int next}) resolveNowNext(List<ScheduleItem> items) {
  final nowMinutes = TimeOfDay.now().hour * 60 + TimeOfDay.now().minute;
  var current = -1;
  var next = -1;
  for (var i = 0; i < items.length; i++) {
    final start = items[i].minutesOfDay;
    if (start > 24 * 60) continue;
    final end = items[i].endMinutesOfDay;
    if (start <= nowMinutes && nowMinutes < end) {
      current = i;
    } else if (start > nowMinutes && next == -1) {
      next = i;
    }
  }
  return (current: current, next: next);
}

/// Compact "happening now / coming next" summary of a child's routine (FR13),
/// shown at the top of the student home. Taps through to the full schedule.
/// Renders nothing when there is no routine or nothing is current/upcoming, so
/// the home stays calm and uncluttered.
class ScheduleNowNextCard extends ConsumerWidget {
  const ScheduleNowNextCard({required this.studentId, this.onTap, super.key});

  final String studentId;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final items =
        ref.watch(studentScheduleProvider(studentId)).value?.sortedItems ??
        const [];
    if (items.isEmpty) return const SizedBox.shrink();
    final nn = resolveNowNext(items);
    var currentIndex = nn.current;
    var nextIndex = nn.next;
    // The routine repeats every day. If today's timed activities are all over
    // (nothing now or later today), the next thing is tomorrow's first one — so
    // show that instead of hiding the card. Keeps the timetable visible on the
    // home page whatever the time of day.
    if (currentIndex == -1 && nextIndex == -1) {
      nextIndex = items.indexWhere((i) => i.minutesOfDay <= 24 * 60);
    }
    if (currentIndex == -1 && nextIndex == -1) return const SizedBox.shrink();
    final onContainer = theme.colorScheme.onPrimaryContainer;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Ink(
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.view_agenda_rounded,
                      size: 20,
                      color: onContainer,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        l.scheduleTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: onContainer,
                        ),
                      ),
                    ),
                    if (onTap != null)
                      Icon(Icons.chevron_right_rounded, color: onContainer),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                if (currentIndex != -1)
                  _NowNextLine(
                    label: l.scheduleNow,
                    item: items[currentIndex],
                    onContainer: onContainer,
                  )
                else
                  // Nothing scheduled right now: a gentle free-time nudge toward
                  // the activities, rather than a blank space.
                  Text(
                    l.scheduleFreeNow,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: onContainer,
                    ),
                  ),
                if (nextIndex != -1) ...[
                  const SizedBox(height: AppSpacing.xs),
                  _NowNextLine(
                    label: l.scheduleNext,
                    item: items[nextIndex],
                    onContainer: onContainer,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NowNextLine extends StatelessWidget {
  const _NowNextLine({
    required this.label,
    required this.item,
    required this.onContainer,
  });

  final String label;
  final ScheduleItem item;
  final Color onContainer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasIcon = item.iconKey?.isNotEmpty ?? false;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          _StatusChip(label: label),
          const SizedBox(width: AppSpacing.sm),
          if (hasIcon) ...[
            Icon(scheduleIcon(item.iconKey!), size: 22, color: onContainer),
            const SizedBox(width: AppSpacing.xs),
          ],
          Expanded(
            child: Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyLarge?.copyWith(color: onContainer),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.item,
    required this.isNow,
    required this.isNext,
  });

  final ScheduleItem item;
  final bool isNow;
  final bool isNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final hasIcon = item.iconKey?.isNotEmpty ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      color: isNow ? theme.colorScheme.primaryContainer : null,
      child: ListTile(
        leading: _TimeChip(
          time: item.time,
          endTime: item.endTime,
          theme: theme,
          onPrimary: isNow,
        ),
        title: Text(
          item.label,
          style: theme.textTheme.titleMedium?.copyWith(
            color: isNow ? theme.colorScheme.onPrimaryContainer : null,
            fontWeight: isNow ? FontWeight.w600 : null,
          ),
        ),
        trailing:
            hasIcon
                ? Icon(
                  scheduleIcon(item.iconKey!),
                  size: 28,
                  color:
                      isNow
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.primary,
                )
                : (isNow || isNext)
                ? _StatusChip(label: isNow ? l.scheduleNow : l.scheduleNext)
                : null,
        subtitle:
            hasIcon && (isNow || isNext)
                ? Align(
                  alignment: Alignment.centerLeft,
                  child: _StatusChip(
                    label: isNow ? l.scheduleNow : l.scheduleNext,
                  ),
                )
                : null,
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({
    required this.time,
    required this.endTime,
    required this.theme,
    this.onPrimary = false,
  });
  final String time;
  final String endTime;
  final ThemeData theme;
  final bool onPrimary;

  /// Locale-formatted time when parseable, else the raw string (or '—').
  String _fmt(BuildContext context, String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length == 2) {
      final h = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      if (h != null && m != null) {
        return TimeOfDay(hour: h, minute: m).format(context);
      }
    }
    return hhmm.isEmpty ? '—' : hhmm;
  }

  @override
  Widget build(BuildContext context) {
    final fg =
        onPrimary ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface;
    return Container(
      constraints: const BoxConstraints(minWidth: 64),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color:
            onPrimary
                ? theme.colorScheme.primary
                : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _fmt(context, time),
            textAlign: TextAlign.center,
            style: theme.textTheme.labelLarge?.copyWith(color: fg),
          ),
          Text(
            _fmt(context, endTime),
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: fg.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoneChoice extends StatelessWidget {
  const _NoneChoice({
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        alignment: Alignment.center,
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
        child: Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color:
                selected
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _IconChoice extends StatelessWidget {
  const _IconChoice({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
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
        child: Icon(
          icon,
          size: 28,
          color:
              selected
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
