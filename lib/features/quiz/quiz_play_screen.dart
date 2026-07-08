import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moodcraft/l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';

import '../../app/theme/tokens.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/enums.dart';
import '../../core/models/quiz_round.dart';
import '../../core/models/session.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/providers/sensory_settings_provider.dart';
import '../../core/services/narration_service.dart';
import '../../core/services/rewards_service.dart';
import '../../core/services/sound_cue_service.dart';
import '../../core/widgets/calm_scaffold.dart';
import '../../core/widgets/reward_celebration.dart';
import '../journal/journal_section.dart' show emotionLabel;
import 'quiz_data.dart';

/// Arguments for the student quiz play route: which daily [setIndex] to play and
/// the student id ([studentId] null = teacher classroom mode, no record).
typedef QuizPlayArgs = ({String? studentId, int setIndex});

/// FR7 — one stress-free feelings quiz round for a chosen daily set. Each
/// question asks in one of three gentle ways (look at a face/scene, listen to a
/// short sound, or hear a tiny story) and the child taps the matching feeling.
///
/// There is no timer and no score. A right tap shows and speaks a warm feedback
/// line; the child can move on whenever they like (tapping **Next** cuts the
/// narration straight away). A wrong tap is a calm "look again" with another try
/// — no buzzer, no red, no penalty. Progress is just soft dots, and each answer
/// is saved as it happens so the round resumes on the next unanswered question
/// after leaving or signing out (like Mix-and-Match).
///
/// [studentId] null = teacher classroom/projection mode: the round plays but no
/// session is recorded and no progress is saved — a group demo, not one child's
/// record.
class QuizPlayScreen extends ConsumerStatefulWidget {
  const QuizPlayScreen({
    required this.studentId,
    required this.setIndex,
    super.key,
  });

  final String? studentId;
  final int setIndex;

  @override
  ConsumerState<QuizPlayScreen> createState() => _QuizPlayScreenState();
}

class _QuizPlayScreenState extends ConsumerState<QuizPlayScreen> {
  List<QuizQuestion>? _deck;
  int _index = 0;
  int _retries = 0; // wrong taps (telemetry only, never shown to the child)
  int _firstTryCorrect = 0;
  bool _missedCurrent = false;
  bool _answered = false; // current question answered right -> show feedback
  DateTime _startedAt = DateTime.now();
  bool _saved = false;
  RewardOutcome? _outcome; // stars/badges just earned, shown on the done screen

  @override
  void initState() {
    super.initState();
    ref.read(narrationServiceProvider).prewarm();
    _load();
  }

  @override
  void dispose() {
    // Never let a prompt or feedback trail into the next screen.
    ref.read(narrationServiceProvider).stop();
    ref.read(soundCueServiceProvider).stop();
    super.dispose();
  }

  Future<void> _load() async {
    // Resume the exact same round the child left mid-way (same questions, same
    // order, same spot), even after signing out. A finished round (or none)
    // starts fresh. Classroom mode (null studentId) always starts fresh.
    QuizRound? saved;
    final studentId = widget.studentId;
    if (studentId != null) {
      try {
        final student = await ref
            .read(studentRepositoryProvider)
            .getStudent(studentId);
        saved = student?.quizRounds[widget.setIndex.toString()];
      } catch (_) {
        // Couldn't read saved progress — just start fresh below.
      }
    }

    List<QuizQuestion> deck;
    int start;
    bool fresh;
    if (saved != null && saved.questions.isNotEmpty && !saved.isComplete) {
      deck = deckFromRound(saved);
      start = saved.answered;
      fresh = false;
    } else {
      deck = await buildQuizDeck(setIndex: widget.setIndex);
      start = 0;
      fresh = true;
    }

    if (!mounted) return;
    setState(() {
      _deck = deck;
      _index = start.clamp(0, deck.length);
      _startedAt = DateTime.now();
    });
    // Persist the freshly built questions right away so a resume gets the exact
    // same round even if the child leaves before answering anything.
    if (fresh) _saveRound(0);
  }

  double get _volume => ref.read(sensorySettingsProvider).masterVolume;

  void _onAnswer(QuizQuestion q, Emotion pick) {
    if (_answered) return;
    if (pick == q.answer) {
      if (!_missedCurrent) _firstTryCorrect++;
      ref.read(soundCueServiceProvider).stop();
      setState(() => _answered = true);
      // Mark this question answered right away (answered = next index), so if the
      // child quits during the feedback they resume on the NEXT question, not by
      // re-answering this one.
      _saveRound(_index + 1);
      if (ref.read(sensorySettingsProvider).feedbackNarration) {
        ref.read(narrationServiceProvider).narrate(q.feedback, volume: _volume);
      }
    } else {
      // Gentle, no-penalty redirect: stay on the question for another try.
      setState(() {
        _retries++;
        _missedCurrent = true;
      });
    }
  }

