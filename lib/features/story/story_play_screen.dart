import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show DeviceOrientation, SystemChrome;
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
import '../../core/services/narration_service.dart';
import '../../core/widgets/calm_scaffold.dart';
import '../journal/journal_section.dart' show emotionLabel;
import 'story_data.dart';

/// Arguments for the story play route: the student id ([studentId] null =
/// teacher classroom mode, no record), which story and which episode (0-based).
typedef StoryPlayArgs = ({String? studentId, String storyId, int level});

/// FR5 — one story episode: a landscape video that pauses at emotional moments
/// to ask how the character feels, quiz-style. Three feeling choices; a right
/// tap speaks a warm tailored line (Continue cuts the narration and resumes the
/// video), a wrong tap is a calm "look again" with another try. No timer, no
/// score. The video never autoplays — the child taps play.
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

  int _pausesDone = 0;
  bool _inQuestion = false;
  bool _answered = false; // current pause answered right -> feedback showing
  bool _missedCurrent = false;
  int _retries = 0; // wrong taps (telemetry only, never shown to the child)
  int _firstTryCorrect = 0;
  bool _finished = false;
  bool _sessionSaved = false;
  DateTime _startedAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    _story = storyById(widget.storyId);
    final episodes = _story?.episodes ?? const [];
    _episode =
        (widget.level >= 0 && widget.level < episodes.length)
            ? episodes[widget.level]
            : null;
    // Landscape, like watching a little film (web stays as the browser is).
    if (!kIsWeb) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
    ref.read(narrationServiceProvider).prewarm();
    _load();
  }

  @override
  void dispose() {
    // Never let feedback narration trail into the next screen.
    ref.read(narrationServiceProvider).stop();
    _controller?.removeListener(_onTick);
    _controller?.dispose();
    if (!kIsWeb) {
      SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    }
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
        _frontier = widget.level == progress.levelsDone;
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
    if (resumeMs > 0) await controller.seekTo(Duration(milliseconds: resumeMs));
    controller.addListener(_onTick);
    setState(() {
      _controller = controller;
      _ready = true;
      _startedAt = DateTime.now();
    });
  }

  /// Playback watcher: pauses the video the moment it reaches the next unasked
  /// pause moment, and spots the natural end of the episode.
  void _onTick() {
    final controller = _controller;
    final episode = _episode;
    if (controller == null || episode == null) return;
    final v = controller.value;
    if (!v.isInitialized) return;

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

    if (!_finished &&
        !_inQuestion &&
        v.duration > Duration.zero &&
        v.position >= v.duration &&
        !v.isPlaying) {
      _finish();
    }
  }

  double get _volume => ref.read(sensorySettingsProvider).masterVolume;

  void _onAnswer(StoryPause pause, Emotion pick) {
    if (_answered) return;
    if (pick == pause.answer) {
      if (!_missedCurrent) _firstTryCorrect++;
      setState(() => _answered = true);
      // Mark this pause answered right away, so a quit during the feedback
      // resumes after this pause, not by re-answering it.
      _saveProgress(pausesDone: _pausesDone + 1, positionMs: pause.atMs);
      ref
          .read(narrationServiceProvider)
          .narrate(pause.feedback, volume: _volume);
    } else {
      // Gentle, no-penalty redirect: stay on the question for another try.
      setState(() {
        _retries++;
        _missedCurrent = true;
      });
    }
  }

  /// Hides the question and lets the film carry on. Cuts the feedback narration
  /// the instant the child moves on.
  void _continueStory() {
    ref.read(narrationServiceProvider).stop();
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
          levelsDone: episodeDone ? widget.level + 1 : widget.level,
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
    _saveProgress(pausesDone: 0, positionMs: 0, episodeDone: true);
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
        body: _StoryDone(onDone: () => context.pop()),
      );
    }
    if (!_ready) {
      return CalmScaffold(
        title: title,
        icon: Icons.menu_book_rounded,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return _buildPlayer(context, l);
  }

  Widget _buildPlayer(BuildContext context, AppLocalizations l) {
    final theme = Theme.of(context);
    final controller = _controller!;
    final episode = _episode!;
    final pause =
        _pausesDone < episode.pauses.length
            ? episode.pauses[_pausesDone]
            : null;
    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      body: SafeArea(
        child: Stack(
          children: [
            // The film, letterboxed like a video player. Tapping it is the one
            // control: play when paused, pause when playing.
            Positioned.fill(
              child: ValueListenableBuilder<VideoPlayerValue>(
                valueListenable: controller,
                builder: (context, value, _) {
                  return GestureDetector(
                    onTap:
                        _inQuestion
                            ? null
                            : () =>
                                value.isPlaying
                                    ? controller.pause()
                                    : controller.play(),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Center(
                          child: AspectRatio(
                            aspectRatio:
                                value.aspectRatio > 0
                                    ? value.aspectRatio
                                    : 16 / 9,
                            child: VideoPlayer(controller),
                          ),
                        ),
                        // One big, calm play button when the film is waiting.
                        if (!value.isPlaying && !_inQuestion)
                          Container(
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
                      ],
                    ),
                  );
                },
              ),
            ),
            // Soft progress line along the bottom — no scrubbing, so the film
            // can never skip past a feelings moment.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: VideoProgressIndicator(
                controller,
                allowScrubbing: false,
                colors: VideoProgressColors(
                  playedColor: activityAccent('story'),
                  bufferedColor: theme.colorScheme.outlineVariant,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                ),
              ),
            ),
            // Calm way back.
            Positioned(
              top: AppSpacing.sm,
              left: AppSpacing.sm,
              child: IconButton.filledTonal(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            ),
            // The pause-and-ask moment, over a softly dimmed film.
            if (_inQuestion && pause != null)
              Positioned.fill(
                child: _PauseQuestion(
                  pause: pause,
                  options: storyOptionsFor(
                    widget.storyId,
                    widget.level,
                    _pausesDone,
                    pause.answer,
                  ),
                  answered: _answered,
                  missed: _missedCurrent,
                  onPick: (e) => _onAnswer(pause, e),
                  onContinue: _continueStory,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The quiz-style question shown while the film waits: three feeling choices,
/// then a warm feedback panel with Continue. A wrong tap shows a gentle "look
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
    return Container(
      color: theme.colorScheme.surface.withValues(alpha: 0.88),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child:
            answered
                ? _PauseFeedback(pause: pause, onContinue: onContinue)
                : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l.storyAskFeeling,
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
                      crossAxisAlignment: CrossAxisAlignment.stretch,
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
                ),
      ),
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

/// Warm "you got it" panel: the feeling, the tailored line (also spoken), and a
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

/// Calm end-of-episode moment — no stars yet (FR11 rewards deferred). A warm
/// "the end" and a way back to the story picker.
class _StoryDone extends StatelessWidget {
  const _StoryDone({required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_rounded,
              size: 88,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l.storyDone,
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l.storyDoneBody,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(onPressed: onDone, child: Text(l.storyDoneButton)),
          ],
        ),
      ),
    );
  }
}
