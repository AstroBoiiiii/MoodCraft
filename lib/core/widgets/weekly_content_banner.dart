import 'package:flutter/material.dart';
import 'package:moodcraft/l10n/app_localizations.dart';

import '../../app/theme/tokens.dart';
import '../utils/content_week.dart';

/// Shared "this week's content" framing for every weekly-rotating activity (AR,
/// Quiz, Story, Mix-and-Match — FR3's companion is the one activity left out,
/// since it teaches live rather than from a fixed set). A calm chip names the
/// current content week, and "Past weeks" opens [showPastWeeksSheet] so the
/// idea of weekly-updating content is visible even before any past week
/// exists. Purely a framing layer: it changes no gameplay, only shows it.
class WeeklyContentBanner extends StatelessWidget {
  const WeeklyContentBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Chip(
              avatar: Icon(
                Icons.calendar_today_rounded,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              label: Text(l.weeklyContentThisWeek),
              visualDensity: VisualDensity.compact,
            ),
          ),
          TextButton.icon(
            onPressed: () => showPastWeeksSheet(context),
            icon: const Icon(Icons.history_rounded, size: 18),
            label: Text(l.weeklyContentPastWeeks),
          ),
        ],
      ),
    );
  }
}

/// A compact icon-only trigger for [showPastWeeksSheet], for chrome that has no
/// room for the full [WeeklyContentBanner] row (e.g. an `AppBar` action on a
/// full-screen activity like AR).
class PastWeeksAction extends StatelessWidget {
  const PastWeeksAction({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return IconButton(
      tooltip: l.weeklyContentPastWeeks,
      icon: const Icon(Icons.history_rounded),
      onPressed: () => showPastWeeksSheet(context),
    );
  }
}

/// The calm "past weeks" sheet. Lists content weeks before the current one,
/// newest first; today that list is always empty (the current week is always
/// week 0's content on a fresh install), so it shows a gentle "nothing yet,
/// check back soon" note rather than an empty-feeling blank list.
void showPastWeeksSheet(BuildContext context) {
  final currentWeek = currentContentWeekIndex();
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => _PastWeeksSheet(currentWeek: currentWeek),
  );
}

class _PastWeeksSheet extends StatelessWidget {
  const _PastWeeksSheet({required this.currentWeek});

  final int currentWeek;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.weeklyContentPastWeeks,
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (currentWeek <= 0) ...[
            Icon(
              Icons.auto_awesome_rounded,
              size: 48,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l.weeklyContentNoneYetTitle,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l.weeklyContentNoneYetBody,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ] else
            for (var week = currentWeek - 1; week >= 0; week--)
              ListTile(
                leading: const Icon(Icons.calendar_view_week_rounded),
                title: Text(l.weeklyContentWeekLabel(week + 1)),
              ),
        ],
      ),
    );
  }
}
