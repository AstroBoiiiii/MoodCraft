import 'dart:math';

import 'package:flutter/services.dart' show AssetManifest, rootBundle;

import '../../core/constants/app_constants.dart';
import '../../core/models/emotion_content.dart';
import '../../core/models/enums.dart';
import '../../core/models/quiz_round.dart';
import '../../core/models/student.dart';

/// Whether [student] has finished all [kQuizSetCount] daily quiz sets
/// (FR7/FR11). This is the "all done" check that earns the completed badge: a
/// finished round saved for every set index.
bool quizAllComplete(Student student) => List.generate(
  kQuizSetCount,
  (i) => student.quizRounds['$i']?.isComplete ?? false,
).every((done) => done);

/// One quiz question. The child taps one of [options]; [answer] is the right
/// feeling. There is no score — a right tap shows/speaks [feedback], a wrong tap
/// is a calm "look again" with another try (see QuizPlayScreen). [QuizModality]
/// lives in `enums.dart` so the persisted [QuizRound] can name it too.
class QuizQuestion {
  const QuizQuestion({
    required this.id,
    required this.modality,
    required this.answer,
    required this.options,
    required this.feedback,
    this.assetPath,
    this.text,
  });

  final String id;
  final QuizModality modality;

  /// The correct feeling.
  final Emotion answer;

  /// The feeling choices shown — always includes [answer]; already shuffled.
  final List<Emotion> options;

  /// Short warm line shown and spoken when the child gets it right.
  final String feedback;

  /// Image (look) or sound-clip (listen) asset path.
  final String? assetPath;

  /// Short scenario read aloud (story).
  final String? text;
}

/// A pool entry before its answer choices are drawn.
typedef _Cand =
    ({
      QuizModality modality,
      Emotion answer,
      String? assetPath,
      String? text,
      String feedback,
    });

/// The fixed, curated arrangement for each daily set: an ordered list of
/// `(feeling, way of asking)` pairs. Every set asks each of the five feelings
/// exactly once (so no feeling repeats inside a round), with the three ways of
/// asking interleaved. The plan is laid out so **no face, sound, or story is
/// reused across the three sets**: each feeling's single sound cue is a "listen"
/// question in just one set, and a feeling is a "look" question in just one set.
/// Stories are already per-day. This makes the three days genuinely distinct and
/// keeps each round predictable and consistent (CLAUDE.md design principle 2).
const List<List<(Emotion, QuizModality)>> _setPlan = [
  // Set 1 — listen: happy, sad; look: scared; story: angry, surprised.
  [
    (Emotion.scared, QuizModality.look),
    (Emotion.happy, QuizModality.listen),
    (Emotion.angry, QuizModality.story),
    (Emotion.sad, QuizModality.listen),
    (Emotion.surprised, QuizModality.story),
  ],
  // Set 2 — listen: scared, angry; look: happy, surprised; story: sad.
  [
    (Emotion.happy, QuizModality.look),
    (Emotion.scared, QuizModality.listen),
    (Emotion.sad, QuizModality.story),
    (Emotion.angry, QuizModality.listen),
    (Emotion.surprised, QuizModality.look),
  ],
  // Set 3 — listen: surprised; look: sad, angry; story: happy, scared.
  [
    (Emotion.sad, QuizModality.look),
    (Emotion.happy, QuizModality.story),
    (Emotion.angry, QuizModality.look),
    (Emotion.surprised, QuizModality.listen),
    (Emotion.scared, QuizModality.story),
  ],
];

