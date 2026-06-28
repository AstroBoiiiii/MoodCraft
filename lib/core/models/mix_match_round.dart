import 'enums.dart';

/// A saved Mix-and-Match round for one card type (FR6), persisted on the student
/// so play resumes on the *exact same question* the child left on, even after a
/// sign-out. [placed] is how many of [cards] are already matched (0..length);
/// the next card to place is `cards[placed]`.
class MixMatchRound {
  const MixMatchRound({required this.cards, this.placed = 0});

  final List<MixMatchRoundCard> cards;
  final int placed;

  bool get isComplete => cards.isNotEmpty && placed >= cards.length;

  Map<String, dynamic> toJson() => {
    'placed': placed,
    'cards': cards.map((c) => c.toJson()).toList(),
  };

  factory MixMatchRound.fromJson(Map<String, dynamic> json) => MixMatchRound(
    placed: (json['placed'] as num?)?.toInt() ?? 0,
    cards:
        (json['cards'] as List?)
            ?.whereType<Map>()
            .map((e) => MixMatchRoundCard.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        const [],
  );
}

/// Parse a stored `MixMatchType.name` → [MixMatchRound] map defensively.
Map<String, MixMatchRound> mixMatchRoundsFromJson(Object? value) {
  if (value is! Map) return const {};
  final out = <String, MixMatchRound>{};
  value.forEach((k, v) {
    if (v is Map) {
      out[k.toString()] = MixMatchRound.fromJson(Map<String, dynamic>.from(v));
    }
  });
  return out;
}

/// One persisted card in a saved round: the correct [answer] feeling plus its
/// content (an image [assetPath] or [text]). Mirrors the playable card, minus
/// the runtime-only widget key.
class MixMatchRoundCard {
  const MixMatchRoundCard({required this.answer, this.assetPath, this.text});

  final Emotion answer;
  final String? assetPath;
  final String? text;

  Map<String, dynamic> toJson() => {
    'answer': answer.name,
    if (assetPath != null) 'assetPath': assetPath,
    if (text != null) 'text': text,
  };

  factory MixMatchRoundCard.fromJson(Map<String, dynamic> json) =>
      MixMatchRoundCard(
        answer: enumFromName(Emotion.values, json['answer'], Emotion.neutral),
        assetPath: json['assetPath'] as String?,
        text: json['text'] as String?,
      );
}
