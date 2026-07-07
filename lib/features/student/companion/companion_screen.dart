import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moodcraft/l10n/app_localizations.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:uuid/uuid.dart';

import '../../../app/theme/tokens.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/enums.dart';
import '../../../core/models/session.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/providers/sensory_settings_provider.dart';
import '../../../core/services/narration_service.dart';
import '../../../core/widgets/calm_scaffold.dart';
import '../../../core/widgets/sensory_settings_sheet.dart';
import '../../journal/journal_section.dart' show emotionLabel;
import 'companion_brain.dart';
import 'companion_chat_service.dart';
import 'companion_data.dart';
// The stage: full-body 3D TalkingHead avatar in a WebView on mobile; the calm
// placeholder face on web (keeps the web build free of WebView/3D deps).
import 'stage/companion_stage_controller.dart';
import 'stage/companion_stage_web.dart'
    if (dart.library.io) 'stage/companion_stage_mobile.dart';

/// FR3 — the AI companion. One calm screen: the companion's face up top, what
/// it is saying beneath, and the child's two gentle ways in below that.
///
/// **Teaching** (the core) is fully curated: tapping a feeling walks the vetted
/// lesson script from `companion_data.dart`, one short line per tap, the face
/// acting out each line. **Chat** (optional) sends the child's typed or spoken
/// words to safe-prompted Gemini; on any failure the companion calmly suggests
/// learning a feeling together instead. Every line the companion says is spoken
/// aloud (audio-first) in response to the child's own tap — nothing autoplays.
class CompanionScreen extends ConsumerStatefulWidget {
  const CompanionScreen({super.key});

  @override
  ConsumerState<CompanionScreen> createState() => _CompanionScreenState();
}

class _CompanionScreenState extends ConsumerState<CompanionScreen> {
  // What the companion is showing and saying right now. A null bubble means
  // the greeting, which is text-only — the companion never speaks unprompted.
  Emotion _expression = Emotion.happy;
  String? _bubbleText;
  // True while a lesson line, or a chat "show me your ... face" moment, talks
  // about the face: the 3D stage zooms the camera to the avatar's head so the
  // child can actually see it. It stays zoomed in until the next line lets go
  // of it (the next lesson line, or the child's next chat question).
  bool _focusFace = false;

  // Voice routing: when the 3D stage can speak (mobile, avatar ready, TTS key
  // present) lines go through the lip-synced avatar; otherwise device TTS.
  final CompanionStageController _stage = CompanionStageController();

  // Lesson walk-through (null emotion = no lesson running).
  Emotion? _lessonEmotion;
  int _lessonStep = 0;
  DateTime _lessonStartedAt = DateTime.now();
  bool _savingLesson = false;

  // Teaching round (the FR3 loop): the avatar demonstrates a feeling and asks;
  // the child answers by tapping one of three choices or by talking; the brain
  // judges gently; a right answer ends the round and logs it.
  Emotion? _roundTarget;
  Emotion? _lastRoundTarget;
  List<Emotion> _roundChoices = const [];
  int _roundAttempt = 1;
  int _roundMisses = 0;
  final List<String> _roundAnswers = [];
  DateTime _roundStartedAt = DateTime.now();
  bool _judging = false;
  final Random _random = Random();

  // Chat.
  final TextEditingController _input = TextEditingController();
  String? _childSaid;
  bool _sending = false;
  // True once a chat reply names one of the teachable feelings: the stage
  // keeps looping that feeling's pose until the child asks something else,
  // instead of settling back after a single pass.
  bool _chatDemonstrate = false;

  // Spoken input. The mic quietly disappears if the device can't listen —
  // typing always works, so nothing is ever blocked.
  final SpeechToText _speech = SpeechToText();
  bool _speechReady = false;
  bool _micHidden = false;
  bool _listening = false;

  // Leaving the screen is intercepted (see build's PopScope) so every exit,
  // system back button, back gesture, or the app bar's back arrow, awaits
  // the stop before the pop actually happens. dispose() alone can't do this:
  // it can't await, so the WebView's stopSpeaking() JS call would sometimes
  // race the native view being torn down and lose, leaving the avatar's
  // voice sounding after the child has already left.
  bool _canPop = false;

  @override
  void initState() {
    super.initState();
    ref.read(narrationServiceProvider).prewarm();
  }