/// Builds one curated, mixed round of [count] questions for the daily [setIndex]
/// (0..[kQuizSetCount]).
///
/// The arrangement is fixed per set (see [_setPlan]): the round asks every
/// feeling once, interleaves the three ways of asking, and reuses no face, sound
/// or story across sets, so replaying a day gives the same calm round and the
/// three days stay distinct. Content is still auto-discovered/drop-in: "look"
/// faces from [kQuizLookRoot], "listen" cues from [kQuizCueFolder], "story"
/// scenarios from `kQuizStorySets[setIndex]`. If a planned way of asking has no
/// art for a feeling it gently falls back to another way that does; if nothing
/// is available the round is empty and the demo never breaks. [random] only
/// shuffles each question's answer choices, never the arrangement.
Future<List<QuizQuestion>> buildQuizDeck({
  required int setIndex,
  int count = kQuizRoundSize,
  Random? random,
}) async {
  final rng = random ?? Random();
  final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
  final assets = manifest.listAssets();

  final looks = _looksByEmotion(assets);
  final listens = _listensByEmotion(assets);
  final stories = _storiesByEmotion(setIndex);

  final out = <QuizQuestion>[];
  final usedContent = <String>{};

  // Follow the plan: each planned way of asking, falling back to another way
  // that has content for that feeling (story -> look -> listen) if art is missing.
  const fallback = [QuizModality.story, QuizModality.look, QuizModality.listen];
  for (final (emotion, preferred) in _planFor(setIndex)) {
    if (out.length >= count) break;
    final order = [preferred, ...fallback.where((m) => m != preferred)];
    for (final m in order) {
      final cand = _candidate(emotion, m, setIndex, looks, listens, stories);
      if (cand == null || usedContent.contains(_contentKey(cand))) continue;
      out.add(_finalize(cand, out.length, rng));
      usedContent.add(_contentKey(cand));
      break;
    }
  }

  // Safety top-up for an unusually empty content set: fill any remaining slots
  // from unused candidates, relaxing the one-per-feeling rule as a last resort.
  if (out.length < count) {
    for (final c in _allCandidates(setIndex, looks, listens, stories)) {
      if (out.length >= count) break;
      if (usedContent.contains(_contentKey(c))) continue;
      out.add(_finalize(c, out.length, rng));
      usedContent.add(_contentKey(c));
    }
  }
  return out;
}

/// The arrangement for [setIndex], wrapping any out-of-range index back into the
/// available sets so the call is always safe.
List<(Emotion, QuizModality)> _planFor(int setIndex) {
  if (_setPlan.isEmpty) return const [];
  final i = setIndex % _setPlan.length;
  return _setPlan[i < 0 ? i + _setPlan.length : i];
}

/// Builds the candidate for one (feeling, way of asking), or null if there is no
/// content for it. A feeling's face uses the [setIndex]th variation so the same
/// feeling can show a different picture on different days.
_Cand? _candidate(
  Emotion e,
  QuizModality m,
  int setIndex,
  Map<Emotion, List<String>> looks,
  Map<Emotion, List<String>> listens,
  Map<Emotion, ({String text, String feedback})> stories,
) {
  switch (m) {
    case QuizModality.look:
      final paths = looks[e];
      if (paths == null || paths.isEmpty) return null;
      return (
        modality: QuizModality.look,
        answer: e,
        assetPath: paths[setIndex.abs() % paths.length],
        text: null,
        feedback: kQuizLookFeedback[e] ?? kQuizFeedback[e] ?? '',
      );
    case QuizModality.listen:
      final paths = listens[e];
      if (paths == null || paths.isEmpty) return null;
      return (
        modality: QuizModality.listen,
        answer: e,
        assetPath: paths.first,
        text: null,
        feedback: kQuizListenFeedback[e] ?? kQuizFeedback[e] ?? '',
      );
    case QuizModality.story:
      final s = stories[e];
      if (s == null) return null;
      return (
        modality: QuizModality.story,
        answer: e,
        assetPath: null,
        text: s.text,
        feedback: s.feedback.isNotEmpty ? s.feedback : (kQuizFeedback[e] ?? ''),
      );
  }
}

/// Every available candidate across all feelings and ways of asking, used only
/// as the last-resort top-up when planned content is missing.
List<_Cand> _allCandidates(
  int setIndex,
  Map<Emotion, List<String>> looks,
  Map<Emotion, List<String>> listens,
  Map<Emotion, ({String text, String feedback})> stories,
) {
  final out = <_Cand>[];
  for (final e in kQuizEmotions) {
    for (final m in QuizModality.values) {
      final c = _candidate(e, m, setIndex, looks, listens, stories);
      if (c != null) out.add(c);
    }
  }
  return out;
}

/// Identifies a candidate by its actual content (modality + image/sound/story),
/// so the same picture or clip never appears twice in one round.
String _contentKey(_Cand c) =>
    '${c.modality.name}:${c.assetPath ?? c.text ?? ''}';

