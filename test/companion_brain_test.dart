import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:moodcraft/core/models/enums.dart';
import 'package:moodcraft/features/student/companion/companion_brain.dart';
import 'package:moodcraft/features/student/companion/companion_data.dart';

void main() {
  group('CompanionJudgment.fromModelJson', () {
    test('parses a full valid judgment', () {
      final j = CompanionJudgment.fromModelJson(
        jsonDecode('''
        {"isCorrect": true, "spokenResponse": "Yes! I am sad.",
         "characterEmotion": "happy", "bodyAnimation": "happy",
         "observationNote": "Identified sad on the first try."}
        '''),
      );
      expect(j, isNotNull);
      expect(j!.isCorrect, isTrue);
      expect(j.characterEmotion, Emotion.happy);
      expect(j.bodyAnimation, Emotion.happy);
      expect(j.observationNote, contains('first try'));
    });

    test('bodyAnimation "none" becomes null', () {
      final j = CompanionJudgment.fromModelJson(
        jsonDecode('''
        {"isCorrect": false, "spokenResponse": "Good try! Look again.",
         "characterEmotion": "sad", "bodyAnimation": "none",
         "observationNote": "n"}
        '''),
      );
      expect(j!.bodyAnimation, isNull);
      expect(j.characterEmotion, Emotion.sad);
    });

    test('rejects garbage and missing essentials', () {
      expect(CompanionJudgment.fromModelJson(null), isNull);
      expect(CompanionJudgment.fromModelJson('not json at all'), isNull);
      expect(CompanionJudgment.fromModelJson(<String, dynamic>{}), isNull);
      expect(
        CompanionJudgment.fromModelJson(
          jsonDecode('{"isCorrect": "yes", "spokenResponse": "hi"}'),
        ),
        isNull,
        reason: 'isCorrect must be a real bool',
      );
      expect(
        CompanionJudgment.fromModelJson(
          jsonDecode('{"isCorrect": true, "spokenResponse": "  "}'),
        ),
        isNull,
        reason: 'a blank spoken line cannot drive the character',
      );
    });

    test('unknown enum strings fall back defensively', () {
      final j = CompanionJudgment.fromModelJson(
        jsonDecode('''
        {"isCorrect": true, "spokenResponse": "Yes!",
         "characterEmotion": "ecstatic", "bodyAnimation": "wiggle",
         "observationNote": "n"}
        '''),
      );
      expect(j!.characterEmotion, Emotion.happy);
      expect(j.bodyAnimation, Emotion.neutral);
    });
  });

  group('CompanionJudgment.offline', () {
    test('accepts the exact feeling word from a tap', () {
      final j = CompanionJudgment.offline(
        target: Emotion.sad,
        answer: 'sad',
        attempt: 1,
      );
      expect(j.isCorrect, isTrue);
      expect(j.characterEmotion, Emotion.happy);
    });

    test('accepts a synonym inside a spoken sentence', () {
      final j = CompanionJudgment.offline(
        target: Emotion.angry,
        answer: 'I think you are really mad right now',
        attempt: 2,
      );
      expect(j.isCorrect, isTrue);
      expect(j.observationNote, contains('attempt 2'));
    });

    test('a miss keeps demonstrating the target and stays gentle', () {
      final j = CompanionJudgment.offline(
        target: Emotion.scared,
        answer: 'happy',
        attempt: 1,
      );
      expect(j.isCorrect, isFalse);
      expect(j.characterEmotion, Emotion.scared);
      expect(j.bodyAnimation, Emotion.scared);
      expect(j.spokenResponse, contains(kCompanionRedirectClue[Emotion.scared]));
      expect(j.spokenResponse.toLowerCase(), isNot(contains('wrong')));
      expect(j.spokenResponse.toLowerCase(), isNot(contains('no.')));
    });

    test('every teachable emotion has synonyms and a redirect clue', () {
      for (final e in kCompanionEmotions) {
        expect(kCompanionSynonyms[e], isNotEmpty, reason: e.name);
        expect(kCompanionRedirectClue[e], isNotNull, reason: e.name);
      }
    });
  });
}
