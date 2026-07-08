/// Content looping: every curated activity except the AI companion (FR3, which
/// teaches from a live Gemini chat, not a fixed set) is organised into weekly
/// content, so new AR characters, quiz sets, stories and Mix-and-Match cards
/// can be dropped in week by week with no code change to the activity itself.
/// Today only one bundle is authored per activity (the current curated
/// content), so every real week just replays it until a new bundle is added —
/// the mechanism is what matters right now, not having weeks of unique content
/// on day one.
library;

/// The Monday this weekly rotation started counting from. Content week 0 is
/// the calendar week containing this date; every real week after it is the
/// next content week. Kept as "this week" so a fresh install always opens on
/// week 0, matching the demo (there is no earlier week to show yet).
final DateTime kContentWeekAnchor = DateTime(2026, 7, 6);

/// 0-based content week for [date], counted in real calendar weeks from
/// [kContentWeekAnchor]. Clamped to 0 for any date before the anchor so a
/// clock set slightly behind never reads as a negative week.
int contentWeekIndexFor(DateTime date) {
  final days = date.difference(kContentWeekAnchor).inDays;
  return days < 0 ? 0 : days ~/ 7;
}

/// The content week for right now, per the real device date.
int currentContentWeekIndex() => contentWeekIndexFor(DateTime.now());

/// Resolves a real week index into an authored-bundle index for a feature that
/// has [bundleCount] bundles ready, wrapping around so "this week" always has
/// something to show even before new bundles are authored — a feature is never
/// left with nothing to play (design principle 1).
int contentBundleIndex(int weekIndex, int bundleCount) =>
    bundleCount <= 0 ? 0 : weekIndex % bundleCount;