  /// Stops every voice source and waits for it, so the WebView's
  /// stopSpeaking() has actually run before the screen is allowed to pop.
  /// Called from the PopScope below on every way out (back button, back
  /// gesture, app bar arrow); dispose() below keeps a fire-and-forget copy
  /// as a fallback for any teardown path that skips the pop interception.
  Future<void> _leaveScreen() async {
    await _stage.stop();
    ref.read(narrationServiceProvider).stop();
    await _speech.stop();
  }

  @override
  void dispose() {
    // Never let the companion's voice trail into the next screen. Nothing is
    // saved for next time on purpose: leaving stops everything, and coming
    // back is a fresh companion load, same as opening the screen new.
    _stage.stop();
    ref.read(narrationServiceProvider).stop();
    _speech.stop();
    _input.dispose();
    super.dispose();
  }

  double get _volume => ref.read(sensorySettingsProvider).masterVolume;

  /// Shows [text] in the bubble with [expression] on the face and speaks it.
  /// Only ever called from the child's own tap, so sound is never a surprise.
  /// [focusFace] zooms the 3D stage to the avatar's head for this line.
  void _say(String text, Emotion expression, {bool focusFace = false}) {
    setState(() {
      _bubbleText = text;
      _expression = expression;
      _focusFace = focusFace;
    });
    if (_stage.canSpeak) {
      ref.read(narrationServiceProvider).stop();
      _stage.speak(text);
    } else {
      ref.read(narrationServiceProvider).narrate(text, volume: _volume);
    }
  }

  // ── Curated lessons ─────────────────────────────────────────────────────

  void _startLesson(Emotion emotion) {
    final line = kCompanionLessons[emotion]!.first;
    setState(() {
      _lessonEmotion = emotion;
      _lessonStep = 0;
      _lessonStartedAt = DateTime.now();
      _childSaid = null;
      _roundTarget = null;
      _chatDemonstrate = false;
    });
    _say(line.text, line.expression, focusFace: line.focusFace);
  }

  // ── The teaching round (FR3's core loop) ────────────────────────────────

  void _startRound() {
    final l = AppLocalizations.of(context);
    // The chat is put away for the round, so a mic still listening from the
    // chat row must not deliver a late result into it.
    _speech.stop();
    _input.clear();
    // A fresh feeling each time (never the same one twice in a row), with the
    // right answer hidden among three choices like the quiz.
    final pool =
        kCompanionEmotions.where((e) => e != _lastRoundTarget).toList()
          ..shuffle(_random);
    final target = pool.first;
    final distractors =
        kCompanionEmotions.where((e) => e != target).toList()..shuffle(_random);
    setState(() {
      _lessonEmotion = null;
      _childSaid = null;
      _listening = false;
      _roundTarget = target;
      _lastRoundTarget = target;
      _roundChoices = [target, distractors[0], distractors[1]]
        ..shuffle(_random);
      _roundAttempt = 1;
      _roundMisses = 0;
      _roundAnswers.clear();
      _roundStartedAt = DateTime.now();
      _chatDemonstrate = false;
    });
    // The demonstrate beat: expression push makes the avatar act the feeling
    // out (face + body clip) while it asks the question aloud.
    _say(l.companionRoundAsk, target);
  }

  Future<void> _answerRound(String answer, {required bool spoken}) async {
    final l = AppLocalizations.of(context);
    final target = _roundTarget;
    if (target == null || _judging) return;
    _roundAnswers.add(answer);
    setState(() {
      _judging = true;
      _bubbleText = l.companionThinking;
    });
    final judgment = await ref
        .read(companionBrainProvider)
        .judge(
          target: target,
          answer: answer,
          spoken: spoken,
          attempt: _roundAttempt,
        );
    if (!mounted) return;
    setState(() => _judging = false);
    if (judgment.isCorrect) {
      _recordRound(target, judgment.observationNote);
      setState(() => _roundTarget = null);
      _say(judgment.spokenResponse, judgment.characterEmotion);
    } else {
      // Gentle redirect: stay in the round and KEEP demonstrating the target.
      // The judge's suggested face is ignored on a miss — the pose the child
      // is trying to read must not change until they get it right.
      setState(() {
        _roundAttempt++;
        _roundMisses++;
      });
      _say(judgment.spokenResponse, target);
    }
  }

  void _stopRound() {
    _stage.stop();
    ref.read(narrationServiceProvider).stop();
    setState(() {
      _roundTarget = null;
      _bubbleText = null;
      _expression = Emotion.happy;
      _chatDemonstrate = false;
    });
  }

