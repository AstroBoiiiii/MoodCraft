/// FR3 — the teaching brain. Judges one round of the emotion-teaching loop:
/// given the feeling the avatar is demonstrating and the child's answer
/// (a tapped feeling or their spoken words), Gemini returns structured JSON
/// that drives everything the character does next — what it says, the face it
/// makes, the body clip it plays, and a short observation note for the
/// teacher's log. This is the literal wiring between the AI's mind and the
/// character's body.
///
/// Never blocks and never turns negative: any failure (offline, quota,
/// malformed reply) falls back to [CompanionJudgment.offline], a deterministic
/// synonym check with the same gentle-redirect rules.
library;

import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/enums.dart' as app;
import 'companion_data.dart';

/// What the brain decided for one answer. Every field maps onto a character
/// action: [spokenResponse] is voiced with lip-sync, [characterEmotion] sets
/// the face, [bodyAnimation] plays the matching pose clip (null = stay as-is),
/// and [observationNote] goes to the round's log entry.
class CompanionJudgment {
  const CompanionJudgment({
    required this.isCorrect,
    required this.spokenResponse,
    required this.characterEmotion,
    required this.bodyAnimation,
    required this.observationNote,
  });

  final bool isCorrect;
  final String spokenResponse;
  final app.Emotion characterEmotion;
  final app.Emotion? bodyAnimation;
  final String observationNote;

  /// Defensive parse of the model's JSON (already decoded to a map).
  /// Returns null when anything essential is missing or malformed.
  static CompanionJudgment? fromModelJson(Object? decoded) {
    if (decoded is! Map<String, dynamic>) return null;
    final isCorrect = decoded['isCorrect'];
    final spoken = (decoded['spokenResponse'] as String?)?.trim();
    if (isCorrect is! bool || spoken == null || spoken.isEmpty) return null;
    final body = decoded['bodyAnimation'];
    return CompanionJudgment(
      isCorrect: isCorrect,
      spokenResponse: spoken,
      characterEmotion: app.enumFromName(
        app.Emotion.values,
        decoded['characterEmotion'],
        isCorrect ? app.Emotion.happy : app.Emotion.neutral,
      ),
      bodyAnimation:
          body == null || body == 'none'
              ? null
              : app.enumFromName(app.Emotion.values, body, app.Emotion.neutral),
      observationNote:
          (decoded['observationNote'] as String?)?.trim() ?? 'No note.',
    );
  }

  /// The deterministic offline judge: same gentle rules, no network. Correct
  /// answers (including synonyms like "mad" for angry) get warm praise; a miss
  /// gets one body/face clue and another look, with the character continuing
  /// to demonstrate the target feeling.
  factory CompanionJudgment.offline({
    required app.Emotion target,
    required String answer,
    required int attempt,
  }) {
    final said = answer.toLowerCase();
    final words = kCompanionSynonyms[target] ?? [target.name];
    final correct = words.any(said.contains);
    if (correct) {
      return CompanionJudgment(
        isCorrect: true,
        spokenResponse: 'Yes! I am feeling ${target.name}. You saw it!',
        characterEmotion: app.Emotion.happy,
        bodyAnimation: app.Emotion.happy,
        observationNote:
            'Identified ${target.name} on attempt $attempt (offline check).',
      );
    }
    return CompanionJudgment(
      isCorrect: false,
      spokenResponse:
          'Good try! ${kCompanionRedirectClue[target] ?? ''} How am I feeling?',
      characterEmotion: target,
      bodyAnimation: target,
      observationNote:
          'Did not identify ${target.name} on attempt $attempt '
          '(offline check).',
    );
  }
}

/// Gemini system prompt: the judge knows the gentle-feedback rules (CLAUDE.md
/// section 4: no failure states) and the exact JSON contract.
const String _kBrainSystemPrompt = '''
You are Momo, a gentle 3D companion teaching young autistic children to recognise feelings. You just acted out a feeling with your face and body, and asked the child how you are feeling. Judge the child's answer.
Rules:
- The child answers by tapping a feeling word or by speaking. Accept close words and synonyms as correct: "mad" means angry, "afraid" or "scary" means scared, "shocked" means surprised, and so on. Spoken answers may be long or messy; if the target feeling is in there, it is correct.
- If correct: give warm, short praise that names the feeling. Your face turns happy and your body celebrates gently.
- If not correct: NEVER say wrong, no, or anything negative. Warmly point at ONE clue in your face or body (for sad: head hanging down; for happy: big smile; for scared: wide eyes, holding tight; for angry: crossed arms, scrunched face; for surprised: round eyes, big O mouth) and ask again. Keep showing the target feeling with your face and body.
- At most two short sentences a six year old can follow. No emoji.
- observationNote is for the teacher, not the child: one short factual note like "Identified sad on the first try" or "Mixed up angry with sad on attempt 1, needed the body clue".
Respond as JSON:
- "isCorrect": whether the child identified the feeling.
- "spokenResponse": what you say to the child.
- "characterEmotion": the feeling your own face shows while saying it (happy, sad, scared, angry, surprised, neutral).
- "bodyAnimation": the body clip you play (happy, sad, scared, angry, surprised, or none).
- "observationNote": the short teacher note.
''';

/// One-shot judge (no chat history — each round stands alone). Returns null
/// only if both attempts fail; callers then use [CompanionJudgment.offline].
class CompanionBrain {
  GenerativeModel? _model;

  GenerativeModel _ensureModel() {
    return _model ??= FirebaseAI.googleAI().generativeModel(
      model: AppConstants.geminiModel,
      systemInstruction: Content.system(_kBrainSystemPrompt),
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: Schema.object(
          properties: {
            'isCorrect': Schema.boolean(),
            'spokenResponse': Schema.string(),
            'characterEmotion': Schema.enumString(
              enumValues: app.Emotion.values.map((e) => e.name).toList(),
            ),
            'bodyAnimation': Schema.enumString(
              enumValues: [
                ...app.Emotion.values.map((e) => e.name),
                'none',
              ],
            ),
            'observationNote': Schema.string(),
          },
        ),
        temperature: 0.4,
        maxOutputTokens: 256,
      ),
    );
  }

  /// Judges [answer] against [target]. [spoken] tells the model whether the
  /// child tapped a word or talked; [attempt] gives it retry context.
  Future<CompanionJudgment> judge({
    required app.Emotion target,
    required String answer,
    required bool spoken,
    required int attempt,
  }) async {
    final payload =
        'Target feeling: ${target.name}. Attempt number: $attempt. '
        'The child ${spoken ? 'said' : 'tapped'}: "$answer"';
    for (var tryNo = 0; tryNo < 2; tryNo++) {
      try {
        final response = await _ensureModel()
            .generateContent([Content.text(payload)])
            .timeout(const Duration(seconds: 12));
        final judgment = CompanionJudgment.fromModelJson(
          response.text == null ? null : _decode(response.text!),
        );
        if (judgment != null) return judgment;
      } catch (e) {
        if (kDebugMode) debugPrint('Companion brain failed: $e');
        _model = null;
        if (tryNo == 0) {
          await Future<void>.delayed(const Duration(milliseconds: 1200));
        }
      }
    }
    return CompanionJudgment.offline(
      target: target,
      answer: answer,
      attempt: attempt,
    );
  }

  static Object? _decode(String raw) {
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }
}

final companionBrainProvider = Provider<CompanionBrain>(
  (ref) => CompanionBrain(),
);
