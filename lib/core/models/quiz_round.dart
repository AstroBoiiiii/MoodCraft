import 'enums.dart';

/// A saved stress-free quiz round (FR7), persisted on the student so the quiz
/// resumes on the *exact same questions* the child left on, even after a
/// sign-out. [answered] is how many of [questions] are done (0..length); the
/// next question to show is `questions[answered]`. Stored per daily set, keyed by
/// the set index (see `quizSetIndexForDate`).
class QuizRound {
  const QuizRound({required this.questions, this.answered = 0});

  final List<QuizRoundQuestion> questions;
  final int answered;

  bool get isComplete => questions.isNotEmpty && answered >= questions.length;

  Map<String, dynamic> toJson() => {
    'answered': answered,
    'questions': questions.map((q) => q.toJson()).toList(),
  };

  factory QuizRound.fromJson(Map<String, dynamic> json) => QuizRound(
    answered: (json['answered'] as num?)?.toInt() ?? 0,
    questions:
        (json['questions'] as List?)
            ?.whereType<Map>()
            .map(
              (e) => QuizRoundQuestion.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList() ??
        const [],
  );
}

/// Parse a stored set-index → [QuizRound] map defensively.
Map<String, QuizRound> quizRoundsFromJson(Object? value) {
  if (value is! Map) return const {};
  final out = <String, QuizRound>{};
  value.forEach((k, v) {
    if (v is Map) {
      out[k.toString()] = QuizRound.fromJson(Map<String, dynamic>.from(v));
    }
  });
  return out;
}

/// One persisted quiz question: how it asks ([modality]), the correct [answer],
/// the feeling [options] shown, the [feedback] line, and its content (an image
/// or sound [assetPath], or story [text]). Mirrors the playable question, minus
/// the runtime-only widget id.
class QuizRoundQuestion {
  const QuizRoundQuestion({
    required this.modality,
    required this.answer,
    required this.options,
    required this.feedback,
    this.assetPath,
    this.text,
  });

  final QuizModality modality;
  final Emotion answer;
  final List<Emotion> options;
  final String feedback;
  final String? assetPath;
  final String? text;

  Map<String, dynamic> toJson() => {
    'modality': modality.name,
    'answer': answer.name,
    'options': options.map((e) => e.name).toList(),
    'feedback': feedback,
    if (assetPath != null) 'assetPath': assetPath,
    if (text != null) 'text': text,
  };

  factory QuizRoundQuestion.fromJson(Map<String, dynamic> json) =>
      QuizRoundQuestion(
        modality: enumFromName(
          QuizModality.values,
          json['modality'],
          QuizModality.look,
        ),
        answer: enumFromName(Emotion.values, json['answer'], Emotion.neutral),
        options:
            (json['options'] as List?)
                ?.map((e) => enumFromName(Emotion.values, e, Emotion.neutral))
                .toList() ??
            const [],
        feedback: (json['feedback'] as String?) ?? '',
        assetPath: json['assetPath'] as String?,
        text: json['text'] as String?,
      );
}
