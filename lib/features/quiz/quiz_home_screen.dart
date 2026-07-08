import 'package:flutter/material.dart';
import 'package:moodcraft/l10n/app_localizations.dart';

import '../../app/theme/tokens.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/weekly_content_banner.dart';

/// Which daily quiz set a [date] maps to (0..[kQuizSetCount]). Uses the real
/// calendar day so the quiz rotates day to day; three consecutive days (today /
/// yesterday / day before) always map to the three different sets. UTC-normalised
/// so it behaves the same on web (Chrome) and mobile, free of DST drift.
int quizSetIndexForDate(DateTime date) {
  final day = DateTime.utc(date.year, date.month, date.day);
  final days = day.difference(DateTime.utc(2000, 1, 1)).inDays;
  return ((days % kQuizSetCount) + kQuizSetCount) % kQuizSetCount;
}

/// A short, locale-free date label like "Mon 29 Jun" (English-only for now,
/// matching the rest of the app; no `intl` locale data needed so it works
/// identically on web and mobile).
String quizShortDate(DateTime d) {
  const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', //
  ];
  return '${weekdays[d.weekday - 1]} ${d.day} ${months[d.month - 1]}';
}

/// The quiz's day picker: Today / Yesterday / Day before, each showing its real
/// date (fetched live from the device clock) and launching that day's set. Used
/// by the student entry screen and the teacher's classroom launcher.
class QuizDayPicker extends StatelessWidget {
  const QuizDayPicker({required this.onPick, this.progressFor, super.key});

  /// Called with the daily set index for the tapped day.
  final void Function(int setIndex) onPick;

  /// Answered count (0..[kQuizRoundSize]) for a day's set index, shown as "X/5";
  /// null hides it (e.g. the teacher's classroom launcher, which keeps no
  /// per-child progress).
  final int Function(int setIndex)? progressFor;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = <(String, DateTime)>[
      (l.quizToday, today),
      (l.quizYesterday, today.subtract(const Duration(days: 1))),
      (l.quizDayBefore, today.subtract(const Duration(days: 2))),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const WeeklyContentBanner(),
        for (final (label, date) in days) ...[
          _DayCard(
            label: label,
            date: quizShortDate(date),
            progress: progressFor?.call(quizSetIndexForDate(date)),
            onTap: () => onPick(quizSetIndexForDate(date)),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.label,
    required this.date,
    required this.onTap,
    this.progress,
  });

  final String label;
  final String date;
  final VoidCallback onTap;

  /// Questions done in this day's round (0..[kQuizRoundSize]); null hides it.
  final int? progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = activityAccent('quiz');
    final done = progress != null && progress! >= kQuizRoundSize;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: Ink(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: accent.withValues(alpha: 0.35), width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.calendar_today_rounded,
                  size: 26,
                  color: accent,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: theme.textTheme.titleMedium),
                    Text(
                      date,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (progress != null) ...[
                if (done)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: Icon(
                      Icons.check_circle_rounded,
                      size: 18,
                      color: accent,
                    ),
                  ),
                Text(
                  '$progress/$kQuizRoundSize',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Icon(Icons.play_arrow_rounded, color: accent),
            ],
          ),
        ),
      ),
    );
  }
}