/// Wraps a chosen candidate into a question, drawing its answer choices.
QuizQuestion _finalize(_Cand c, int index, Random rng) => QuizQuestion(
  id: '${c.modality.name}_${c.answer.name}_$index',
  modality: c.modality,
  answer: c.answer,
  options: _optionsFor(c.answer, rng),
  feedback: c.feedback,
  assetPath: c.assetPath,
  text: c.text,
);

/// Rebuilds the playable deck from a saved round so the child resumes the exact
/// same questions in the same order (the unanswered ones are
/// `questions[round.answered..]`).
List<QuizQuestion> deckFromRound(QuizRound round) => [
  for (var i = 0; i < round.questions.length; i++)
    QuizQuestion(
      id: 'saved_$i',
      modality: round.questions[i].modality,
      answer: round.questions[i].answer,
      options: round.questions[i].options,
      feedback: round.questions[i].feedback,
      assetPath: round.questions[i].assetPath,
      text: round.questions[i].text,
    ),
];

/// Snapshots the current deck + how many are answered into a savable round.
QuizRound roundFromDeck(List<QuizQuestion> deck, int answered) => QuizRound(
  answered: answered,
  questions: [
    for (final q in deck)
      QuizRoundQuestion(
        modality: q.modality,
        answer: q.answer,
        options: q.options,
        feedback: q.feedback,
        assetPath: q.assetPath,
        text: q.text,
      ),
  ],
);

/// Three feeling choices: the answer plus two distinct distractors, shuffled.
List<Emotion> _optionsFor(Emotion answer, Random rng) {
  final others = kQuizEmotions.where((e) => e != answer).toList()..shuffle(rng);
  return <Emotion>[answer, ...others.take(2)]..shuffle(rng);
}

/// Discovers the shared "look" faces, grouped by feeling and sorted by filename
/// so a feeling's variations have a stable order (`happy_1`, `happy_2`, ...).
/// The leading `<emotion>` filename token is the answer; unknown tokens or
/// feelings outside [kQuizEmotions] are skipped.
Map<Emotion, List<String>> _looksByEmotion(List<String> assets) {
  final out = <Emotion, List<String>>{};
  final paths =
      assets.where((p) => p.startsWith('$kQuizLookRoot/')).toList()..sort();
  for (final path in paths) {
    final e = _emotionFromPath(path);
    if (e == null || !kQuizEmotions.contains(e)) continue;
    (out[e] ??= <String>[]).add(path);
  }
  return out;
}

/// Discovers the shared "listen" sound cues, grouped by feeling and sorted by
/// filename; the leading `<emotion>` token is the answer.
Map<Emotion, List<String>> _listensByEmotion(List<String> assets) {
  final out = <Emotion, List<String>>{};
  final paths =
      assets.where((p) => p.startsWith('$kQuizCueFolder/')).toList()..sort();
  for (final path in paths) {
    final e = _emotionFromPath(path);
    if (e == null || !kQuizEmotions.contains(e)) continue;
    (out[e] ??= <String>[]).add(path);
  }
  return out;
}

/// The day's curated story scenarios, grouped by feeling, each with its own
/// tailored spoken feedback.
Map<Emotion, ({String text, String feedback})> _storiesByEmotion(int setIndex) {
  final stories =
      (setIndex >= 0 && setIndex < kQuizStorySets.length)
          ? kQuizStorySets[setIndex]
          : const <EmotionContent>[];
  final out = <Emotion, ({String text, String feedback})>{};
  for (final c in stories) {
    if (!kQuizEmotions.contains(c.emotion)) continue;
    out[c.emotion] = (text: c.prompt, feedback: c.feedback);
  }
  return out;
}

/// Parses the leading `<emotion>` token from an asset filename, ignoring the
/// extension, e.g. `.../happy_1.png` or `.../happy.mp3` -> Emotion.happy.
/// Returns null if unrecognised.
Emotion? _emotionFromPath(String path) {
  var file = path.split('/').last;
  final dot = file.lastIndexOf('.');
  if (dot > 0) file = file.substring(0, dot);
  final token = file.split('_').first.toLowerCase();
  for (final e in Emotion.values) {
    if (e.name == token) return e;
  }
  return null;
}
