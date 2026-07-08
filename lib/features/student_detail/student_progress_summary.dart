import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moodcraft/l10n/app_localizations.dart';

import '../../app/theme/tokens.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/enums.dart';
import '../../core/models/session.dart';
import '../../core/models/student.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/widgets/section_card.dart';

/// The child's most recent activity runs, newest first, for the progress card.
final _recentSessionsProvider = StreamProvider.autoDispose
    .family<List<Session>, String>((ref, studentId) {
      return ref.watch(sessionRepositoryProvider).watchForStudent(studentId);
    });

/// FR8/FR11 — a calm, read-only snapshot of a child's progress, shown to the
/// teacher and the parent on the shared detail Overview (both render
/// [StudentDetailTabs]). It surfaces exactly what the rewards model records:
/// stars and badges earned, which of the five feelings the child has practiced,
/// and the last few activities. It is a summary, not the full FR8 analytics
/// (trends, difficulty areas) — those come in a later pass.
class StudentProgressSummary extends ConsumerWidget {
  const StudentProgressSummary({required this.student, super.key});

  final Student student;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final earned = student.badges.toSet();
    final badgeCount = kRewardBadges.where((b) => earned.contains(b.id)).length;
    // Which of the five feelings the child has met, read straight from their
    // sessions (not a badge) so it stays an honest teacher/parent insight even
    // now that rewards are about finishing activities rather than feelings.
    final sessionsAsync = ref.watch(_recentSessionsProvider(student.id));
    final practiced = <Emotion>{
      for (final s in sessionsAsync.value ?? const <Session>[])
        ...s.emotionsShown,
    };

    return SectionCard(
      title: l.progressTitle,
      icon: Icons.insights_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _Stat(
                  icon: Icons.star_rounded,
                  color: const Color(0xFFE3B23C),
                  value: '${student.stars}',
                  caption: l.progressStarsCaption,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _Stat(
                  icon: Icons.workspace_premium_rounded,
                  color: theme.colorScheme.primary,
                  value: '$badgeCount/${kRewardBadges.length}',
                  caption: l.progressBadgesCaption,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(l.progressFeelingsTitle, style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          _FeelingsRow(practiced: practiced),
          const SizedBox(height: AppSpacing.lg),
          Text(l.progressRecentTitle, style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          sessionsAsync.when(
            loading:
                () => const Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
            error: (_, __) => _emptyRecent(context, l),
            data: (sessions) {
              if (sessions.isEmpty) return _emptyRecent(context, l);
              return Column(
                children: [
                  for (final s in sessions.take(4)) _RecentRow(session: s),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _emptyRecent(BuildContext context, AppLocalizations l) {
    final theme = Theme.of(context);
    return Text(
      l.progressNoActivity,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// One stat tile: a coloured icon, a big value and a small caption.
class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.color,
    required this.value,
    required this.caption,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Row(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              Text(
                caption,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The five feelings, each drawn in its colour once the child has met it in an
/// activity (it turned up in one of their sessions) and greyed until then — a
/// quick read of coverage.
class _FeelingsRow extends StatelessWidget {
  const _FeelingsRow({required this.practiced});

  final Set<Emotion> practiced;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Row(
      children: [
        for (final feeling in kRewardFeelings)
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: Builder(
              builder: (context) {
                final on = practiced.contains(feeling);
                final color = on ? kEmotionColor[feeling]! : muted;
                return Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: on ? 0.18 : 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(kEmotionIcon[feeling], size: 24, color: color),
                );
              },
            ),
          ),
      ],
    );
  }
}

/// One recent activity: its icon and name, with the date it happened.
class _RecentRow extends StatelessWidget {
  const _RecentRow({required this.session});

  final Session session;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final accent = activityAccent(session.activityType.name);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _activityIcon(session.activityType),
              size: 20,
              color: accent,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              _activityLabel(session.activityType, l),
              style: theme.textTheme.bodyLarge,
            ),
          ),
          Text(
            MaterialLocalizations.of(
              context,
            ).formatMediumDate(session.timestamp),
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

IconData _activityIcon(ActivityType t) => switch (t) {
  ActivityType.story => Icons.menu_book_rounded,
  ActivityType.mixmatch => Icons.extension_rounded,
  ActivityType.quiz => Icons.emoji_objects_rounded,
  ActivityType.companion => Icons.chat_bubble_rounded,
  ActivityType.ar => Icons.view_in_ar_rounded,
};

String _activityLabel(ActivityType t, AppLocalizations l) => switch (t) {
  ActivityType.story => l.navStories,
  ActivityType.mixmatch => l.navMatch,
  ActivityType.quiz => l.navQuiz,
  ActivityType.companion => l.navCompanion,
  ActivityType.ar => l.navAr,
};
