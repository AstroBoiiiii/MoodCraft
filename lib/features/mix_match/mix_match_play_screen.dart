import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moodcraft/l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';

import '../../app/theme/tokens.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/enums.dart';
import '../../core/models/mix_match_round.dart';
import '../../core/models/session.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/providers/sensory_settings_provider.dart';
import '../../core/services/narration_service.dart';
import '../../core/widgets/calm_scaffold.dart';
import '../journal/journal_section.dart' show emotionLabel;
import 'mix_match_data.dart';

/// FR6 — one Mix-and-Match round. The five feelings are fixed drop-buckets in
/// the same spots every time (predictable layout, CLAUDE.md section 4.2). The
/// child drags the current card onto the matching feeling. A wrong drop is a
/// calm, no-penalty redirect: the card simply stays for another try. There is no
/// timer, no score shown, no fail state.
///
/// [studentId] null = teacher "classroom" mode (projection): plays the same
/// round but writes no session and saves no progress. It's a group demo, not one
/// child's record.
class MixMatchPlayScreen extends ConsumerStatefulWidget {
  const MixMatchPlayScreen({required this.type, this.studentId, super.key});

  final MixMatchType type;
  final String? studentId;

  @override
  ConsumerState<MixMatchPlayScreen> createState() => _MixMatchPlayScreenState();
}

class _MixMatchPlayScreenState extends ConsumerState<MixMatchPlayScreen> {
  static const int _roundSize = kMixMatchRoundSize;
  static const _emotions = kMixMatchEmotions;

