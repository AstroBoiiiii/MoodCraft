import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moodcraft/l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';

import '../../app/theme/tokens.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/enums.dart';
import '../../core/models/session.dart';
import '../../core/models/story_progress.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/providers/sensory_settings_provider.dart';
import '../../core/services/rewards_service.dart';
import '../../core/widgets/calm_scaffold.dart';
import '../../core/widgets/reward_celebration.dart';
import '../journal/journal_section.dart' show emotionLabel;
import 'story_data.dart';

/// Arguments for the story play route: the student id ([studentId] null =
/// teacher classroom mode, no record), which story and which episode (0-based).
typedef StoryPlayArgs = ({String? studentId, String storyId, int level});

/// FR5 — one story episode, laid out like a familiar video page on web and
/// mobile alike: the film sits in its own contained frame with calm controls
/// underneath (play/pause and a non-scrubbable progress line). Tapping the film
/// itself also toggles play/pause. The film never autoplays — the child taps
/// play. No full-screen mode: the contained page stays clean and predictable.
///
/// At each configured emotional moment the film pauses and asks its question
/// quiz-style beneath the film: the pause's own `ask` line (naming who to think
/// about), three feeling choices, a short friendly feedback line on a right tap
/// (read, not narrated — story mode has no TTS), a calm "look again" on a wrong
/// one. No timer, no score. The question is never painted *over* the video —
/// on web the video is a real browser element layered above the Flutter
/// canvas, and overlays drawn onto it can come out blank white.
///
/// Progress has full parity with the quiz: each answered pause is saved the
/// instant it is given (episode + pause point on `Student.storyProgress`), so
/// play resumes exactly where the child left off, and finishing the episode
/// opens the next one and writes a [Session]. Replaying an already-finished
/// episode never regresses progress. [studentId] null = teacher classroom mode:
/// nothing is recorded.
class StoryPlayScreen extends ConsumerStatefulWidget {
  const StoryPlayScreen({
    required this.studentId,
    required this.storyId,
    required this.level,
    super.key,
  });

  final String? studentId;
  final String storyId;
  final int level;

  @override
  ConsumerState<StoryPlayScreen> createState() => _StoryPlayScreenState();
}

class _StoryPlayScreenState extends ConsumerState<StoryPlayScreen> {
  StoryInfo? _story;
  StoryEpisode? _episode;
  VideoPlayerController? _controller;
  bool _ready = false;
  bool _failed = false;

  /// Whether this run is the story's frontier episode (the next unfinished
  /// one), i.e. the run that advances saved progress. Replays and classroom
  /// mode leave progress untouched.
  bool _frontier = false;

  int _level = 0;

  /// Where this run is meant to open in the film (the episode's segment start,
  /// or the saved resume point). Kept so playback can be snapped back here if a
  /// cold, unbuffered first load lets the film start from 0:00 instead.
  int _segmentStartMs = 0;

  /// True once real playback has genuinely moved past [_segmentStartMs]. Until
  /// then the start guard in [_onTick] watches for a dropped opening seek; after
  /// then it never fires again, so it can't disturb the pause moments.
  bool _startReached = false;

