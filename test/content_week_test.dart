import 'package:flutter_test/flutter_test.dart';
import 'package:moodcraft/core/utils/content_week.dart';

/// Content looping (FR-weekly): the real-date -> content-week mapping shared
/// by AR, Quiz, Story and Mix-and-Match, plus the bundle-wrap helper that lets
/// "this week" always have something to show even with only one authored
/// bundle so far.
void main() {
  test('the anchor week and the six days after it are week 0', () {
    expect(contentWeekIndexFor(kContentWeekAnchor), 0);
    expect(
      contentWeekIndexFor(kContentWeekAnchor.add(const Duration(days: 6))),
      0,
    );
  });

  test('the 7th day after the anchor rolls over to week 1', () {
    expect(
      contentWeekIndexFor(kContentWeekAnchor.add(const Duration(days: 7))),
      1,
    );
    expect(
      contentWeekIndexFor(kContentWeekAnchor.add(const Duration(days: 20))),
      2,
    );
  });

  test('a date before the anchor clamps to week 0, never negative', () {
    expect(
      contentWeekIndexFor(kContentWeekAnchor.subtract(const Duration(days: 3))),
      0,
    );
  });

  test('bundle index wraps around so a week never has nothing to show', () {
    expect(contentBundleIndex(0, 1), 0);
    expect(contentBundleIndex(1, 1), 0);
    expect(contentBundleIndex(5, 1), 0);
    expect(contentBundleIndex(2, 3), 2);
    expect(contentBundleIndex(3, 3), 0);
  });

  test('bundle index is 0 when there are no authored bundles yet', () {
    expect(contentBundleIndex(4, 0), 0);
  });
}