  List<MixMatchCard>? _deck;
  int _index = 0; // current card
  int _retries = 0; // total misses (telemetry only, never shown)
  int _firstTryCorrect = 0;
  bool _missedCurrent = false;
  bool _nudge = false; // show a gentle "try again" hint after a miss
  Emotion? _justAccepted; // bucket to glow briefly on a correct drop
  DateTime _startedAt = DateTime.now();
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _load();
    // Warm up the device/browser voices now so the first "Listen" tap on a story
    // card speaks immediately (web loads its voice list asynchronously).
    ref.read(narrationServiceProvider).prewarm();
  }

  @override
  void dispose() {
    // Cut any narration when leaving the round so it never trails into the next
    // screen.
    ref.read(narrationServiceProvider).stop();
    super.dispose();
  }

  Future<void> _load() async {
    // Resume the exact same round the child left mid-way (same cards, same
    // order, same spot) so question "a" is still question "a" on return, even
    // after signing out. A finished round (or none) starts a fresh deck.
    // Classroom mode (null studentId) keeps no record, so always starts fresh.
    MixMatchRound? saved;
    final studentId = widget.studentId;
    if (studentId != null) {
      try {
        final student = await ref
            .read(studentRepositoryProvider)
            .getStudent(studentId);
        saved = student?.mixMatchRounds[widget.type.name];
      } catch (_) {
        // Couldn't read the saved round — just start fresh below.
      }
    }

    List<MixMatchCard> deck;
    int start;
    if (saved != null && saved.cards.isNotEmpty && !saved.isComplete) {
      deck = deckFromRound(widget.type, saved);
      start = saved.placed;
    } else {
      deck = await buildMixMatchDeck(widget.type, count: _roundSize);
      start = 0;
    }

    if (!mounted) return;
    setState(() {
      _deck = deck;
      _index = start.clamp(0, deck.length);
      _startedAt = DateTime.now();
    });
  }

  bool get _done => _deck != null && _index >= _deck!.length;

  void _onDrop(MixMatchCard card, Emotion bucket) {
    if (bucket == card.answer) {
      if (!_missedCurrent) _firstTryCorrect++;
      // Stop narrating the card that was just placed before the next one shows.
      ref.read(narrationServiceProvider).stop();
      setState(() {
        _justAccepted = bucket;
        _nudge = false;
        _index++;
        _missedCurrent = false;
      });
      // Clear the brief bucket glow.
      final settings = ref.read(sensorySettingsProvider);
      Future.delayed(
        effectiveDuration(settings.animationIntensity, AppDurations.slow),
        () {
          if (mounted) setState(() => _justAccepted = null);
        },
      );
      // Persist the round (deck + how many placed) as each card lands, so the
      // child resumes the exact same question after leaving or signing out.
      _saveRound(_index);
      if (_done) _finish();
    } else {
      setState(() {
        _retries++;
        _missedCurrent = true;
        _nudge = true;
      });
    }
  }

  Future<void> _finish() async {
    // Classroom mode (null studentId) records nothing; only write once.
    if (_saved || widget.studentId == null) return;
    _saved = true;
    final studentId = widget.studentId!;
    final deck = _deck!;

    final session = Session(
      id: const Uuid().v4(),
      studentId: studentId,
      activityType: ActivityType.mixmatch,
      emotionsShown: deck.map((c) => c.answer).toList(),
      responses: deck.map((c) => c.answer.name).toList(),
      correctCount: _firstTryCorrect,
      retries: _retries,
      durationMs: DateTime.now().difference(_startedAt).inMilliseconds,
      timestamp: DateTime.now(),
    );
    try {
      await ref.read(sessionRepositoryProvider).add(session);
    } catch (_) {
      // Offline/transient — Firestore cache will sync later (FR14). The child's
      // calm "all done" moment never depends on the write succeeding.
    }
  }

  /// Saves the current round (deck + cards placed) for this category so the
  /// child resumes the exact same question, and the home tile shows "X/5".
  /// Student mode only (classroom keeps no record). Best-effort: a failed write
  /// just syncs later via the Firestore cache (FR14).
  Future<void> _saveRound(int placed) async {
    final studentId = widget.studentId;
    final deck = _deck;
    if (studentId == null || deck == null) return;
    final repo = ref.read(studentRepositoryProvider);
    try {
      final student = await repo.getStudent(studentId);
      if (student == null) return;
      final updated = Map<String, MixMatchRound>.from(student.mixMatchRounds)
        ..[widget.type.name] = roundFromDeck(deck, placed);
      await repo.upsert(student.copyWith(mixMatchRounds: updated));
    } catch (_) {
      // Ignore — saving progress is a nicety, never blocks play.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return CalmScaffold(
      title: l.navMatch,
      icon: Icons.extension_rounded,
      body:
          _deck == null
              ? const Center(child: CircularProgressIndicator())
              : _done
              ? _Completion(onDone: () => context.pop())
              : _buildRound(context, l),
    );
  }

  Widget _buildRound(BuildContext context, AppLocalizations l) {
    final theme = Theme.of(context);
    final deck = _deck!;
    final card = deck[_index];
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          children: [
            _ProgressDots(total: deck.length, placed: _index),
            const SizedBox(height: AppSpacing.md),
            Text(
              _nudge ? l.mixMatchTryAgain : l.mixMatchPrompt,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            // The card to place. Keyed by id so a new card animates in cleanly.
            Expanded(
              flex: 3,
              child: Center(
                child: _DraggableCard(key: ValueKey(card.id), card: card),
              ),
            ),
            // Tap to hear the story/situation read aloud (audio-first, FR6). Only
            // text cards have words to narrate; faces and bodies are picture-only.
            if (card.isText) ...[
              const SizedBox(height: AppSpacing.md),
              _NarrateButton(text: card.text!),
            ],
            const SizedBox(height: AppSpacing.lg),
            Expanded(flex: 4, child: _buildBuckets()),
          ],
        ),
      ),
    );
  }

  /// The five feeling buckets, evenly arranged and centred: three on top, two
  /// centred below. Clean word boxes (no icons), each tinted with its feeling's
  /// colour so the cue stays gentle and predictable.
  Widget _buildBuckets() {
    const spacing = AppSpacing.sm;
    final top = _emotions.take(3).toList();
    final bottom = _emotions.skip(3).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Match the bottom row's box width to the top row's cells so the whole
        // block lines up neatly whatever the screen width.
        final cellWidth = (constraints.maxWidth - spacing * 2) / 3;

        Widget rowFor(List<Emotion> emotions) => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < emotions.length; i++) ...[
              if (i > 0) const SizedBox(width: spacing),
              SizedBox(
                width: cellWidth,
                child: _EmotionBucket(
                  emotion: emotions[i],
                  glow: _justAccepted == emotions[i],
                  onAccept: (c) => _onDrop(c, emotions[i]),
                ),
              ),
            ],
          ],
        );

        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 84, child: rowFor(top)),
              const SizedBox(height: spacing),
              SizedBox(height: 84, child: rowFor(bottom)),
            ],
          ),
        );
      },
    );
  }
}

/// Five soft dots showing how many cards are placed — gentle progress, no
/// numbers or pressure.
class _ProgressDots extends StatelessWidget {
  const _ProgressDots({required this.total, required this.placed});

  final int total;
  final int placed;

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
              i < placed ? Icons.circle : Icons.circle_outlined,
              size: 14,
              color:
                  i < placed
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant,
            ),
          ),
      ],
    );
  }
}

/// Reads the current text card aloud (FR6 audio-first narration). One large,
/// calm tap target that toggles: tap to play, tap again while it is playing to
/// stop, then tap once more to play again from the beginning. Honours the
/// student's master volume.
class _NarrateButton extends ConsumerWidget {
  const _NarrateButton({required this.text});

