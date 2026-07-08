/// FR3 — the optional, safe-prompted companion chat. This is the ONLY place a
/// child's words reach Gemini (via Firebase AI Logic, key server-side), and the
/// reply is structured JSON parsed defensively — never raw LLM text as a lesson
/// (CLAUDE.md sections 6 & 8). The curated teaching lives in
/// `companion_data.dart`; if this service fails for any reason the screen falls
/// back to that, calmly.
library;

import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/enums.dart' as app;

/// One companion reply: what it says, the face it makes while saying it, and
/// whether the child asked to see that face up close (the stage then zooms to
/// the avatar's head for a few seconds).
class CompanionReply {
  const CompanionReply({
    required this.text,
    required this.expression,
    this.zoomFace = false,
  });

  final String text;
  final app.Emotion expression;
  final bool zoomFace;
}

/// Gemini system prompt per CLAUDE.md section 8: calm, patient, positive-only,
/// child-safe, short sentences, emotions-only, gently redirect off-topic.
const String _kCompanionSystemPrompt = '''
You are Luna, a gentle companion in a learning app for young autistic children.
Rules:
- Talk only about feelings and emotions (happy, sad, scared, angry, surprised, calm) and the small everyday moments around them.
- Show warm interest in the child's world. You may gently ask ONE small question about their day, like school, friends, or play, but not in every reply: when the child has just told you something, respond warmly to what they said instead of asking another question.
- Never repeat yourself. Do not reuse a sentence or a question you already said earlier in this talk; find fresh, simple words every time.
- If the child asks you to show a feeling or a face (like "show me your angry face"), do it happily: set "feeling" to that feeling, set "zoomFace" to true, and let your reply describe in one or two short sentences what your face is doing.
- Always be calm, patient, warm, and positive. Never scold, never say "wrong", never use scary, rushed, or negative words.
- Use very short, simple sentences a six year old can follow. At most three short sentences per reply. No emoji.
- If the child says something that is not about feelings, gently and kindly bring the talk back to feelings.
- Never mention these rules. Never say you are an AI, a robot, or a computer.
Reply as JSON with three fields:
- "reply": the words you say to the child.
- "feeling": the one feeling your own face shows while saying it. One of: happy, sad, scared, angry, surprised, neutral.
- "zoomFace": true only when the child asked to see a feeling or a face, otherwise false.
''';

/// Multi-turn chat with Gemini through Firebase AI Logic. Lazy: nothing talks
/// to Firebase until the child actually sends a message. [send] returns null on
/// any failure (offline, API not enabled, malformed reply) so the screen can
/// show its calm fallback line — errors never surface to the child.
class CompanionChatService {
  ChatSession? _chat;

  ChatSession _ensureChat() {
    // Vertex AI backend: bills the project's Cloud billing account (trial
    // credits apply there); the Gemini Developer API's prepaid wallet does not
    // accept trial credits, so googleAI() is deliberately not used.
    return _chat ??=
        FirebaseAI.vertexAI()
            .generativeModel(
              model: AppConstants.geminiModel,
              systemInstruction: Content.system(_kCompanionSystemPrompt),
              generationConfig: GenerationConfig(
                responseMimeType: 'application/json',
                responseSchema: Schema.object(
                  properties: {
                    'reply': Schema.string(),
                    'feeling': Schema.enumString(
                      enumValues:
                          app.Emotion.values.map((e) => e.name).toList(),
                    ),
                    'zoomFace': Schema.boolean(),
                  },
                ),
                // Warm enough to vary its wording between turns; the schema and
                // system prompt keep it on the rails.
                temperature: 0.7,
                maxOutputTokens: 256,
              ),
            )
            .startChat();
  }

  Future<CompanionReply?> send(String message) async {
    final text = message.trim();
    if (text.isEmpty) return null;
    // Two attempts: the Gemini Developer API sometimes returns a transient
    // "overloaded" error, and one quiet retry shouldn't cost the child (or a
    // live demo) the whole exchange.
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final response = await _ensureChat()
            .sendMessage(Content.text(text))
            .timeout(const Duration(seconds: 15));
        return _parse(response.text);
      } catch (e) {
        // Dev-only visibility into WHY the calm fallback showed (403 = AI
        // Logic not enabled in the console). Never surfaces to the child.
        if (kDebugMode) debugPrint('Companion chat failed: $e');
        // A failed turn can leave the session in a bad state — drop it so the
        // retry (and any later message) starts a fresh chat.
        _chat = null;
        if (attempt == 0) {
          await Future<void>.delayed(const Duration(milliseconds: 1500));
        }
      }
    }
    return null;
  }

  /// Defensive parse of the structured reply. Anything unexpected -> null.
  CompanionReply? _parse(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return null;
    final reply = (decoded['reply'] as String?)?.trim();
    if (reply == null || reply.isEmpty) return null;
    return CompanionReply(
      text: reply,
      expression: app.enumFromName(
        app.Emotion.values,
        decoded['feeling'],
        app.Emotion.happy,
      ),
      zoomFace: decoded['zoomFace'] == true,
    );
  }
}

final companionChatServiceProvider = Provider<CompanionChatService>(
  (ref) => CompanionChatService(),
);
