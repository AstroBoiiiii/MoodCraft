import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moodcraft/l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';

import '../../app/theme/tokens.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/enums.dart';
import '../../core/models/session.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/providers/sensory_settings_provider.dart';
import '../../core/widgets/calm_scaffold.dart';
import '../../core/widgets/narrated_text.dart';
import '../journal/journal_section.dart' show emotionLabel;
import 'mix_match_data.dart';

/// FR6 — one Mix-and-Match round. The six emotions are fixed drop-buckets in the
/// same spots every time (predictable layout, CLAUDE.md section 4.2). The child
/// drags the current card onto the matching feeling. A wrong drop is a calm,
/// no-penalty redirect — the card simply stays for another try. There is no
/// timer, no score shown, no fail state.
///
/// [studentId] null = teacher "classroom" mode (projection): plays the same
/// round but writes no session and bumps no progress — it's a group demo, not
/// one child's record.
class MixMatchPlayScreen extends ConsumerStatefulWidget {
  const MixMatchPlayScreen({required this.type, this.studentId, super.key});

  final MixMatchType type;
  final String? studentId;

  @override
  ConsumerState<MixMatchPlayScreen> createState() => _MixMatchPlayScreenState();
}

class _MixMatchPlayScreenState extends ConsumerState<MixMatchPlayScreen> {
  static const int _roundSize = 5;
  static const _emotions = Emotion.values;

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
  }

  Future<void> _load() async {
    final deck = await buildMixMatchDeck(widget.type, count: _roundSize);
    if (!mounted) return;
    setState(() {
      _deck = deck;
      _startedAt = DateTime.now();
    });
  }

  bool get _done => _deck != null && _index >= _deck!.length;

  void _onDrop(MixMatchCard card, Emotion bucket) {
    if (bucket == card.answer) {
      if (!_missedCurrent) _firstTryCorrect++;
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
    final repo = ref.read(studentRepositoryProvider);
    try {
      await ref.read(sessionRepositoryProvider).add(session);
      // Unlock the next level: mixMatchLevel = highest unlocked type index.
      final student = await repo.getStudent(studentId);
      if (student != null) {
        final unlocked = widget.type.index + 1;
        if (student.mixMatchLevel < unlocked) {
          await repo.upsert(student.copyWith(mixMatchLevel: unlocked));
        }
      }
    } catch (_) {
      // Offline/transient — Firestore cache will sync later (FR14). The child's
      // calm "all done" moment never depends on the write succeeding.
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
            NarratedText(
              _nudge ? l.mixMatchTryAgain : l.mixMatchPrompt,
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
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              flex: 4,
              child: GridView.count(
                crossAxisCount: 3,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppSpacing.sm,
                crossAxisSpacing: AppSpacing.sm,
                childAspectRatio: 1.0,
                children: [
                  for (final emotion in _emotions)
                    _EmotionBucket(
                      emotion: emotion,
                      glow: _justAccepted == emotion,
                      onAccept: (c) => _onDrop(c, emotion),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
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
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(width: 180, height: 180, child: _CardFace(card: card)),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: visual),
      child: visual,
    );
  }
}

class _CardFace extends StatelessWidget {
  const _CardFace({required this.card});

  final MixMatchCard card;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Container(
        width: 180,
        height: 180,
        padding: const EdgeInsets.all(AppSpacing.md),
        alignment: Alignment.center,
        child:
            card.isText
                ? Text(
                  card.text!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall,
                )
                : ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  child: Image.asset(card.assetPath!, fit: BoxFit.contain),
                ),
      ),
    );
  }
}

/// One fixed emotion drop-bucket. Tints with the emotion's constant colour and
/// softly highlights while a card hovers or just landed correctly.
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
        return Container(
          decoration: BoxDecoration(
            color: color.withValues(alpha: active ? 0.32 : 0.14),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: color.withValues(alpha: active ? 0.9 : 0.4),
              width: active ? 2.5 : 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(kEmotionIcon[emotion], size: 34, color: color),
              const SizedBox(height: AppSpacing.xs),
              Text(
                emotionLabel(emotion, l),
                textAlign: TextAlign.center,
                style: theme.textTheme.labelLarge,
              ),
            ],
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