  final String text;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final service = ref.read(narrationServiceProvider);
    final volume = ref.watch(
      sensorySettingsProvider.select((s) => s.masterVolume),
    );
    return ValueListenableBuilder<bool>(
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
          label: Text(speaking ? l.mixMatchListening : l.mixMatchListen),
        );
      },
    );
  }
}

/// The current card the child drags. Faces/bodies/situations show art; words and
/// art-less situations show large, legible text.
class _DraggableCard extends StatelessWidget {
  const _DraggableCard({required this.card, super.key});

  final MixMatchCard card;

  @override
  Widget build(BuildContext context) {
    final visual = _CardFace(card: card);
    return Draggable<MixMatchCard>(
      data: card,
      // The dragged token sits centred under the finger/cursor wherever the card
      // is grabbed — pointerDragAnchorStrategy puts the pointer at the feedback's
      // origin, and the -0.5/-0.5 shift recentres it. Shrunk to roughly a
      // bucket's mood-icon size so it reads as the small thing being dropped.
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: Material(
          color: Colors.transparent,
          child: _CardFace(card: card, size: 64),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: visual),
      child: visual,
    );
  }
}

class _CardFace extends StatelessWidget {
  const _CardFace({required this.card, this.size = 240});

  final MixMatchCard card;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final compact = size < 120;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.md),
    );

    // Text cards (short story / situation). Full size = a wide, readable card
    // the child reads and interprets; compact = a tiny drag token.
    if (card.isText) {
      return Card(
        elevation: 2,
        shape: shape,
        child: Container(
          width: compact ? size : 300,
          constraints:
              compact
                  ? BoxConstraints.tightFor(height: size)
                  : const BoxConstraints(minHeight: 140, maxHeight: 240),
          padding: EdgeInsets.all(compact ? AppSpacing.xs : AppSpacing.lg),
          alignment: Alignment.center,
          child: Text(
            card.text!,
            textAlign: TextAlign.center,
            maxLines: compact ? 3 : 8,
            overflow: TextOverflow.ellipsis,
            style:
                compact
                    ? theme.textTheme.labelSmall
                    : theme.textTheme.titleMedium,
          ),
        ),
      );
    }

    // Image cards (face / body / situation art). The card hugs the picture's
    // own shape with an even margin all round — a fixed square would leave
    // uneven gaps since every image has a different aspect ratio. The image
    // (no BoxFit) keeps its proportions, scaled to fit within [size], and the
    // Card shrink-wraps it, so the frame always looks clean and balanced.
    final pad = compact ? 2.0 : AppSpacing.md.toDouble();
    return Card(
      elevation: 2,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.all(pad),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: size - pad * 2,
            maxHeight: size - pad * 2,
          ),
          // Round the picture's own corners so it reads as a smooth card, not a
          // sharp-edged rectangle sitting inside the frame.
          child: ClipRRect(
            borderRadius: BorderRadius.circular(compact ? AppRadii.sm : AppRadii.md),
            child: Image.asset(
              card.assetPath!,
              filterQuality: FilterQuality.medium,
            ),
          ),
        ),
      ),
    );
  }
}

/// One fixed emotion drop-bucket — a clean word box (no icon) tinted with the
/// feeling's constant colour, softly highlighting while a card hovers or just
/// landed correctly.
class _EmotionBucket extends StatelessWidget {
  const _EmotionBucket({
    required this.emotion,
    required this.glow,
    required this.onAccept,
  });

  final Emotion emotion;
  final bool glow;
  final ValueChanged<MixMatchCard> onAccept;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final color = kEmotionColor[emotion]!;
    return DragTarget<MixMatchCard>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (d) => onAccept(d.data),
      builder: (context, candidate, __) {
        final hovering = candidate.isNotEmpty;
        final active = hovering || glow;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          decoration: BoxDecoration(
            color: color.withValues(alpha: active ? 0.30 : 0.12),
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(
              color: color.withValues(alpha: active ? 0.95 : 0.5),
              width: active ? 3 : 1.5,
            ),
          ),
          child: Text(
            emotionLabel(emotion, l),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        );
      },
    );
  }
}

/// Calm completion moment — no stars yet (rewards FR11 deferred). Just a warm
/// "all done" and a way back.
class _Completion extends StatelessWidget {
  const _Completion({required this.onDone});

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
              l.mixMatchDone,
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l.mixMatchDoneBody,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(onPressed: onDone, child: Text(l.mixMatchDoneButton)),
          ],
        ),
      ),
    );
  }
}
