import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moodcraft/l10n/app_localizations.dart';

import '../../app/theme/tokens.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/journal_entry.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/widgets/reward_celebration.dart'
    show rewardBadgeById, rewardBadgeLabel, rewardLevelTitle;
import '../journal/journal_section.dart' show emotionLabel;

/// Parent app shell: a small bottom navigation (Progress / Messages / Tasks).
///
/// The in-app half of FR9 milestone notifications (no push): when the linked
/// child earns reward badges, reaches a new personal level (FR11's title
/// ladder), or logs a new emotion journal entry (FR12), that the parent has
/// not seen, the Progress tab shows a red count and a calm popup announces
/// the news the next time the parent is in the app. Closing a popup
/// acknowledges it (the matching seen count catches up), so it never nags.
/// The signal is monotonic (badges are append-only, level only ever goes up,
/// journal entries are never deleted), so it can only ever mean "something
/// new about your child".
class ParentShell extends ConsumerStatefulWidget {
  const ParentShell(this.navigationShell, {super.key});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<ParentShell> createState() => _ParentShellState();
}

class _ParentShellState extends ConsumerState<ParentShell> {
  /// Guards against scheduling the popup more than once while it is open.
  bool _announcing = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final unseenBadges = ref.watch(parentUnseenBadgesProvider);
    final unseenLevel = ref.watch(parentUnseenLevelProvider);
    final unseenJournal = ref.watch(parentUnseenJournalProvider);
    final hasNews =
        unseenBadges.isNotEmpty ||
        unseenLevel != null ||
        unseenJournal.isNotEmpty;
    final newsCount =
        unseenBadges.length +
        (unseenLevel != null ? 1 : 0) +
        unseenJournal.length;

    // Announce new badges/level/journal entries the next frame there is
    // something and it isn't already showing — works on login and live while
    // the parent is in the app (e.g. the child logs a feeling right then).
    if (hasNews && !_announcing) {
      _announcing = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _announceNews());
    }

    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: widget.navigationShell.currentIndex,
        onDestinationSelected:
            (index) => widget.navigationShell.goBranch(
              index,
              initialLocation: index == widget.navigationShell.currentIndex,
            ),
        destinations: [
          NavigationDestination(
            icon: Badge(
              isLabelVisible: hasNews,
              backgroundColor: theme.colorScheme.error,
              label: Text('$newsCount'),
              child: const Icon(Icons.insights_rounded),
            ),
            label: l.navProgress,
          ),
          NavigationDestination(
            icon: const Icon(Icons.message_rounded),
            label: l.navMessages,
          ),
          NavigationDestination(
            icon: const Icon(Icons.assignment_turned_in_rounded),
            label: l.navTasks,
          ),
        ],
      ),
    );
  }

  /// Show the calm "something new about your child" popups (achievements
  /// first, then a logged feeling), then mark everything shown as seen so it
  /// (and the red count) clears.
  Future<void> _announceNews() async {
    if (!mounted) return;
    final child = ref.read(activeStudentProvider).value;
    final me = ref.read(currentUserDocProvider).value;
    final badges = ref.read(parentUnseenBadgesProvider);
    final level = ref.read(parentUnseenLevelProvider);
    final journal = ref.read(parentUnseenJournalProvider);
    if (child == null ||
        me == null ||
        (badges.isEmpty && level == null && journal.isEmpty)) {
      _announcing = false;
      return;
    }

    if (badges.isNotEmpty || level != null) {
      await showDialog<void>(
        context: context,
        builder:
            (_) => _NewAchievementsDialog(
              childName: child.name,
              badgeIds: badges,
              newLevel: level,
            ),
      );
    }
    if (!mounted) {
      _announcing = false;
      return;
    }
    if (journal.isNotEmpty) {
      await showDialog<void>(
        context: context,
        builder:
            (_) => _NewJournalDialog(childName: child.name, entries: journal),
      );
    }
    if (!mounted) {
      _announcing = false;
      return;
    }

    try {
      await ref
          .read(userRepositoryProvider)
          .upsert(
            me.copyWith(
              seenBadgeCounts: {
                ...me.seenBadgeCounts,
                child.id: child.badges.length,
              },
              seenLevelCounts: {...me.seenLevelCounts, child.id: child.level},
              seenJournalCounts: {
                ...me.seenJournalCounts,
                child.id:
                    (me.seenJournalCounts[child.id] ?? 0) + journal.length,
              },
            ),
          );
    } catch (_) {
      // Best-effort: if the write fails the popup simply shows again later.
    }
    _announcing = false;
  }
}

/// The parent-facing celebration popup: any new badge(s) their child just
/// earned and/or a new personal level they just reached, shown warmly with
/// the child's name. One "Lovely!" button dismisses and acknowledges both.
/// Any badge ids not in the taxonomy are quietly skipped.
class _NewAchievementsDialog extends StatelessWidget {
  const _NewAchievementsDialog({
    required this.childName,
    required this.badgeIds,
    required this.newLevel,
  });

  final String childName;
  final List<String> badgeIds;
  final int? newLevel;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final badges = [
      for (final id in badgeIds)
        if (rewardBadgeById(id) != null) rewardBadgeById(id)!,
    ];
    final level = newLevel;

    return AlertDialog(
      icon: Icon(
        Icons.emoji_events_rounded,
        size: 48,
        color: theme.colorScheme.primary,
      ),
      title: Text(
        badges.isEmpty
            ? l.parentNewLevelTitle(childName)
            : level != null
            ? l.parentNewAchievementTitle(childName)
            : l.parentNewBadgeTitle(childName, badges.length),
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (level != null) ...[
            Icon(
              Icons.military_tech_rounded,
              size: 40,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l.parentNewLevelCaption,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              rewardLevelTitle(level, l),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (badges.isNotEmpty) const SizedBox(height: AppSpacing.lg),
          ],
          if (badges.isNotEmpty)
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpacing.lg,
              runSpacing: AppSpacing.md,
              children: [
                for (final badge in badges)
                  SizedBox(
                    width: 96,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: badge.color.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: badge.color.withValues(alpha: 0.6),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.emoji_events_rounded,
                            size: 34,
                            color: badge.color,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          rewardBadgeLabel(badge, l),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelLarge,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.parentNewBadgeDismiss),
        ),
      ],
      actionsAlignment: MainAxisAlignment.center,
    );
  }
}

/// The parent-facing "your child logged a feeling" popup (FR12/FR9-lite).
/// Shows the most recent entry's icon and any note; when more than one entry
/// arrived since the parent last checked, a small caption names how many more.
class _NewJournalDialog extends StatelessWidget {
  const _NewJournalDialog({required this.childName, required this.entries});

  final String childName;
  final List<JournalEntry> entries;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final latest = entries.first;
    final color = kEmotionColor[latest.emotionIcon]!;
    final extra = entries.length - 1;

    return AlertDialog(
      icon: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.18),
          shape: BoxShape.circle,
        ),
        child: Icon(kEmotionIcon[latest.emotionIcon], size: 40, color: color),
      ),
      title: Text(
        l.parentNewJournalTitle(childName),
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            emotionLabel(latest.emotionIcon, l),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (latest.note != null && latest.note!.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              latest.note!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
          if (extra > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              l.parentNewJournalExtra(extra),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.parentNewBadgeDismiss),
        ),
      ],
      actionsAlignment: MainAxisAlignment.center,
    );
  }
}
