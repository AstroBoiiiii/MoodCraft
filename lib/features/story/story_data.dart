import 'dart:math';

import '../../core/constants/app_constants.dart';
import '../../core/models/enums.dart';

/// One pause-and-ask moment in an episode (FR5). The video pauses at [atMs] and
/// asks how the character feels; [answer] is the right feeling and [feedback]
/// is the short warm line spoken when the child gets it right.
class StoryPause {
  const StoryPause({
    required this.atMs,
    required this.answer,
    required this.feedback,
  });

  final int atMs;
  final Emotion answer;
  final String feedback;
}

/// One episode of a story: its bundled video and the pause moments inside it,
/// in playback order.
class StoryEpisode {
  const StoryEpisode({required this.videoAsset, required this.pauses});

  final String videoAsset;
  final List<StoryPause> pauses;
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

/// The curated story catalogue (FR5). PLACEHOLDER CONTENT: every episode plays
/// the same stand-in clip with stand-in pause timestamps and feedback lines.
/// When the real story videos are ready, drop each mp4 under [kStoryVideoRoot]
/// and update the entry here (file name, pause timestamps, feelings, feedback);
/// nothing else in the feature changes. Titles and feedback are curated English
/// teaching content like `kQuizStorySets` (BM is the deferred FR15 pass).
const List<StoryInfo> kStoryCatalog = [
  StoryInfo(
    id: 'lost_ball',
    title: 'The Lost Ball',
    episodes: [
      StoryEpisode(
        videoAsset: '$kStoryVideoRoot/placeholder.mp4',
        pauses: [
          StoryPause(
            atMs: 3000,
            answer: Emotion.sad,
            feedback: 'His ball rolled far away. He feels sad.',
          ),
          StoryPause(
            atMs: 7000,
            answer: Emotion.happy,
            feedback: 'A friend came to help him look. He feels happy.',
          ),
        ],
      ),
      StoryEpisode(
        videoAsset: '$kStoryVideoRoot/placeholder.mp4',
        pauses: [
          StoryPause(
            atMs: 3000,
            answer: Emotion.scared,
            feedback: 'The bushes rustled in the dark. He feels scared.',
          ),
          StoryPause(
            atMs: 7000,
            answer: Emotion.surprised,
            feedback: 'The ball popped out of the bush. What a surprise!',
          ),
        ],
      ),
      StoryEpisode(
        videoAsset: '$kStoryVideoRoot/placeholder.mp4',
        pauses: [
          StoryPause(
            atMs: 3000,
            answer: Emotion.angry,
            feedback: 'Someone kicked his ball away again. He feels angry.',
          ),
          StoryPause(
            atMs: 7000,
            answer: Emotion.happy,
            feedback: 'They all played together in the end. He feels happy.',
          ),
        ],
      ),
    ],
  ),
  StoryInfo(
    id: 'new_puppy',
    title: 'The New Puppy',
    episodes: [
      StoryEpisode(
        videoAsset: '$kStoryVideoRoot/placeholder.mp4',
        pauses: [
          StoryPause(
            atMs: 3000,
            answer: Emotion.surprised,
            feedback: 'A puppy jumped out of the box. What a surprise!',
          ),
          StoryPause(
            atMs: 7000,
            answer: Emotion.happy,
            feedback: 'The puppy licked her hand. She feels happy.',
          ),
        ],
      ),
      StoryEpisode(
        videoAsset: '$kStoryVideoRoot/placeholder.mp4',
        pauses: [
          StoryPause(
            atMs: 3000,
            answer: Emotion.sad,
            feedback: 'The puppy hid under the bed all day. She feels sad.',
          ),
          StoryPause(
            atMs: 7000,
            answer: Emotion.happy,
            feedback: 'The puppy came out for a cuddle. She feels happy.',
          ),
        ],
      ),
      StoryEpisode(
        videoAsset: '$kStoryVideoRoot/placeholder.mp4',
        pauses: [
          StoryPause(
            atMs: 3000,
            answer: Emotion.scared,
            feedback: 'The thunder was very loud. The puppy feels scared.',
          ),
          StoryPause(
            atMs: 7000,
            answer: Emotion.happy,
            feedback: 'She kept the puppy safe and warm. They feel happy.',
          ),
        ],
      ),
    ],
  ),
  StoryInfo(
    id: 'big_party',
    title: 'The Big Party',
    episodes: [
      StoryEpisode(
        videoAsset: '$kStoryVideoRoot/placeholder.mp4',
        pauses: [
          StoryPause(
            atMs: 3000,
            answer: Emotion.happy,
            feedback: 'He is baking a cake with Grandma. He feels happy.',
          ),
          StoryPause(
            atMs: 7000,
            answer: Emotion.angry,
            feedback: 'His brother poked the cake and it sank. He feels angry.',
          ),
        ],
      ),
      StoryEpisode(
        videoAsset: '$kStoryVideoRoot/placeholder.mp4',
        pauses: [
          StoryPause(
            atMs: 3000,
            answer: Emotion.sad,
            feedback: 'It rained and the garden party stopped. He feels sad.',
          ),
          StoryPause(
            atMs: 7000,
            answer: Emotion.surprised,
            feedback: 'Everyone moved the party inside. What a surprise!',
          ),
        ],
      ),
      StoryEpisode(
        videoAsset: '$kStoryVideoRoot/placeholder.mp4',
        pauses: [
          StoryPause(
            atMs: 3000,
            answer: Emotion.surprised,
            feedback:
                'The lights came on and everyone cheered. What a surprise!',
          ),
          StoryPause(
            atMs: 7000,
            answer: Emotion.happy,
            feedback: 'They sang together and shared the cake. He feels happy.',
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

/// The three feeling choices for one pause: the answer plus two distractors.
/// Deterministically seeded by (story, episode, pause) so the same pause always
/// shows the same choices in the same order — predictable and consistent for
/// the child (design principle 2), with no need to persist the options.
List<Emotion> storyOptionsFor(
  String storyId,
  int level,
  int pauseIndex,
  Emotion answer,
) {
  // FNV-1a over a stable key: Object.hash/hashCode vary between app runs, and
  // the choices must look the same every single time this pause is seen.
  var seed = 0x811c9dc5;
  for (final c in '$storyId/$level/$pauseIndex'.codeUnits) {
    seed = ((seed ^ c) * 0x01000193) & 0x7fffffff;
  }
  final rng = Random(seed);
  final others =
      kStoryEmotions.where((e) => e != answer).toList()..shuffle(rng);
  return <Emotion>[answer, ...others.take(2)]..shuffle(rng);
}
