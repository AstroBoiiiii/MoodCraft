import 'dart:math';

import '../../core/constants/app_constants.dart';
import '../../core/models/enums.dart';
import '../../core/models/student.dart';

/// One pause-and-ask moment in an episode (FR5). The video pauses at [atMs] and
/// asks [ask] — the question names who to think about (the boy, the puppy), so
/// the child always knows whose feeling is being asked. [answer] is the right
/// feeling and [feedback] is the short warm line shown when the child gets it
/// right (story mode is read-only: no narration, just short friendly text).
class StoryPause {
  const StoryPause({
    required this.atMs,
    required this.ask,
    required this.answer,
    required this.feedback,
    this.avoidOptions = const [],
  });

  final int atMs;
  final String ask;
  final Emotion answer;
  final String feedback;

  /// Emotions to keep out of this pause's three choices, even though they are
  /// valid feelings elsewhere. Used when a distractor would be confusing or too
  /// close to the answer for this particular moment, or to pin the choices to a
  /// specific pair (empty = no restriction).
  final List<Emotion> avoidOptions;
}

/// One episode of a story: a segment of its bundled video ([startMs] up to
/// [endMs], or the natural end of the file when [endMs] is null) and the pause
/// moments inside it, in playback order. All timestamps, pauses included, are
/// absolute positions in the video file, so one continuous film can be carved
/// into episodes with no editing.
class StoryEpisode {
  const StoryEpisode({
    required this.videoAsset,
    required this.pauses,
    this.startMs = 0,
    this.endMs,
  });

  final String videoAsset;
  final List<StoryPause> pauses;
  final int startMs;
  final int? endMs;
}

/// A cartoon story (FR5): [kStoryEpisodeCount] episodes that continue one plot,
/// watched in order like a little series.
class StoryInfo {
  const StoryInfo({
    required this.id,
    required this.title,
    required this.episodes,
  });

  final String id;
  final String title;
  final List<StoryEpisode> episodes;
}

