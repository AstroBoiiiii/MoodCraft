import 'package:flutter/material.dart';
import 'package:moodcraft/l10n/app_localizations.dart';

import '../../app/theme/tokens.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/enums.dart';

/// The activities a teacher can set as homework. AR is left out on purpose: it
/// records no session yet, so there is nothing to auto-complete against (the
/// same reason it has no reward badge). Add it here the day AR writes sessions.
const List<ActivityType> kAssignableActivities = [
  ActivityType.story,
  ActivityType.mixmatch,
  ActivityType.quiz,
  ActivityType.companion,
];

/// Icon for an activity — matches the student home tiles and reward badges so a
/// task reads the same everywhere.
IconData activityIcon(ActivityType activity) => switch (activity) {
  ActivityType.story => Icons.menu_book_rounded,
  ActivityType.mixmatch => Icons.extension_rounded,
  ActivityType.quiz => Icons.emoji_objects_rounded,
  ActivityType.companion => Icons.chat_bubble_rounded,
  ActivityType.ar => Icons.view_in_ar_rounded,
};

/// Accent colour key for an activity (feeds [activityAccent]).
String activityAccentKey(ActivityType activity) => switch (activity) {
  ActivityType.story => 'story',
  ActivityType.mixmatch => 'mixmatch',
  ActivityType.quiz => 'quiz',
  ActivityType.companion => 'companion',
  ActivityType.ar => 'ar',
};

/// The student home route that launches an activity — where the child's "to do"
/// card sends them.
String activityRoute(ActivityType activity) => switch (activity) {
  ActivityType.story => '/student/story',
  ActivityType.mixmatch => '/student/mixmatch',
  ActivityType.quiz => '/student/quiz',
  ActivityType.companion => '/student/companion',
  ActivityType.ar => '/student/ar',
};

/// Localised activity name, reusing the nav labels so wording stays consistent.
String activityLabel(ActivityType activity, AppLocalizations l) =>
    switch (activity) {
      ActivityType.story => l.navStories,
      ActivityType.mixmatch => l.navMatch,
      ActivityType.quiz => l.navQuiz,
      ActivityType.companion => l.navCompanion,
      ActivityType.ar => l.navAr,
    };

/// A small pill showing one task activity: its icon and name, tinted with the
/// activity accent. With [done] set it reads as completed (a soft tick, filled
/// tint); otherwise it is a calm outline — never a red "not done" (design
/// principle 1).
class ActivityChip extends StatelessWidget {
  const ActivityChip({required this.activity, this.done, super.key});

  final ActivityType activity;

  /// null = neutral (no completion shown), true/false = done state.
  final bool? done;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final accent = activityAccent(activityAccentKey(activity));
    final isDone = done == true;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: isDone ? 0.18 : 0.08),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: accent.withValues(alpha: isDone ? 0.6 : 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            done == null
                ? activityIcon(activity)
                : (isDone
                    ? Icons.check_circle_rounded
                    : activityIcon(activity)),
            size: 18,
            color: accent,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            activityLabel(activity, l),
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: isDone ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