  void _next() {
    final deck = _deck!;
    final wasLast = _index >= deck.length - 1;
    // Cut the feedback narration the instant the child moves on.
    ref.read(narrationServiceProvider).stop();
    setState(() {
      _index++;
      _answered = false;
      _missedCurrent = false;
    });
    if (wasLast) _finish();
  }

  /// Saves the current round (questions + how many answered) so the child
  /// resumes the exact next question. Student mode only (classroom keeps no
  /// record). Best-effort: a failed write just syncs later via the cache (FR14).
  Future<void> _saveRound(int answered) async {
    final studentId = widget.studentId;
    final deck = _deck;
    if (studentId == null || deck == null) return;
    final repo = ref.read(studentRepositoryProvider);
    try {
      final student = await repo.getStudent(studentId);
      if (student == null) return;
      final updated = Map<String, QuizRound>.from(student.quizRounds)
        ..[widget.setIndex.toString()] = roundFromDeck(deck, answered);
      await repo.upsert(student.copyWith(quizRounds: updated));
    } catch (_) {
      // Ignore — saving progress is a nicety, never blocks play.
    }
  }

  /// Records the round for the teacher dashboard (FR8). Student mode only.
  Future<void> _finish() async {
    if (_saved || widget.studentId == null) return;
    _saved = true;
    final deck = _deck!;
    // The final answer's round save is fire-and-forget (it runs while feedback
    // shows), so land this set's completion before the reads below so the
    // "all three sets done" badge check sees it (and never clobbers it).
    await _saveRound(deck.length);
    final session = Session(
      id: const Uuid().v4(),
      studentId: widget.studentId!,
      activityType: ActivityType.quiz,
      emotionsShown: deck.map((q) => q.answer).toList(),
      responses: deck.map((q) => q.answer.name).toList(),
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
    // A fresh read sees every daily set's progress: check whether this set was
    // the one that finished all three, which earns the completed badge (FR11).
    final student = await ref
        .read(studentRepositoryProvider)
        .getStudent(widget.studentId!);
    final allDone = student != null && quizAllComplete(student);
    // Grant participation stars + any new badges (FR11) and reveal them on the
    // done screen. Best-effort: a failed award just shows a calm "all done".
    final outcome = await ref
        .read(rewardsServiceProvider)
        .awardForSession(
          studentId: widget.studentId!,
          activity: ActivityType.quiz,
          activityCompleted: allDone,
        );
    if (mounted) setState(() => _outcome = outcome);
  }

  bool get _done => _deck != null && _index >= _deck!.length;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final speak = ref.watch(
      sensorySettingsProvider.select((s) => s.feedbackNarration),
    );
    return CalmScaffold(
      title: l.navQuiz,
      icon: Icons.emoji_objects_rounded,
      actions: [
        IconButton(
          tooltip: speak ? l.quizMuteVoice : l.quizUnmuteVoice,
          icon: Icon(
            speak ? Icons.volume_up_rounded : Icons.volume_off_rounded,
          ),
          onPressed: () {
            final on = !speak;
            ref.read(sensorySettingsProvider.notifier).setFeedbackNarration(on);
            // Silence any feedback already playing the moment it's turned off.
            if (!on) ref.read(narrationServiceProvider).stop();
          },
        ),
      ],
      body:
          _deck == null
              ? const Center(child: CircularProgressIndicator())
              : (_deck!.isEmpty || _done)
              ? RewardCelebration(
                outcome: _outcome,
                title: l.quizDone,
                body: l.quizDoneBody,
                doneLabel: l.quizDoneButton,
                onDone: () => context.pop(),
              )
              : _buildRound(context, l),
    );
  }

  Widget _buildRound(BuildContext context, AppLocalizations l) {
    final theme = Theme.of(context);
    final deck = _deck!;
    final q = deck[_index];
    final isLast = _index >= deck.length - 1;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          children: [
            _ProgressDots(
              total: deck.length,
              filled: _index + (_answered ? 1 : 0),
            ),
            const SizedBox(height: AppSpacing.md),
            // The prompt — image / listen button / story. Keyed by id so a new
            // question animates in cleanly. Once answered it goes static (no audio
            // button) so the card's own sound is never confused with the feedback.
            Expanded(
              flex: 3,
              child: Center(
                child: _Prompt(
                  key: ValueKey(q.id),
                  question: q,
                  answered: _answered,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (_answered)
              Expanded(
                flex: 4,
                child: _Feedback(question: q, isLast: isLast, onNext: _next),
              )
            else ...[
              Text(
                _askFor(q.modality, l),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
              if (_missedCurrent) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l.quizTryAgain,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              Expanded(
                flex: 4,
                child: _Choices(question: q, onPick: (e) => _onAnswer(q, e)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _askFor(QuizModality m, AppLocalizations l) => switch (m) {
    QuizModality.look => l.quizAskLook,
    QuizModality.listen => l.quizAskListen,
    QuizModality.story => l.quizAskStory,
  };
}

/// Soft dots showing how many questions are done — gentle progress, no numbers
/// or pressure.
class _ProgressDots extends StatelessWidget {
  const _ProgressDots({required this.total, required this.filled});

  final int total;
  final int filled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < total; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Icon(
              i < filled ? Icons.circle : Icons.circle_outlined,
              size: 14,
              color:
                  i < filled
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant,
            ),
          ),
      ],
    );
  }
}

/// The question prompt, drawn for its modality. When [answered] it is purely
/// visual — the audio controls belong to the question, not the feedback.
class _Prompt extends StatelessWidget {
  const _Prompt({required this.question, required this.answered, super.key});

  final QuizQuestion question;
  final bool answered;

  @override
  Widget build(BuildContext context) {
    switch (question.modality) {
      case QuizModality.look:
        return _ImagePrompt(path: question.assetPath!);
      case QuizModality.listen:
        return _ListenPrompt(path: question.assetPath!, answered: answered);
      case QuizModality.story:
        return _StoryPrompt(text: question.text!, answered: answered);
    }
  }
}

/// "Look" — a single feeling picture, shown calmly in a soft card.
class _ImagePrompt extends StatelessWidget {
  const _ImagePrompt({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 240, maxHeight: 240),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.md),
            child: Image.asset(path, filterQuality: FilterQuality.medium),
          ),
        ),
      ),
    );
  }
}

