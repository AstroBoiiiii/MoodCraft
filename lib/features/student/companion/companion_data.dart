/// FR3 AI Companion — the curated teaching content. The child never learns
/// from a raw LLM (CLAUDE.md section 6): these vetted lesson scripts are the
/// core teaching, and live Gemini is only the optional chat on top.
///
/// English-only content like `kMixMatchStories` (BM is the deferred FR15 pass).
library;

import '../../../core/models/enums.dart';

/// The feelings the companion teaches (the five clear, teachable emotions;
/// `neutral` excluded). The companion keeps its own list so it never depends on
/// Mix-and-Match, the quiz, or Story Mode.
const List<Emotion> kCompanionEmotions = [
  Emotion.happy,
  Emotion.sad,
  Emotion.scared,
  Emotion.angry,
  Emotion.surprised,
];

/// One step of a lesson: a short line the companion says while showing
/// [expression] on its face. The expression is enum-keyed so the placeholder
/// face swaps for the Rive state machine later with no data change.
class CompanionLine {
  const CompanionLine(this.expression, this.text);

  final Emotion expression;
  final String text;
}

/// Vetted lesson script per feeling (FR3: teach the emotion via face + body).
/// Each lesson walks the same gentle shape so the flow stays predictable:
/// what the feeling is, what the face does, what the body does, then a tiny
/// example and an invite to try the face. Short sentences, no negativity.
const Map<Emotion, List<CompanionLine>> kCompanionLessons = {
  Emotion.happy: [
    CompanionLine(Emotion.happy, 'Happy is a warm, good feeling.'),
    CompanionLine(
      Emotion.happy,
      'When I am happy, I smile big. My eyes go soft and crinkly.',
    ),
    CompanionLine(
      Emotion.happy,
      'My body feels light. Sometimes I clap or give a little jump.',
    ),
    CompanionLine(
      Emotion.happy,
      'Playing with a friend can make me happy. Can you show me your happy face?',
    ),
  ],
  Emotion.sad: [
    CompanionLine(Emotion.sad, 'Sad is a heavy, quiet feeling.'),
    CompanionLine(
      Emotion.sad,
      'When I am sad, my mouth turns down. My eyes might have tears.',
    ),
    CompanionLine(
      Emotion.sad,
      'My body goes slow and droopy. My head hangs down.',
    ),
    CompanionLine(
      Emotion.sad,
      'Losing a toy can make me sad. It is okay to feel sad. Can you show me a sad face?',
    ),
  ],
  Emotion.scared: [
    CompanionLine(Emotion.scared, 'Scared is a jumpy, shaky feeling.'),
    CompanionLine(
      Emotion.scared,
      'When I am scared, my eyes go big and wide. My mouth opens a little.',
    ),
    CompanionLine(
      Emotion.scared,
      'My body goes stiff and still. I might hide or hold something tight.',
    ),
    CompanionLine(
      Emotion.scared,
      'A loud noise can make me scared. A big hug helps. Can you show me a scared face?',
    ),
  ],
  Emotion.angry: [
    CompanionLine(Emotion.angry, 'Angry is a hot, tight feeling.'),
    CompanionLine(
      Emotion.angry,
      'When I am angry, my eyebrows push down. My face scrunches up.',
    ),
    CompanionLine(
      Emotion.angry,
      'My body goes tight. My hands might squeeze into fists.',
    ),
    CompanionLine(
      Emotion.angry,
      'A broken tower can make me angry. Slow breaths help me feel calm again. Can you show me an angry face?',
    ),
  ],
  Emotion.surprised: [
    CompanionLine(Emotion.surprised, 'Surprised is a quick, popping feeling.'),
    CompanionLine(
      Emotion.surprised,
      'When I am surprised, my eyes go round. My mouth makes a big O.',
    ),
    CompanionLine(
      Emotion.surprised,
      'My body gives a little jump. My hands might fly up.',
    ),
    CompanionLine(
      Emotion.surprised,
      'A balloon going pop can surprise me. Can you show me a surprised face?',
    ),
  ],
};