  int _pausesDone = 0;
  bool _inQuestion = false;
  bool _answered = false; // current pause answered right -> feedback showing
  bool _missedCurrent = false;
  int _retries = 0; // wrong taps (telemetry only, never shown to the child)
  int _firstTryCorrect = 0;
  bool _finished = false;
  bool _sessionSaved = false;
  RewardOutcome? _outcome; // stars/badges just earned, shown on the done screen
  DateTime _startedAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    _level = widget.level;
    _story = storyById(widget.storyId);
    _episode = _episodeForLevel(_level);
    _load();
  }

  StoryEpisode? _episodeForLevel(int level) {
    final episodes = _story?.episodes ?? const [];
    return (level >= 0 && level < episodes.length) ? episodes[level] : null;
  }

  bool get _hasNextEpisode {
    final episodes = _story?.episodes ?? const [];
    return _level + 1 < episodes.length;
  }

  void _goNextEpisode() {
    _controller?.removeListener(_onTick);
    _controller?.dispose();
    setState(() {
      _level++;
      _episode = _episodeForLevel(_level);
      _controller = null;
      _ready = false;
      _failed = false;
      _frontier = false;
      _pausesDone = 0;
      _inQuestion = false;
      _answered = false;
      _missedCurrent = false;
      _retries = 0;
      _firstTryCorrect = 0;
      _finished = false;
      _sessionSaved = false;
      _outcome = null;
      _startedAt = DateTime.now();
    });
    _load();
  }

  @override
  void dispose() {
    _controller?.removeListener(_onTick);
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final episode = _episode;
    if (episode == null) {
      setState(() => _failed = true);
      return;
    }

    // Resume the exact pause point the child left mid-episode, but only on the
    // frontier episode — a replay of a finished episode always starts fresh.
    var resumeMs = 0;
    final studentId = widget.studentId;
    if (studentId != null) {
      try {
        final student = await ref
            .read(studentRepositoryProvider)
            .getStudent(studentId);
        final progress =
            student?.storyProgress[widget.storyId] ?? const StoryProgress();
        _frontier = _level == progress.levelsDone;
        if (_frontier) {
          _pausesDone = progress.pausesDone.clamp(0, episode.pauses.length);
          resumeMs = progress.positionMs;
        }
      } catch (_) {
        // Couldn't read saved progress — just start fresh below.
      }
    }

    final controller = VideoPlayerController.asset(episode.videoAsset);
    try {
      await controller.initialize();
    } catch (_) {
      controller.dispose();
      if (mounted) setState(() => _failed = true);
      return;
    }
    if (!mounted) {
      controller.dispose();
      return;
    }
    await controller.setVolume(ref.read(sensorySettingsProvider).masterVolume);
    // Open on the episode's segment start, or the exact saved pause point when
    // resuming further in (all timestamps are absolute in the film).
    final seekMs = resumeMs > episode.startMs ? resumeMs : episode.startMs;
    _segmentStartMs = seekMs;
    _startReached = seekMs <= 0;
    if (seekMs > 0) {
      final target = Duration(milliseconds: seekMs);
      await controller.seekTo(target);
      // On web (and any cold, unbuffered asset) seekTo resolves before the
      // underlying <video> element has actually moved, so a play() right after
      // would start from 0:00 and drop the seek. A large, never-before-loaded
      // file can take several seconds to buffer far enough for the browser to
      // honour a seek that far in, so keep re-issuing the seek and waiting for
      // the reported position to land on the target before playing (a later
      // replay, once the asset is cached, lands almost immediately).
      for (var i = 0; i < 80 && mounted; i++) {
        if (controller.value.position >=
            target - const Duration(milliseconds: 200)) {
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await controller.seekTo(target);
      }
      if (!mounted) {
        controller.dispose();
        return;
      }
    }
    controller.addListener(_onTick);
    setState(() {
      _controller = controller;
      _ready = true;
      _startedAt = DateTime.now();
    });
    await controller.play();
  }

  /// Playback watcher: pauses the video the moment it reaches the next unasked
  /// pause moment, and spots the end of the episode's segment.
  void _onTick() {
    final controller = _controller;
    final episode = _episode;
    if (controller == null || episode == null) return;
    final v = controller.value;
    if (!v.isInitialized) return;

    // Cold-load start guard: on the very first, unbuffered play the opening
    // seek can be dropped and the film begins from 0:00. Watch the *real*
    // reported playback (not the optimistic post-seek value) and snap it back
    // to where this episode should begin. Once playback has truly moved past
    // that point, disarm the guard so it can never touch the pause moments,
    // which all sit further into the film.
    if (!_startReached) {
      final posMs = v.position.inMilliseconds;
      if (posMs > _segmentStartMs + 150) {
        _startReached = true;
      } else if (v.isPlaying && posMs < _segmentStartMs - 300) {
        controller.seekTo(Duration(milliseconds: _segmentStartMs));
        return;
      }
    }

    if (!_inQuestion &&
        !_finished &&
        _pausesDone < episode.pauses.length &&
        v.position.inMilliseconds >= episode.pauses[_pausesDone].atMs) {
      controller.pause();
      setState(() {
        _inQuestion = true;
        _answered = false;
        _missedCurrent = false;
      });
      return;
    }

    // The episode is over at its configured segment end, or at the natural end
    // of the film for the last stretch.
    final endMs = episode.endMs;
    final segmentOver =
        endMs != null
            ? v.position.inMilliseconds >= endMs
            : v.duration > Duration.zero &&
                v.position >= v.duration &&
                !v.isPlaying;
    if (!_finished && !_inQuestion && segmentOver) {
      controller.pause();
      _finish();
    }
  }

  void _togglePlay() {
    final controller = _controller;
    if (controller == null || _inQuestion) return;
    if (controller.value.isPlaying) {
      controller.pause();
      return;
    }
    // First play after a cold load (autoplay is blocked on web, so the child's
    // tap is the real first play): make sure we roll from the episode's start,
    // not 0:00, if the opening seek hadn't taken yet.
    if (!_startReached &&
        controller.value.position.inMilliseconds < _segmentStartMs - 300) {
      controller.seekTo(Duration(milliseconds: _segmentStartMs));
    }
    controller.play();
  }

  void _onAnswer(StoryPause pause, Emotion pick) {
    if (_answered) return;
    if (pick == pause.answer) {
      if (!_missedCurrent) _firstTryCorrect++;
      setState(() => _answered = true);
      // Mark this pause answered right away, so a quit during the feedback
      // resumes after this pause, not by re-answering it.
      _saveProgress(pausesDone: _pausesDone + 1, positionMs: pause.atMs);
    } else {
      // Gentle, no-penalty redirect: stay on the question for another try.
      setState(() {
        _retries++;
        _missedCurrent = true;
      });
    }
  }

  /// Hides the question and lets the film carry on.
  void _continueStory() {
    setState(() {
      _pausesDone++;
      _inQuestion = false;
      _answered = false;
      _missedCurrent = false;
    });
    _controller?.play();
  }

  /// Saves the exact pause point on the frontier episode. Best-effort: a failed
  /// write just syncs later via the cache (FR14).
  Future<void> _saveProgress({
    required int pausesDone,
    required int positionMs,
    bool episodeDone = false,
  }) async {
    final studentId = widget.studentId;
    if (studentId == null || !_frontier) return;
    final repo = ref.read(studentRepositoryProvider);
    try {
      final student = await repo.getStudent(studentId);
      if (student == null) return;
      final updated = Map<String, StoryProgress>.from(student.storyProgress)
        ..[widget.storyId] = StoryProgress(
          levelsDone: episodeDone ? _level + 1 : _level,
          pausesDone: episodeDone ? 0 : pausesDone,
          positionMs: episodeDone ? 0 : positionMs,
        );
      await repo.upsert(student.copyWith(storyProgress: updated));
    } catch (_) {
      // Ignore — saving progress is a nicety, never blocks play.
    }
  }

  /// Episode finished: open the next one (frontier only) and record the session
  /// for the teacher dashboard (FR8). Student mode only.
  Future<void> _finish() async {
    if (_finished) return;
    setState(() => _finished = true);
    // Save the episode-done progress first, then award, so the two writes to the
    // student (storyProgress vs stars/badges) never clobber each other.
    await _saveProgress(pausesDone: 0, positionMs: 0, episodeDone: true);
    if (_sessionSaved || widget.studentId == null) return;
    _sessionSaved = true;
    final pauses = _episode?.pauses ?? const <StoryPause>[];
    final session = Session(
      id: const Uuid().v4(),
      studentId: widget.studentId!,
      activityType: ActivityType.story,
      emotionsShown: pauses.map((p) => p.answer).toList(),
      responses: pauses.map((p) => p.answer.name).toList(),
      correctCount: _firstTryCorrect,
      retries: _retries,
      durationMs: DateTime.now().difference(_startedAt).inMilliseconds,
      timestamp: DateTime.now(),
    );
    try {
      await ref.read(sessionRepositoryProvider).add(session);
    } catch (_) {
      // Offline/transient — Firestore cache will sync later (FR14).
    }
    // Grant participation stars + any new badges (FR11) and reveal them on the
    // end-of-episode screen. Best-effort: a failed award just shows "the end".
    final outcome = await ref
        .read(rewardsServiceProvider)
        .awardForSession(
          studentId: widget.studentId!,
          activity: ActivityType.story,
          emotionsShown: pauses.map((p) => p.answer).toList(),
        );
    if (mounted) setState(() => _outcome = outcome);
  }

  StoryPause? get _currentPause {
    final pauses = _episode?.pauses ?? const <StoryPause>[];
    return _pausesDone < pauses.length ? pauses[_pausesDone] : null;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final title = _story?.title ?? l.navStories;

    if (_failed) {
      return CalmScaffold(
        title: title,
        icon: Icons.menu_book_rounded,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text(
              l.storyVideoUnavailable,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
      );
    }
    if (_finished) {
      return CalmScaffold(
        title: title,
        icon: Icons.menu_book_rounded,
        body: RewardCelebration(
          outcome: _outcome,
          title: l.storyDone,
          body: l.storyDoneBody,
          doneLabel: l.storyDoneButton,
          onDone: () => context.pop(),
          secondaryLabel: _hasNextEpisode ? l.storyNextEpisode : null,
          onSecondary: _hasNextEpisode ? _goNextEpisode : null,
        ),
      );
    }
    if (!_ready) {
      return CalmScaffold(
        title: title,
        icon: Icons.menu_book_rounded,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final pause = _currentPause;
    return CalmScaffold(
      title: title,
      icon: Icons.menu_book_rounded,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: ListView(
            children: [
              _videoFrame(context),
              const SizedBox(height: AppSpacing.sm),
              _controlsRow(context),
              const SizedBox(height: AppSpacing.md),
              if (_inQuestion && pause != null)
                _PauseQuestion(
                  pause: pause,
                  options: storyOptionsFor(
                    widget.storyId,
                    _level,
                    _pausesDone,
                    pause.answer,
                  ),
                  answered: _answered,
                  missed: _missedCurrent,
                  onPick: (e) => _onAnswer(pause, e),
                  onContinue: _continueStory,
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// The film in a rounded frame at its own aspect ratio, with one big calm
  /// play button while it waits. A transparent Flutter tap layer sits above the
  /// video, so tapping the film to play or pause always works — on web the
  /// video itself is a browser element that can swallow taps.
  Widget _videoFrame(BuildContext context) {
    final theme = Theme.of(context);
    final controller = _controller!;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: ValueListenableBuilder<VideoPlayerValue>(
        valueListenable: controller,
        builder: (context, value, _) {
          return AspectRatio(
            aspectRatio: value.aspectRatio > 0 ? value.aspectRatio : 16 / 9,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // The frame already matches the film's aspect ratio, so the
                // video simply fills it.
                SizedBox.expand(child: VideoPlayer(controller)),
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _togglePlay,
                  ),
                ),
                // One big, calm play button when the film is waiting. It only
                // signposts the tap layer underneath, so taps pass through.
                if (!value.isPlaying && !_inQuestion)
                  IgnorePointer(
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface.withValues(
                          alpha: 0.85,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.play_arrow_rounded,
                        size: 56,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Calm control strip under the film: play/pause and the episode's progress
  /// line (non-scrubbable, so the film can never skip past a feelings moment).
  /// The controls live *beside* the video, never over it, so they always work
  /// on web where the video is a browser element.
  Widget _controlsRow(BuildContext context) {
    final theme = Theme.of(context);
    final controller = _controller!;
    final episode = _episode!;
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final endMs = episode.endMs ?? value.duration.inMilliseconds;
        final span = endMs - episode.startMs;
        final played = value.position.inMilliseconds - episode.startMs;
        return Row(
          children: [
            IconButton.filledTonal(
              onPressed: _inQuestion ? null : _togglePlay,
              icon: Icon(
                value.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: LinearProgressIndicator(
                minHeight: 6,
                borderRadius: BorderRadius.circular(AppRadii.pill),
                value: span > 0 ? (played / span).clamp(0.0, 1.0) : 0.0,
                color: activityAccent('story'),
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// The quiz-style question shown beneath the paused film: the pause's own ask
/// line (naming who to think about), three feeling choices, then a short
/// friendly feedback line with Continue. A wrong tap shows a gentle "look
/// again" and stays on the question.
class _PauseQuestion extends StatelessWidget {
  const _PauseQuestion({
    required this.pause,
    required this.options,
    required this.answered,
    required this.missed,
    required this.onPick,
    required this.onContinue,
  });

  final StoryPause pause;
  final List<Emotion> options;
  final bool answered;
  final bool missed;
  final ValueChanged<Emotion> onPick;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    if (answered) {
      return _PauseFeedback(pause: pause, onContinue: onContinue);
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          pause.ask,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall,
        ),
        if (missed) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            l.storyTryAgain,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            for (var i = 0; i < options.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _FeelingTile(
                  emotion: options[i],
                  onTap: () => onPick(options[i]),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// One large feeling choice — icon plus label, like the quiz's tiles.
class _FeelingTile extends StatelessWidget {
  const _FeelingTile({required this.emotion, required this.onTap});

  final Emotion emotion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final color = kEmotionColor[emotion]!;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: Ink(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: color.withValues(alpha: 0.45), width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(kEmotionIcon[emotion], size: 34, color: color),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                emotionLabel(emotion, l),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Warm "you got it" panel: the feeling, the short friendly line, and a
/// Continue button that resumes the film whenever the child likes.
class _PauseFeedback extends StatelessWidget {
  const _PauseFeedback({required this.pause, required this.onContinue});

  final StoryPause pause;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final color = kEmotionColor[pause.answer]!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.18),
            shape: BoxShape.circle,
          ),
          child: Icon(kEmotionIcon[pause.answer], size: 38, color: color),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          emotionLabel(pause.answer, l),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          pause.feedback,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton(onPressed: onContinue, child: Text(l.storyContinue)),
      ],
    );
  }
}