  /// Logs the finished round for the teacher (FR8): which feeling, every
  /// answer given, how many extra tries, and the brain's observation note.
  Future<void> _recordRound(Emotion target, String note) async {
    try {
      final student = ref.read(activeStudentProvider).value;
      if (student == null) return;
      await ref
          .read(sessionRepositoryProvider)
          .add(
            Session(
              id: const Uuid().v4(),
              studentId: student.id,
              activityType: ActivityType.companion,
              emotionsShown: [target],
              responses: List.of(_roundAnswers),
              correctCount: 1,
              retries: _roundMisses,
              durationMs:
                  DateTime.now().difference(_roundStartedAt).inMilliseconds,
              note: note,
              timestamp: DateTime.now(),
            ),
          );
    } catch (_) {
      // The log is for the teacher; it never blocks the child.
    }
  }

  void _advanceLesson() {
    final emotion = _lessonEmotion;
    if (emotion == null) return;
    final lines = kCompanionLessons[emotion]!;
    if (_lessonStep + 1 < lines.length) {
      final line = lines[_lessonStep + 1];
      setState(() => _lessonStep++);
      _say(line.text, line.expression, focusFace: line.focusFace);
    } else {
      _recordLesson(emotion);
      setState(() => _lessonEmotion = null);
      _say(AppLocalizations.of(context).companionLessonDone, Emotion.happy);
    }
  }

  /// Records the finished lesson for the teacher dashboard (FR8). Best-effort:
  /// offline writes sync later via the Firestore cache (FR14).
  Future<void> _recordLesson(Emotion emotion) async {
    if (_savingLesson) return;
    _savingLesson = true;
    try {
      final student = ref.read(activeStudentProvider).value;
      if (student == null) return;
      await ref
          .read(sessionRepositoryProvider)
          .add(
            Session(
              id: const Uuid().v4(),
              studentId: student.id,
              activityType: ActivityType.companion,
              emotionsShown: [emotion],
              responses: [emotion.name],
              correctCount: 1,
              retries: 0,
              durationMs:
                  DateTime.now().difference(_lessonStartedAt).inMilliseconds,
              timestamp: DateTime.now(),
            ),
          );
    } catch (_) {
      // Recording is a nicety, never a blocker for the child.
    } finally {
      _savingLesson = false;
    }
  }

  // ── Optional safe chat ──────────────────────────────────────────────────