/// The curated story catalogue (FR5). Three stories are wired: "The Present"
/// (`the_present.mp4`), "Watermelon" (`watermelon.mp4`) and "Pip"
/// (`pip.mp4`), each a single continuous film carved into three episodes by
/// start/end timestamps. Titles, asks and feedback are curated English
/// teaching content like `kQuizStorySets` (BM is the deferred FR15 pass); keep
/// the lines short and easy for the child to read.
const List<StoryInfo> kStoryCatalog = [
  StoryInfo(
    id: 'the_present',
    title: 'The Present',
    episodes: [
      // Episode 1 — Mom's surprise gift (0:07.5 to 1:00).
      StoryEpisode(
        videoAsset: '$kStoryVideoRoot/the_present.mp4',
        startMs: 7500,
        endMs: 60000,
        pauses: [
          StoryPause(
            atMs: 29000,
            ask: 'How does the boy feel?',
            answer: Emotion.surprised,
            feedback: 'He is shocked by the surprise from Mom.',
          ),
          StoryPause(
            atMs: 59000,
            ask: 'How does the boy feel?',
            answer: Emotion.happy,
            feedback: 'He is happy to receive a puppy as a gift.',
            avoidOptions: [Emotion.surprised],
          ),
        ],
      ),
      // Episode 2 — the puppy is pushed away (1:00 to 1:52).
      StoryEpisode(
        videoAsset: '$kStoryVideoRoot/the_present.mp4',
        startMs: 60000,
        endMs: 112000,
        pauses: [
          StoryPause(
            atMs: 70000,
            ask: 'How does the boy feel?',
            answer: Emotion.angry,
            feedback: 'He is mad the puppy has a missing leg.',
          ),
          StoryPause(
            atMs: 110600,
            ask: 'How does the puppy feel?',
            answer: Emotion.angry,
            feedback: 'The grumpy puppy is mad because it tumbled over.',
            avoidOptions: [Emotion.sad, Emotion.surprised],
          ),
        ],
      ),
      // Episode 3 — warmth wins (1:52 to the end of the story at 3:22; the
      // last ask sits just before the cut so the gift's warm ending lands).
      StoryEpisode(
        videoAsset: '$kStoryVideoRoot/the_present.mp4',
        startMs: 112000,
        endMs: 202000,
        pauses: [
          StoryPause(
            atMs: 162000,
            ask: 'How does the boy feel?',
            answer: Emotion.happy,
            feedback: 'The puppy won him over. He feels happy.',
          ),
          StoryPause(
            atMs: 201000,
            ask: 'How does the boy feel about his gift?',
            answer: Emotion.happy,
            feedback: 'He loves his gift. He feels warm and happy.',
          ),
        ],
      ),
    ],
  ),
  StoryInfo(
    id: 'watermelon',
    title: 'Watermelon',
    episodes: [
      // Episode 1 — the sweet treat turns strange (0:03 to 0:56).
      StoryEpisode(
        videoAsset: '$kStoryVideoRoot/watermelon.mp4',
        startMs: 3000,
        endMs: 56000,
        pauses: [
          StoryPause(
            atMs: 21500,
            ask: 'How does the boy feel about eating the watermelon?',
            answer: Emotion.happy,
            feedback: 'The watermelon is sweet and yummy. He feels happy.',
          ),
          StoryPause(
            atMs: 55000,
            ask: 'How does the boy feel?',
            answer: Emotion.scared,
            feedback: 'A watermelon is growing on his body. He feels scared.',
          ),
        ],
      ),
      // Episode 2 — a loud class and a slippery floor (0:56 to 1:56).
      StoryEpisode(
        videoAsset: '$kStoryVideoRoot/watermelon.mp4',
        startMs: 56000,
        endMs: 116000,
        pauses: [
          StoryPause(
            atMs: 71000,
            ask: 'How does the boy feel?',
            answer: Emotion.scared,
            feedback: 'The teacher is about to scold him. He feels scared.',
          ),
          StoryPause(
            atMs: 116000,
            ask: 'How does the boy feel sliding around?',
            answer: Emotion.happy,
            feedback: 'Sliding around is so much fun. He feels happy.',
          ),
        ],
      ),
      // Episode 3 — the race and what comes next (1:56 to 2:39, just past the
      // last ask, so the episode ends there rather than rolling into the
      // credits scene).
      StoryEpisode(
        videoAsset: '$kStoryVideoRoot/watermelon.mp4',
        startMs: 116000,
        endMs: 159000,
        pauses: [
          StoryPause(
            atMs: 131000,
            ask: 'How does the boy feel about winning the race?',
            answer: Emotion.happy,
            feedback: 'He won the race. He feels happy and proud.',
          ),
          StoryPause(
            atMs: 158000,
            ask: 'How do you feel about what happens next?',
            answer: Emotion.scared,
            feedback:
                'Everyone who ate the watermelon will grow one too. That feels scary.',
          ),
        ],
      ),
    ],
  ),
  StoryInfo(
    id: 'pip',
    title: 'Pip',
    episodes: [
      // Episode 1 — Pip's exam day (0:03 to 0:56).
      StoryEpisode(
        videoAsset: '$kStoryVideoRoot/pip.mp4',
        startMs: 3000,
        endMs: 56000,
        pauses: [
          StoryPause(
            atMs: 38000,
            ask: 'How does the dog feel?',
            answer: Emotion.surprised,
            feedback:
                'Someone suddenly appeared in front of him. He feels surprised.',
          ),
          StoryPause(
            atMs: 55500,
            ask: 'How does the dog feel?',
            answer: Emotion.happy,
            feedback: 'He passed and is now qualified. He feels happy.',
          ),
        ],
      ),
      // Episode 2 — hard training and a rough exam (0:56 to 2:27).
      StoryEpisode(
        videoAsset: '$kStoryVideoRoot/pip.mp4',
        startMs: 56000,
        endMs: 147000,
        pauses: [
          StoryPause(
            atMs: 91500,
            ask: 'How does the dog feel about his training?',
            answer: Emotion.sad,
            feedback: 'His training is not going well. He feels sad.',
          ),
          StoryPause(
            atMs: 146500,
            ask: 'How does the dog feel about the exam?',
            answer: Emotion.sad,
            feedback: 'The exam did not go well. He feels sad.',
          ),
        ],
      ),
      // Episode 3 — a setback, then the happy ending (2:27 to 3:39; the story
      // ends right after the last ask instead of running into whatever footage
      // follows in the raw file).
      StoryEpisode(
        videoAsset: '$kStoryVideoRoot/pip.mp4',
        startMs: 147000,
        endMs: 219000,
        pauses: [
          StoryPause(
            atMs: 166500,
            ask: 'How does the dog feel?',
            answer: Emotion.sad,
            feedback: 'He did not get picked to be a helper dog. He feels sad.',
          ),
          StoryPause(
            atMs: 218000,
            ask: 'How does the dog feel in the end?',
            answer: Emotion.happy,
            feedback: 'He finally gets to be a helper dog. He feels happy.',
          ),
        ],
      ),
    ],
  ),
];

