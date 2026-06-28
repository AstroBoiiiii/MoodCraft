import 'package:flutter_test/flutter_test.dart';
import 'package:moodcraft/core/constants/app_constants.dart';
import 'package:moodcraft/core/models/enums.dart';

/// FR12 placeholder-art contract: every emotion the journal can log must have a
/// centralised icon + colour so the picker and history never render a gap, and
/// real art can be swapped in later with no call-site changes (CLAUDE.md §9).
void main() {
  test('every Emotion has a journal icon and colour', () {
    for (final emotion in Emotion.values) {
      expect(
        kEmotionIcon[emotion],
        isNotNull,
        reason: 'icon missing: $emotion',
      );
      expect(
        kEmotionColor[emotion],
        isNotNull,
        reason: 'colour missing: $emotion',
      );
    }
  });

  test('journalContextIcon resolves known keys, null otherwise', () {
    expect(journalContextIcon('home'), kJournalContextCatalog['home']);
    expect(journalContextIcon(null), isNull);
    expect(journalContextIcon('not-a-key'), isNull);
  });
}