/// "Listen" — one big, calm circle. Tap to play the sound cue; tap again to hear
/// it from the start. The sound never autoplays. Once [answered] it is static so
/// it cannot play over the spoken feedback.
class _ListenPrompt extends ConsumerWidget {
  const _ListenPrompt({required this.path, required this.answered});

  final String path;
  final bool answered;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final service = ref.read(soundCueServiceProvider);
    final volume = ref.watch(
      sensorySettingsProvider.select((s) => s.masterVolume),
    );
    final accent = activityAccent('quiz');
    return ValueListenableBuilder<bool>(
      valueListenable: service.playing,
      builder: (context, playing, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(AppRadii.pill),
              onTap: answered ? null : () => service.play(path, volume: volume),
              child: Container(
                width: 156,
                height: 156,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: playing ? 0.30 : 0.16),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: accent.withValues(alpha: 0.55),
                    width: 2,
                  ),
                ),
                child: Icon(
                  playing ? Icons.graphic_eq_rounded : Icons.volume_up_rounded,
                  size: 68,
                  color: accent,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              playing ? l.quizPlaying : l.quizListen,
              style: theme.textTheme.titleMedium,
            ),
          ],
        );
      },
    );
  }
}

/// "Story" — a tiny scenario in a card with a tap-to-hear button (audio-first).
/// The button reads only this scenario; once [answered] it is hidden so it can
/// never be mistaken for the spoken feedback.
class _StoryPrompt extends ConsumerWidget {
  const _StoryPrompt({required this.text, required this.answered});

  final String text;
  final bool answered;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final service = ref.read(narrationServiceProvider);
    final volume = ref.watch(
      sensorySettingsProvider.select((s) => s.masterVolume),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Container(
              width: 320,
              constraints: const BoxConstraints(minHeight: 120, maxHeight: 200),
              padding: const EdgeInsets.all(AppSpacing.lg),
              alignment: Alignment.center,
              child: Text(
                text,
                textAlign: TextAlign.center,
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium,
              ),
            ),
          ),
        ),
        if (!answered) ...[
          const SizedBox(height: AppSpacing.md),
          ValueListenableBuilder<bool>(
            valueListenable: service.speaking,
            builder: (context, speaking, _) {
              return FilledButton.tonalIcon(
                onPressed:
                    speaking
                        ? () => service.stop()
                        : () => service.narrate(text, volume: volume),
                icon: Icon(
                  speaking ? Icons.pause_rounded : Icons.play_arrow_rounded,
                ),
                label: Text(speaking ? l.quizPlaying : l.quizListen),
              );
            },
          ),
        ],
      ],
    );
  }
}

/// The three feeling choices — large, equal-width face tiles. One tap answers.
class _Choices extends StatelessWidget {
  const _Choices({required this.question, required this.onPick});

  final QuizQuestion question;
  final ValueChanged<Emotion> onPick;

  @override
  Widget build(BuildContext context) {
    final options = question.options;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _ChoiceTile(
              emotion: options[i],
              onTap: () => onPick(options[i]),
            ),
          ),
        ],
      ],
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({required this.emotion, required this.onTap});

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
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
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

/// Warm "you got it" panel after a correct tap: the feeling, the short feedback
/// line, and a Next button the child can tap whenever they like (it cuts the
/// narration and moves on).
class _Feedback extends StatelessWidget {
  const _Feedback({
    required this.question,
    required this.isLast,
    required this.onNext,
  });

  final QuizQuestion question;
  final bool isLast;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final color = kEmotionColor[question.answer]!;
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(
                kEmotionIcon[question.answer],
                size: 38,
                color: color,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              emotionLabel(question.answer, l),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              question.feedback,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: onNext,
              child: Text(isLast ? l.quizFinish : l.quizNext),
            ),
          ],
        ),
      ),
    );
  }
}
