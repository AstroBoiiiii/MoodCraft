import 'package:flutter/material.dart';

import '../../app/theme/tokens.dart';

/// Text paired with an audio-narration affordance. The app communicates with
/// pictures and audio first, text second (CLAUDE.md section 4.4); low-literacy
/// users can always tap to hear content read aloud.
///
/// [onSpeak] is wired to TTS later (Phase 2). Until then the speaker button is
/// present and consistent but inert when null.
class NarratedText extends StatelessWidget {
  const NarratedText(
    this.text, {
    this.onSpeak,
    this.style,
    super.key,
  });

  final String text;
  final VoidCallback? onSpeak;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            text,
            style: style ?? Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        IconButton(
          tooltip: 'Read aloud',
          iconSize: 28,
          onPressed: onSpeak,
          icon: const Icon(Icons.volume_up_rounded),
        ),
      ],
    );
  }
}
