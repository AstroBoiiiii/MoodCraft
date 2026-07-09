import 'package:flutter_test/flutter_test.dart';
import 'package:moodcraft/core/constants/app_constants.dart';
import 'package:moodcraft/core/models/enums.dart';
import 'package:moodcraft/core/models/mix_match_round.dart';
import 'package:moodcraft/core/models/quiz_round.dart';
import 'package:moodcraft/core/models/story_progress.dart';
import 'package:moodcraft/core/models/student.dart';
import 'package:moodcraft/features/mix_match/mix_match_data.dart';
import 'package:moodcraft/features/quiz/quiz_data.dart';
import 'package:moodcraft/features/story/story_data.dart';
import 'package:moodcraft/features/student/companion/companion_data.dart';

/// The "is the whole activity finished" checks that earn each completed badge
/// (FR11). One shared shape: only the very last unit flips them to true, so a
/// completed badge can never be handed out early.
void main() {
  MixMatchRound round(int cards, int placed) => MixMatchRound(
    cards: [
      for (var i = 0; i < cards; i++)
        const MixMatchRoundCard(answer: Emotion.happy),
    ],
    placed: placed,
  );

  QuizRound quiz(int questions, int answered) => QuizRound(
    questions: [
      for (var i = 0; i < questions; i++)
        const QuizRoundQuestion(
          modality: QuizModality.look,
          answer: Emotion.happy,
          options: [Emotion.happy, Emotion.sad, Emotion.angry],
          feedback: '',
        ),
    ],
    answered: answered,
  );

  test('mixMatchAllComplete needs a full round of all four card types', () {
    // Three of four types finished — not complete yet.
    final partial = Student(
      id: 's1',
      name: 'A',
      mixMatchRounds: {
        for (final t in MixMatchType.values.take(3)) t.name: round(5, 5),
      },
    );
    expect(mixMatchAllComplete(partial), isFalse);

    // The fourth type present but not fully placed — still not complete.
    final almost = partial.copyWith(
      mixMatchRounds: {
        for (final t in MixMatchType.values.take(3)) t.name: round(5, 5),
        MixMatchType.values.last.name: round(5, 4),
      },
    );
    expect(mixMatchAllComplete(almost), isFalse);

    // All four fully placed — complete.
    final done = almost.copyWith(
      mixMatchRounds: {
        for (final t in MixMatchType.values) t.name: round(5, 5),
      },
    );
    expect(mixMatchAllComplete(done), isTrue);
  });

  test('quizAllComplete needs every daily set finished', () {
    final partial = Student(
      id: 's1',
      name: 'A',
      quizRounds: {
        for (var i = 0; i < kQuizSetCount - 1; i++) '$i': quiz(5, 5),
      },
    );
    expect(quizAllComplete(partial), isFalse);

    final done = Student(
      id: 's1',
      name: 'A',
      quizRounds: {for (var i = 0; i < kQuizSetCount; i++) '$i': quiz(5, 5)},
    );
    expect(quizAllComplete(done), isTrue);
  });

  test('storyAllComplete needs every episode of every story finished', () {
    // All stories but the last one done.
    final partial = Student(
      id: 's1',
      name: 'A',
      storyProgress: {
        for (final s in kStoryCatalog.take(kStoryCatalog.length - 1))
          s.id: StoryProgress(levelsDone: s.episodes.length),
      },
    );
    expect(storyAllComplete(partial), isFalse);

    final done = Student(
      id: 's1',
      name: 'A',
      storyProgress: {
        for (final s in kStoryCatalog)
          s.id: StoryProgress(levelsDone: s.episodes.length),
      },
    );
    expect(storyAllComplete(done), isTrue);
  });

  test('companionAllComplete needs all five feeling lessons', () {
    final four = kCompanionEmotions.take(4).map((e) => e.name).toList();
    expect(companionAllComplete(four), isFalse);

    final all = kCompanionEmotions.map((e) => e.name).toList();
    expect(companionAllComplete(all), isTrue);
  });
}
