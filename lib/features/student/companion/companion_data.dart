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

/// Words a child might use for each feeling. The teaching brain's offline
/// fallback (and any local pre-check) accepts these as a correct answer, so a
/// child saying "mad" for angry is never told otherwise just because the
/// device lost its connection.
const Map<Emotion, List<String>> kCompanionSynonyms = {
  Emotion.happy: ['happy', 'glad', 'joy', 'joyful', 'smiling', 'good'],
  Emotion.sad: ['sad', 'unhappy', 'crying', 'cry', 'down', 'upset'],
  Emotion.scared: [
    'scared',
    'afraid',
    'frightened',
    'fear',
    'scary',
    'terrified',
  ],
  Emotion.angry: ['angry', 'mad', 'cross', 'grumpy', 'furious'],
  Emotion.surprised: [
    'surprised',
    'surprise',
    'shocked',
    'shock',
    'wow',
    'startled',
  ],
  Emotion.neutral: ['okay', 'ok', 'fine', 'calm', 'neutral'],
};

/// One short body-language clue per feeling, used for the gentle redirect when
/// the child has not spotted it yet ("Good try. Look again..."). The clues
/// describe the body, not the face: on the 3D stage the Mixamo pose is what
/// the child can actually see, so each line matches that clip.
const Map<Emotion, String> kCompanionRedirectClue = {
  Emotion.happy: 'Look at my arms open wide.',
  Emotion.sad: 'Look at my head hanging down.',
  Emotion.scared: 'Look at how I hold myself small and tight.',
  Emotion.angry: 'Look at my crossed arms.',
  Emotion.surprised: 'Look at how I lean back quickly.',
  Emotion.neutral: 'Look at how calm and still I am.',
};

/// One step of a lesson: a short line the companion says while showing
/// [expression]. The expression is enum-keyed so the stage can act it out.
/// A line with [focusFace] talks about the face, so the 3D stage zooms the
/// camera to the avatar's head while it is spoken and pulls back to full
/// body afterwards.
class CompanionLine {
  const CompanionLine(this.expression, this.text, {this.focusFace = false});

  final Emotion expression;
  final String text;
  final bool focusFace;
}

/// Vetted lesson script per feeling (FR3: teach the emotion via face + body).
/// Each lesson walks the same gentle shape so the flow stays predictable:
/// what the feeling is, what the face does (the stage zooms to the head for
/// that line), what the body does, then an everyday example ending with a
/// question back to the child — the chat is there to hear their answer once
/// the lesson is done. Short sentences, no negativity, and no "show me your
/// face" asks: there is no camera or face recognition anywhere in the app.
const Map<Emotion, List<CompanionLine>> kCompanionLessons = {
  Emotion.happy: [
    CompanionLine(Emotion.happy, 'Happy is a warm, good feeling.'),
    CompanionLine(
      Emotion.happy,
      'Look at my face. My smile is big and my eyes go soft and crinkly.',
      focusFace: true,
    ),
    CompanionLine(Emotion.happy, 'My body feels light. My arms open up wide.'),
    CompanionLine(
      Emotion.happy,
      'Playing with a friend at school can make me happy. What makes you happy?',
    ),
  ],
  Emotion.sad: [
    CompanionLine(Emotion.sad, 'Sad is a heavy, quiet feeling.'),
    CompanionLine(
      Emotion.sad,
      'Look at my face. My mouth turns down. My eyes might have tears.',
      focusFace: true,
    ),
    CompanionLine(
      Emotion.sad,
      'My body goes slow and droopy. My head hangs down.',
    ),
    CompanionLine(
      Emotion.sad,
      'Losing a toy can make me sad. It is okay to feel sad. What makes you feel sad?',
    ),
  ],
  Emotion.scared: [
    CompanionLine(Emotion.scared, 'Scared is a jumpy, shaky feeling.'),
    CompanionLine(
      Emotion.scared,
      'Look at my face. My eyes go big and wide. My mouth opens a little.',
      focusFace: true,
    ),
    CompanionLine(
      Emotion.scared,
      'My body goes small and tight. I hold myself close.',
    ),
    CompanionLine(
      Emotion.scared,
      'A loud noise at school can make me scared. A big hug helps. What feels scary to you?',
    ),
  ],
  Emotion.angry: [
    CompanionLine(Emotion.angry, 'Angry is a hot, tight feeling.'),
    CompanionLine(
      Emotion.angry,
      'Look at my face. My eyebrows push down and my face scrunches up.',
      focusFace: true,
    ),
    CompanionLine(Emotion.angry, 'My body goes tight. My arms cross hard.'),
    CompanionLine(
      Emotion.angry,
      'A broken tower can make me angry. Slow breaths help me feel calm again. What makes you angry?',
    ),
  ],
  Emotion.surprised: [
    CompanionLine(Emotion.surprised, 'Surprised is a quick, popping feeling.'),
    CompanionLine(
      Emotion.surprised,
      'Look at my face. My eyes go round. My mouth makes a big O.',
      focusFace: true,
    ),
    CompanionLine(
      Emotion.surprised,
      'My body gives a little jump and leans back quickly.',
    ),
    CompanionLine(
      Emotion.surprised,
      'A balloon going pop can surprise me. What surprised you today?',
    ),
  ],
};