  Future<void> _sendChat() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending || _judging) return;
    // Guard set synchronously, before any await below: the mic fires both
    // onResult(finalResult) and onStatus(notListening/done) for the same
    // utterance in quick succession, and both call this method. Without
    // flipping _sending here first, the second call races in through the
    // await below (before _input is cleared or _sending flips true) and
    // sends, and speaks, the same message a second time.
    _sending = true;
    final l = AppLocalizations.of(context);
    await _speech.stop();
    _stage.stop();
    ref.read(narrationServiceProvider).stop();
    _input.clear();

    // During a guessing round the chat is put away (the input row is hidden
    // until the round settles); a stray send from a lingering mic result is
    // simply dropped.
    if (_roundTarget != null) {
      setState(() => _sending = false);
      return;
    }
    setState(() {
      _childSaid = text;
      _listening = false;
      _bubbleText = l.companionThinking;
      _expression = Emotion.neutral;
      // A face the child asked to see stays up until this next question,
      // not on a timer; asking anything new lets go of it.
      _focusFace = false;
    });

    final reply = await ref.read(companionChatServiceProvider).send(text);

    if (!mounted) return;
    setState(() => _sending = false);
    if (reply != null) {
      // A "show me your ... face" ask zooms to the head while the reply is
      // spoken, and now stays there until the child's next question.
      _say(reply.text, reply.expression, focusFace: reply.zoomFace);
      // Keep looping the pose for a named feeling until the child asks
      // something else; a neutral reply (off-topic redirect) settles back.
      setState(() => _chatDemonstrate = reply.expression != Emotion.neutral);
    } else {
      // Offline or the service is unavailable — redirect to the curated
      // lessons, calmly. No error states in student UI.
      _say(l.companionRestLine, Emotion.neutral);
      setState(() => _chatDemonstrate = false);
    }
  }

  Future<void> _toggleMic() async {
    if (_listening) {
      await _speech.stop();
      if (mounted) {
        setState(() => _listening = false);
        // The child chose to stop talking — their words go straight out, no
        // second tap needed (safe: _sendChat no-ops on an empty field).
        _sendChat();
      }
      return;
    }
    // Tapping the mic while the companion is mid-sentence interrupts it right
    // away: it is the child's turn to talk now. Harmless if it was already
    // quiet.
    _stage.stop();
    ref.read(narrationServiceProvider).stop();
    if (!_speechReady) {
      var ok = false;
      try {
        ok = await _speech.initialize(
          onStatus: (status) {
            if ((status == 'notListening' || status == 'done') && mounted) {
              setState(() => _listening = false);
              // Listening ended (pause or timeout) — send whatever was heard.
              _sendChat();
            }
          },
          onError: (_) {
            if (mounted) setState(() => _listening = false);
          },
        );
      } catch (_) {
        ok = false;
      }
      if (!mounted) return;
      if (!ok) {
        // No recognizer / permission declined: hide the mic and move on.
        setState(() => _micHidden = true);
        return;
      }
      _speechReady = true;
    }
    setState(() => _listening = true);
    await _speech.listen(
      onResult: (result) {
        _input.text = result.recognizedWords;
        _input.selection = TextSelection.collapsed(offset: _input.text.length);
        // The recogniser decided the child finished talking — send right
        // away. Duplicate triggers are harmless: the first send clears the
        // field and _sendChat ignores an empty one.
        if (result.finalResult && mounted) {
          setState(() => _listening = false);
          _sendChat();
        }
      },
      listenOptions: SpeechListenOptions(
        partialResults: true,
        listenFor: const Duration(seconds: 20),
        // Trimmed from 3s so the question goes out a little snappier once
        // the child stops talking.
        pauseFor: const Duration(milliseconds: 2500),
      ),
    );
  }

  // ── UI ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final intensity = ref.watch(
      sensorySettingsProvider.select((s) => s.animationIntensity),
    );
    final volume = ref.watch(
      sensorySettingsProvider.select((s) => s.masterVolume),
    );
    final inLesson = _lessonEmotion != null;
    final lessonLines =
        inLesson
            ? kCompanionLessons[_lessonEmotion!]!
            : const <CompanionLine>[];

    return PopScope(
      canPop: _canPop,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _leaveScreen();
        if (!context.mounted) return;
        setState(() => _canPop = true);
        Navigator.of(context).pop();
      },
      child: CalmScaffold(
        title: l.navCompanion,
        icon: Icons.chat_bubble_rounded,
        actions: accountActions(context, ref),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    children: [
                      const SizedBox(height: AppSpacing.sm),
                      CompanionStage(
                        expression: _expression,
                        focusFace: _focusFace,
                        // Lessons, rounds, and a chat reply about a named
                        // feeling all keep the body-language clip looping so
                        // the pose never fades out mid-teaching or mid-chat.
                        demonstrate:
                            inLesson ||
                            _roundTarget != null ||
                            _chatDemonstrate,
                        intensity: intensity,
                        volume: volume,
                        controller: _stage,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (_childSaid != null) ...[
                        _ChildBubble(text: _childSaid!),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                      _SpeechBubble(
                        text: _bubbleText ?? l.companionGreeting,
                        busy: _sending || _judging,
                        speakOverride: _stage.canSpeak ? _stage.speak : null,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      if (inLesson) ...[
                        _LessonDots(
                          total: lessonLines.length,
                          done: _lessonStep,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Center(
                          child: FilledButton.icon(
                            onPressed: _advanceLesson,
                            icon: const Icon(Icons.arrow_forward_rounded),
                            label: Text(l.companionNext),
                          ),
                        ),
                      ] else if (_roundTarget != null) ...[
                        Text(
                          l.companionRoundPick,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            for (final emotion in _roundChoices)
                              _FeelingTile(
                                emotion: emotion,
                                enabled: !_judging,
                                onTap:
                                    () => _answerRound(
                                      emotion.name,
                                      spoken: false,
                                    ),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Center(
                          child: TextButton(
                            onPressed: _judging ? null : _stopRound,
                            child: Text(l.companionStopRound),
                          ),
                        ),
                      ] else ...[
                        Center(
                          child: FilledButton.icon(
                            onPressed:
                                (_sending || _judging) ? null : _startRound,
                            icon: const Icon(Icons.emoji_emotions_rounded),
                            label: Text(l.companionPlayRound),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          l.companionPickFeeling,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            for (final emotion in kCompanionEmotions)
                              _FeelingTile(
                                emotion: emotion,
                                enabled: !_sending,
                                onTap: () => _startLesson(emotion),
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ),
                ),
                // The chat row steps aside during a lesson and during a guessing
                // round: one activity at a time, and mid-round the three tiles
                // are the only way to answer.
                if (!inLesson && _roundTarget == null)
                  _ChatInputRow(
                    controller: _input,
                    sending: _sending || _judging,
                    listening: _listening,
                    micHidden: _micHidden,
                    onMic: _toggleMic,
                    onSend: _sendChat,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// What the companion is saying, with a tap-to-replay button (audio-first, but
/// replay stays in the child's hands). While thinking it shows a tiny quiet
/// spinner instead.
class _SpeechBubble extends ConsumerWidget {
  const _SpeechBubble({
    required this.text,
    required this.busy,
    this.speakOverride,
  });

  final String text;
  final bool busy;

  /// When the 3D stage voices lines itself, replay goes through it instead of
  /// device narration.
  final Future<void> Function(String text)? speakOverride;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final narration = ref.read(narrationServiceProvider);
    final volume = ref.watch(
      sensorySettingsProvider.select((s) => s.masterVolume),
    );
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (busy) ...[
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            Text(
              text,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            if (!busy) ...[
              const SizedBox(height: AppSpacing.sm),
              if (speakOverride != null)
                TextButton.icon(
                  onPressed: () => speakOverride!(text),
                  icon: const Icon(Icons.volume_up_rounded, size: 20),
                  label: Text(l.companionHearAgain),
                )
              else
                ValueListenableBuilder<bool>(
                  valueListenable: narration.speaking,
                  builder: (context, speaking, _) {
                    return TextButton.icon(
                      onPressed:
                          speaking
                              ? () => narration.stop()
                              : () => narration.narrate(text, volume: volume),
                      icon: Icon(
                        speaking ? Icons.stop_rounded : Icons.volume_up_rounded,
                        size: 20,
                      ),
                      label: Text(l.companionHearAgain),
                    );
                  },
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The child's own last words, echoed back gently so the exchange reads like a
/// little conversation.
class _ChildBubble extends StatelessWidget {
  const _ChildBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        child: Text(text, style: theme.textTheme.bodyLarge),
      ),
    );
  }
}

/// Soft dots showing where the child is in the lesson — gentle progress, no
/// numbers or pressure (same idiom as the quiz).
class _LessonDots extends StatelessWidget {
  const _LessonDots({required this.total, required this.done});

  final int total;
  final int done;

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
              i <= done ? Icons.circle : Icons.circle_outlined,
              size: 14,
              color:
                  i <= done
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant,
            ),
          ),
      ],
    );
  }
}

/// One tappable feeling — a small round face tile in that feeling's constant
/// colour, opening its curated lesson.
class _FeelingTile extends StatelessWidget {
  const _FeelingTile({
    required this.emotion,
    required this.enabled,
    required this.onTap,
  });

  final Emotion emotion;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final color = kEmotionColor[emotion]!;
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: Ink(
        width: 96,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: color.withValues(alpha: 0.45), width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(kEmotionIcon[emotion], size: 30, color: color),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                emotionLabel(emotion, l),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Typed or spoken input for the optional chat. The mic fills the text field
/// live while listening; send always works from the keyboard too.
class _ChatInputRow extends StatelessWidget {
  const _ChatInputRow({
    required this.controller,
    required this.sending,
    required this.listening,
    required this.micHidden,
    required this.onMic,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final bool listening;
  final bool micHidden;
  final VoidCallback onMic;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: !sending,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText:
                    listening ? l.companionListening : l.companionInputHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
              ),
            ),
          ),
          if (!micHidden) ...[
            const SizedBox(width: AppSpacing.xs),
            IconButton.filledTonal(
              tooltip: l.companionTalk,
              onPressed: sending ? null : onMic,
              isSelected: listening,
              icon: Icon(
                listening ? Icons.graphic_eq_rounded : Icons.mic_rounded,
                color: listening ? theme.colorScheme.primary : null,
              ),
            ),
          ],
          const SizedBox(width: AppSpacing.xs),
          IconButton.filled(
            tooltip: l.companionSend,
            onPressed: sending ? null : onSend,
            icon: const Icon(Icons.send_rounded),
          ),
        ],
      ),
    );
  }
}
