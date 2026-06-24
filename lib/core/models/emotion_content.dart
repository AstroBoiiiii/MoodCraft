import '../utils/json_utils.dart';
import 'enums.dart';

/// `emotionContent/{contentId}` — curated/cached teaching content that powers
/// the companion and games and works offline. The child never depends on a
/// live LLM for core teaching (CLAUDE.md section 4.7).
class EmotionContent {
  const EmotionContent({
    required this.id,
    required this.emotion,
    required this.prompt,
    this.language = AppLanguage.en,
    this.options = const [],
    this.feedback = '',
  });

  final String id;
  final Emotion emotion;
  final AppLanguage language;
  final String prompt;
  final List<String> options;
  final String feedback;

  Map<String, dynamic> toJson() => {
    'id': id,
    'emotion': emotion.name,
    'language': language.name,
    'prompt': prompt,
    'options': options,
    'feedback': feedback,
  };

  factory EmotionContent.fromJson(Map<String, dynamic> json) => EmotionContent(
    id: (json['id'] as String?) ?? '',
    emotion: enumFromName(Emotion.values, json['emotion'], Emotion.neutral),
    language: enumFromName(AppLanguage.values, json['language'], AppLanguage.en),
    prompt: (json['prompt'] as String?) ?? '',
    options: stringListFromJson(json['options']),
    feedback: (json['feedback'] as String?) ?? '',
  );
}
