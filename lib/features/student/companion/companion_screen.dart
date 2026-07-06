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

  // Spoken input. The mic quietly disappears if the device can't listen —
  // typing always works, so nothing is ever blocked.
  final SpeechToText _speech = SpeechToText();
  bool _speechReady = false;
  bool _micHidden = false;
  bool _listening = false;

  @override
  void initState() {
    super.initState();
    ref.read(narrationServiceProvider).prewarm();
  }

  @override
  void dispose() {
    // Never let the companion's voice trail into the next screen.
    _stage.stop();
    ref.read(narrationServiceProvider).stop();
    _speech.stop();
    _input.dispose();
    super.dispose();
  }

  double get _volume => ref.read(sensorySettingsProvider).masterVolume;

  /// Shows [text] in the bubble with [expression] on the face and speaks it.
  /// Only ever called from the child's own tap, so sound is never a surprise.
  void _say(String text, Emotion expression) {
    setState(() {
      _bubbleText = text;
      _expression = expression;
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
    });
    _say(line.text, line.expression);
  }

  // ── The teaching round (FR3's core loop) ────────────────────────────────

  void _startRound() {
    final l = AppLocalizations.of(context);
    // A fresh feeling each time (never the same one twice in a row), with the
    // right answer hidden among three choices like the quiz.
    final pool =
        kCompanionEmotions.where((e) => e != _lastRoundTarget).toList()
          ..shuffle(_random);
    final target = pool.first;
    final distractors =
        kCompanionEmotions.where((e) => e != target).toList()
          ..shuffle(_random);
    setState(() {
      _lessonEmotion = null;
      _childSaid = null;
      _roundTarget = target;
      _lastRoundTarget = target;
      _roundChoices = [target, distractors[0], distractors[1]]
        ..shuffle(_random);
      _roundAttempt = 1;
      _roundMisses = 0;
      _roundAnswers.clear();
      _roundStartedAt = DateTime.now();
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
    } else {
      // Gentle redirect: stay in the round, the avatar keeps demonstrating.
      setState(() {
        _roundAttempt++;
        _roundMisses++;
      });
    }
    _say(judgment.spokenResponse, judgment.characterEmotion);
  }

  void _stopRound() {
    _stage.stop();
    ref.read(narrationServiceProvider).stop();
    setState(() {
      _roundTarget = null;
      _bubbleText = null;
      _expression = Emotion.happy;
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
      _say(line.text, line.expression);
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
    final l = AppLocalizations.of(context);
    final text = _input.text.trim();
    if (text.isEmpty || _sending || _judging) return;
    await _speech.stop();
    _stage.stop();
    ref.read(narrationServiceProvider).stop();
    _input.clear();

    // Mid-round, the child's words are their answer, not a chat message.
    if (_roundTarget != null) {
      setState(() {
        _childSaid = text;
        _listening = false;
      });
      await _answerRound(text, spoken: true);
      return;
    }
    setState(() {
      _childSaid = text;
      _sending = true;
      _listening = false;
      _bubbleText = l.companionThinking;
      _expression = Emotion.neutral;
    });

    final reply = await ref.read(companionChatServiceProvider).send(text);

    if (!mounted) return;
    setState(() => _sending = false);
    if (reply != null) {
      _say(reply.text, reply.expression);
    } else {
      // Offline or the service is unavailable — redirect to the curated
      // lessons, calmly. No error states in student UI.
      _say(l.companionRestLine, Emotion.neutral);
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
        pauseFor: const Duration(seconds: 3),
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
        inLesson ? kCompanionLessons[_lessonEmotion!]! : const <CompanionLine>[];

    return CalmScaffold(
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
                      _LessonDots(total: lessonLines.length, done: _lessonStep),
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
              if (!inLesson)
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
    );
  }
}

/// What the companion is saying, with a tap-to-replay button (audio-first, but
/// replay stays in the child's hands). While thinking it shows a tiny quiet
/// spinner instead.
class _SpeechBubble extends ConsumerWidget {
  const _SpeechBubble({required this.text, required this.busy, this.speakOverride});

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
                        speaking
                            ? Icons.stop_rounded
                            : Icons.volume_up_rounded,
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
      padding: const EdgeInsets.only(
        top: AppSpacing.sm,
        bottom: AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: !sending,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: listening ? l.companionListening : l.companionInputHint,
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
