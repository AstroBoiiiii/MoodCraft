import 'package:flutter/material.dart';

import '../../../../app/theme/tokens.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/enums.dart';
import '../../../../core/providers/sensory_settings_provider.dart';

/// Web fallback for the companion stage (FR3 is mobile in the final product;
/// dev runs on Chrome). Shows the calm enum-keyed placeholder face — the same
/// big soft circle the Milestone 1 screen used — so the screen stays fully
/// usable on the web without any WebView or 3D dependency.
class CompanionStage extends StatelessWidget {
  const CompanionStage({
    required this.expression,
    required this.intensity,
    super.key,
  });

  final Emotion expression;
  final AnimationIntensity intensity;

  @override
  Widget build(BuildContext context) {
    final color = kEmotionColor[expression]!;
    return Center(
      child: AnimatedSwitcher(
        duration: effectiveDuration(intensity, AppDurations.normal),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: Container(
          key: ValueKey(expression),
          width: 148,
          height: 148,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.18),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.55), width: 2),
          ),
          child: Icon(kEmotionIcon[expression], size: 88, color: color),
        ),
      ),
    );
  }
}
