import 'package:flutter/material.dart';

/// Caps content width on wide windows (web/tablet) and centers it, so a screen
/// built for a phone never stretches edge to edge. The standard cap matches the
/// 560px column already used by the student home and classroom screens.
class ConstrainedContent extends StatelessWidget {
  const ConstrainedContent({
    required this.child,
    this.maxWidth = 560,
    super.key,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
