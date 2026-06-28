import 'package:flutter/material.dart';

import '../../app/theme/tokens.dart';

/// A calm, consistent empty state: a soft icon and a short line. Used wherever a
/// list is empty or unavailable, so an empty screen never reads as a failure
/// (CLAUDE.md section 1 — no failure states). Replaces scattered bare
/// "Coming soon" / one-off centered text.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.message,
    this.icon = Icons.spa_rounded,
    this.compact = false,
    super.key,
  });

  final String message;
  final IconData icon;

  /// Inline rendering (smaller, no fill) for use inside a card or list section.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: compact ? 40 : 64,
          color: theme.colorScheme.outlineVariant,
        ),
        SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),
        Text(
          message,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
    if (compact) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: content,
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: content,
      ),
    );
  }
}
