import 'package:flutter/material.dart';

import '../../app/theme/tokens.dart';

/// A consistent page chrome used across the app. Predictable, identical layout
/// every time (CLAUDE.md section 4.2): soft background, one clear title with an
/// optional leading icon, generous padding, and a single body.
class CalmScaffold extends StatelessWidget {
  const CalmScaffold({
    required this.title,
    required this.body,
    this.icon,
    this.actions,
    this.floatingActionButton,
    this.bottom,
    super.key,
  });

  final String title;
  final Widget body;
  final IconData? icon;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final PreferredSizeWidget? bottom;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 28),
              const SizedBox(width: AppSpacing.sm),
            ],
            Flexible(child: Text(title, overflow: TextOverflow.ellipsis)),
          ],
        ),
        actions: actions,
        bottom: bottom,
      ),
      floatingActionButton: floatingActionButton,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: body,
        ),
      ),
    );
  }
}
