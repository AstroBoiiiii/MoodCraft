import 'dart:math';

import 'package:flutter/services.dart' show AssetManifest, rootBundle;

import '../../core/constants/app_constants.dart';
import '../../core/models/enums.dart';
import '../../core/models/mix_match_round.dart';

/// One draggable card in a Mix-and-Match round (FR6). A card belongs to exactly
/// one [answer] emotion — the child's job is to drag it onto that emotion's
/// bucket. Image cards carry an [assetPath]; word/situation cards carry [text].
class MixMatchCard {
  const MixMatchCard({
    required this.id,
    required this.type,
    required this.answer,
    this.assetPath,
    this.text,
  });

  final String id;
  final MixMatchType type;
  final Emotion answer;

  /// Set for image cards (face/body, or situation when art was uploaded).
  final String? assetPath;

  /// Set for text cards (word, or situation without art).
  final String? text;

  bool get isText => text != null;
}

/// Builds a shuffled round of [count] cards for a level [type].
///
/// Image types are discovered at runtime from the asset manifest: every file
/// under `mixmatch/<type>/` named `<emotion>_<n>.ext` becomes a card whose
/// answer is parsed from the leading `<emotion>` token (unknown tokens are
/// skipped, never crash). Text types (word, and situation when no art exists)
/// come from the curated catalogs in `app_constants.dart`.
///
/// If fewer source cards exist than [count], cards are sampled with repeats so
/// the round is always full — keeping the demo robust no matter how little art
/// has been dropped in.
Future<List<MixMatchCard>> buildMixMatchDeck(
  MixMatchType type, {
  int count = 5,
  Random? random,
}) async {
  final rng = random ?? Random();
  final pool = await _poolFor(type);
  if (pool.isEmpty) return const [];

  pool.shuffle(rng);
  if (pool.length >= count) return pool.take(count).toList();

  // Not enough distinct cards — pad with random repeats so the round is full.
  final deck = [...pool];
  while (deck.length < count) {
    deck.add(pool[rng.nextInt(pool.length)]);
  }
  // Re-key the padded copies so widget keys stay unique.
  return [
    for (var i = 0; i < deck.length; i++)
      MixMatchCard(
        id: '${deck[i].id}#$i',
        type: deck[i].type,
        answer: deck[i].answer,
        assetPath: deck[i].assetPath,
        text: deck[i].text,
      ),
  ];
}

/// Rebuilds the playable deck from a saved round so the child resumes the exact
/// same cards in the same order (the unplaced ones are `cards[round.placed..]`).
List<MixMatchCard> deckFromRound(MixMatchType type, MixMatchRound round) => [
  for (var i = 0; i < round.cards.length; i++)
    MixMatchCard(
      id: '${type.name}_saved_$i',
      type: type,
      answer: round.cards[i].answer,
      assetPath: round.cards[i].assetPath,
      text: round.cards[i].text,
    ),
];

/// Snapshots the current deck + how many are placed into a savable round.
MixMatchRound roundFromDeck(List<MixMatchCard> deck, int placed) =>
    MixMatchRound(
      placed: placed,
      cards: [
        for (final c in deck)
          MixMatchRoundCard(
            answer: c.answer,
            assetPath: c.assetPath,
            text: c.text,
          ),
      ],
    );

Future<List<MixMatchCard>> _poolFor(MixMatchType type) async {
  if (type == MixMatchType.story) return _textPool(type, kMixMatchStories);

  final images = await _imagePool(type);
  if (images.isNotEmpty) return images;

  // Situation falls back to curated text when no art has been uploaded.
  if (type == MixMatchType.situation) {
    return _textPool(type, kMixMatchSituations);
  }
  return const [];
}

/// Cards from a curated `Emotion -> entries` catalog.
List<MixMatchCard> _textPool(
  MixMatchType type,
  Map<Emotion, List<String>> cat,
) {
  final cards = <MixMatchCard>[];
  for (final entry in cat.entries) {
    for (var i = 0; i < entry.value.length; i++) {
      cards.add(
        MixMatchCard(
          id: '${type.name}_${entry.key.name}_$i',
          type: type,
          answer: entry.key,
          text: entry.value[i],
        ),
      );
    }
  }
  return cards;
}

/// Cards discovered from bundled assets under the type's folder.
Future<List<MixMatchCard>> _imagePool(MixMatchType type) async {
  final folder = mixMatchTypeFolder(type);
  final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
  final cards = <MixMatchCard>[];
  for (final path in manifest.listAssets()) {
    if (!path.startsWith('$folder/')) continue;
    final answer = _emotionFromPath(path);
    // Skip unknown prefixes and any emotion without a bucket (e.g. neutral) —
    // never break the round.
    if (answer == null || !kMixMatchEmotions.contains(answer)) continue;
    cards.add(
      MixMatchCard(id: path, type: type, answer: answer, assetPath: path),
    );
  }
  return cards;
}

/// Parses the leading `<emotion>` token from a card filename, e.g.
/// `.../face/happy_1.png` -> Emotion.happy. Returns null if unrecognised.
Emotion? _emotionFromPath(String path) {
  final file = path.split('/').last; // happy_1.png
  final token = file.split('_').first.toLowerCase(); // happy
  for (final e in Emotion.values) {
    if (e.name == token) return e;
  }
  return null;
}
