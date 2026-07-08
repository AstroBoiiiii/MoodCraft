import 'package:flutter/material.dart';

import '../../../../app/theme/tokens.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/enums.dart';
import 'companion_stage_controller.dart';

/// Web fallback for the companion stage (FR3 is mobile in the final product;
/// dev runs on Chrome). Shows the calm enum-keyed placeholder face — the same
/// big soft circle the Milestone 1 screen used — so the screen stays fully
/// usable on the web without any WebView or 3D dependency. The [controller]
/// is never bound here, so the screen keeps narrating with device TTS.
class CompanionStage extends StatefulWidget {
  const CompanionStage({
    required this.expression,
    required this.volume,
    this.focusFace = false,
    this.demonstrate = false,
    this.controller,
    this.onStageReady,
    super.key,
  });

  final Emotion expression;
  final double volume;

  /// The 3D stage zooms to the avatar's head for face lines and loops the
  /// pose clip while [demonstrate] is set; the placeholder is already just a
  /// face, so here both are accepted and ignored.
  final bool focusFace;
  final bool demonstrate;
  final CompanionStageController? controller;

  /// The placeholder face has nothing to load, so this fires right after the
  /// first frame (mirrors the mobile stage's real `stageReady` signal so the
  /// screen can greet the child the same way on both platforms).
  final VoidCallback? onStageReady;

  @override
  State<CompanionStage> createState() => _CompanionStageState();
}

class _CompanionStageState extends State<CompanionStage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => widget.onStageReady?.call(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = kEmotionColor[widget.expression]!;
    return Center(
      child: AnimatedSwitcher(
        duration: AppDurations.normal,
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: Container(
          key: ValueKey(widget.expression),
          width: 148,
          height: 148,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.18),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.55), width: 2),
          ),
          child: Icon(kEmotionIcon[widget.expression], size: 88, color: color),
        ),
      ),
    );
  }
}