/// Looks a story up by id, or null if the id is unknown (defensive — a stale
/// saved progress key must never crash play).
StoryInfo? storyById(String id) {
  for (final s in kStoryCatalog) {
    if (s.id == id) return s;
  }
  return null;
}

/// Full length of each bundled film (its raw file duration), used only as a
/// fallback so the picker can show an accurate length for a story's final
/// episode if it ever plays to the file's natural end rather than a hard cut
/// (`StoryEpisode.endMs == null`; every episode in `kStoryCatalog` currently
/// has an explicit `endMs` — each story cuts cleanly at its last ask rather
/// than rolling into any credits scene, so this fallback sits ready for any
/// future episode authored without one). Playback itself never needs this: a
/// null `endMs` already means "play to the natural end" either way (see
/// `story_play_screen.dart`'s `_controlsRow`, which reads the real duration
/// live from the video controller instead) — this exists purely so the picker
/// doesn't have to load every video just to read its length. Keep in sync
/// with the actual asset if a film is replaced.
const Map<String, int> kStoryVideoDurationMs = {
  '$kStoryVideoRoot/the_present.mp4': 258000,
  '$kStoryVideoRoot/watermelon.mp4': 164000,
  '$kStoryVideoRoot/pip.mp4': 245000,
};

/// The exact length of [episode] as actually shown to the child, i.e. its own
/// segment of the film (`startMs` to `endMs`) — never the whole raw file's
/// duration, which for every episode but a story's last is longer than what
/// plays. Falls back to [kStoryVideoDurationMs] when the episode has no
/// `endMs` of its own.
int storyEpisodeDurationMs(StoryEpisode episode) {
  final end = episode.endMs ?? kStoryVideoDurationMs[episode.videoAsset] ?? 0;
  return (end - episode.startMs).clamp(0, 1 << 31);
}

/// A story's total watch time: the sum of its episodes' shown durations (not
/// the raw file length, which may run past where the last episode ends).
int storyTotalDurationMs(StoryInfo story) =>
    story.episodes.fold(0, (sum, e) => sum + storyEpisodeDurationMs(e));

/// Formats a duration in milliseconds as a calm "m:ss" caption (e.g. "1:05"),
/// rounded to the nearest second — for showing "how long is this" without a
/// frame-exact number that means nothing to a child or a busy parent/teacher.
String formatStoryDuration(int ms) {
  final totalSeconds = (ms / 1000).round();
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

/// Whether [student] has finished every episode of every story (FR5/FR11). This
/// is the "all done" check that earns the completed badge: for each story in the
/// catalogue, its saved progress reports all its episodes done.
bool storyAllComplete(Student student) => kStoryCatalog.every((story) {
  final done = student.storyProgress[story.id]?.levelsDone ?? 0;
  return done >= story.episodes.length;
});

/// The three feeling choices for one pause: the answer plus two distractors.
/// Deterministically seeded by (story, episode, pause) so the same pause always
/// shows the same choices in the same order — predictable and consistent for
/// the child (design principle 2), with no need to persist the options.
List<Emotion> storyOptionsFor(
  String storyId,
  int level,
  int pauseIndex,
  Emotion answer, {
  List<Emotion> avoid = const [],
}) {
  // FNV-1a over a stable key: Object.hash/hashCode vary between app runs, and
  // the choices must look the same every single time this pause is seen.
  var seed = 0x811c9dc5;
  for (final c in '$storyId/$level/$pauseIndex'.codeUnits) {
    seed = ((seed ^ c) * 0x01000193) & 0x7fffffff;
  }
  final rng = Random(seed);
  final others =
      kStoryEmotions.where((e) => e != answer && !avoid.contains(e)).toList()
        ..shuffle(rng);
  return <Emotion>[answer, ...others.take(2)]..shuffle(rng);
}
