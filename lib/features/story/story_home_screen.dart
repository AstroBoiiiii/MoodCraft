import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moodcraft/l10n/app_localizations.dart';

import '../../app/theme/tokens.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/story_progress.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/widgets/calm_scaffold.dart';
import '../../core/widgets/sensory_settings_sheet.dart';
import '../../core/widgets/weekly_content_banner.dart';
import 'story_data.dart';

/// FR5 — the student's story picker. Three stories, each a little series of
/// episodes that continue one plot: finishing an episode gently opens the next,
/// while every story is always available. Progress refreshes live via
/// [activeStudentProvider], and play resumes where the child left off.
class StoryHomeScreen extends ConsumerWidget {
  const StoryHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final student = ref.watch(activeStudentProvider).value;
    return CalmScaffold(
      title: l.navStories,
      icon: Icons.menu_book_rounded,
      actions: accountActions(context, ref),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            children: [
              Text(l.storyIntro, style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.md),
              StoryPicker(
                progressFor:
                    (storyId) =>
                        student?.storyProgress[storyId] ??
                        const StoryProgress(),
                onPick:
                    (storyId, level) => context.push(
                      '/student/story/play',
                      extra: (
                        studentId: student?.id,
                        storyId: storyId,
                        level: level,
                      ),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The shared story/episode picker: one card per story with its episode chips.
/// With [progressFor] (student mode) episodes unlock in order — done episodes
/// show a check and stay replayable, the next one is open, later ones wait
/// quietly. Without it (teacher classroom mode) every episode is open and no
/// progress is shown. Used by the student entry screen and the teacher's
/// classroom launcher.
class StoryPicker extends StatelessWidget {
  const StoryPicker({required this.onPick, this.progressFor, super.key});

  /// Called with the tapped story id and episode index (0-based).
  final void Function(String storyId, int level) onPick;

  /// The saved progress for a story id; null opens every episode (classroom).
  final StoryProgress Function(String storyId)? progressFor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = activityAccent('story');
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const WeeklyContentBanner(),
        for (final story in kStoryCatalog) ...[
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(
                color: accent.withValues(alpha: 0.35),
                width: 1.5,
              ),
            ),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.auto_stories_rounded,
                        size: 24,
                        color: accent,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(story.title, style: theme.textTheme.titleMedium),
                          Text(
                            formatStoryDuration(storyTotalDurationMs(story)),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (progressFor != null &&
                        progressFor!(story.id).levelsDone >=
                            story.episodes.length)
                      Icon(Icons.check_circle_rounded, size: 20, color: accent),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                // IntrinsicHeight bounds the stretch: without it this Row
                // inherits the ListView's infinite height and the stretch
                // blows up layout (blank screen wherever the picker embeds).
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < story.episodes.length; i++) ...[
                        if (i > 0) const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _EpisodeChip(
                            label: AppLocalizations.of(
                              context,
                            ).storyEpisode(i + 1),
                            duration: formatStoryDuration(
                              storyEpisodeDurationMs(story.episodes[i]),
                            ),
                            state: _stateFor(story, i),
                            accent: accent,
                            onTap: () => onPick(story.id, i),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }

  _EpisodeState _stateFor(StoryInfo story, int level) {
    final progress = progressFor?.call(story.id);
    if (progress == null) return _EpisodeState.open; // classroom: all open
    if (level < progress.levelsDone) return _EpisodeState.done;
    if (level == progress.levelsDone) return _EpisodeState.open;
    return _EpisodeState.waiting;
  }
}

enum _EpisodeState { done, open, waiting }

/// One episode chip. Done = check (replayable), open = play, waiting = quietly
/// faded and untappable until the episode before it is finished — no harsh lock
/// visuals, it simply is not ready yet.
class _EpisodeChip extends StatelessWidget {
  const _EpisodeChip({
    required this.label,
    required this.duration,
    required this.state,
    required this.accent,
    required this.onTap,
  });

  final String label;

  /// This episode's own shown length ("m:ss"), e.g. "0:53" — its segment of
  /// the film, never the whole raw video's length.
  final String duration;
  final _EpisodeState state;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final waiting = state == _EpisodeState.waiting;
    final icon = switch (state) {
      _EpisodeState.done => Icons.check_circle_rounded,
      _EpisodeState.open => Icons.play_arrow_rounded,
      _EpisodeState.waiting => Icons.more_horiz_rounded,
    };
    // Paint the border with a real Container (an `Ink` inside a ListView can
    // skip painting its decoration on the first frame until a scroll forces a
    // repaint), and keep the tap ripple via a transparent Material layer.
    return Opacity(
      opacity: waiting ? 0.45 : 1,
      child: Container(
        decoration: BoxDecoration(
          color: accent.withValues(
            alpha: state == _EpisodeState.open ? 0.14 : 0.06,
          ),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: accent.withValues(alpha: 0.35)),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: waiting ? null : onTap,
            borderRadius: BorderRadius.circular(AppRadii.md),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.sm,
                horizontal: AppSpacing.xs,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 22, color: accent),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge,
                  ),
                  Text(
                    duration,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
