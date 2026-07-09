import 'package:flutter_test/flutter_test.dart';
import 'package:moodcraft/core/constants/app_constants.dart';
import 'package:moodcraft/features/story/story_data.dart';

/// FR5 — the episode/story durations shown on the picker must reflect the
/// segment actually played (`startMs` to `endMs`), never the whole raw film,
/// and the "natural end" episode (no `endMs`) must fall back to the film's
/// own total length rather than reading as 0.
void main() {
  test('formatStoryDuration renders m:ss, padding seconds', () {
    expect(formatStoryDuration(53000), '0:53');
    expect(formatStoryDuration(60000), '1:00');
    expect(formatStoryDuration(90000), '1:30');
    expect(formatStoryDuration(5000), '0:05');
  });

  test(
    'an episode with an explicit endMs uses its own segment, not the raw file',
    () {
      final story = storyById('the_present')!;
      // Episode 1: startMs 7500, endMs 60000 -> 52500ms, not the film's 258000ms.
      expect(storyEpisodeDurationMs(story.episodes[0]), 52500);
    },
  );

  test('an episode authored without an endMs falls back to the film\'s total '
      'length (every current story cuts cleanly at its last ask instead, but '
      'the fallback still has to hold for any future one that does not)', () {
    const videoAsset = '$kStoryVideoRoot/the_present.mp4';
    const episode = StoryEpisode(
      videoAsset: videoAsset,
      startMs: 200000,
      pauses: [],
    );
    final expected = kStoryVideoDurationMs[videoAsset]! - episode.startMs;
    expect(storyEpisodeDurationMs(episode), expected);
    expect(expected, greaterThan(0));
  });

  test('a story total is the sum of its episodes, not the raw file length', () {
    for (final story in kStoryCatalog) {
      final total = storyTotalDurationMs(story);
      final sum = story.episodes.fold<int>(
        0,
        (acc, e) => acc + storyEpisodeDurationMs(e),
      );
      expect(total, sum);
      expect(total, greaterThan(0));
    }
  });
}
