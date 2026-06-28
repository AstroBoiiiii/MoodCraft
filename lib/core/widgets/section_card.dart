import 'package:flutter/material.dart';

import '../../app/theme/tokens.dart';

/// A titled, soft-surface card used to group a section of content. Replaces the
/// repeated "Divider + title + content" pattern so every screen groups content
/// the same calm, predictable way (CLAUDE.md section 4.2).
///
/// Sits on the scaffold background as a [surface] card with a faint outline.
/// Fill inner tiles with `surfaceContainerHighest` (e.g. [ContactCard]) so they
/// read as a level above the card.
class SectionCard extends StatelessWidget {
  const SectionCard({
    required this.title,
    required this.child,
    this.icon,
    this.trailing,
    super.key,
  });

  final String title;
  final Widget child;
  final IconData? icon;

  /// Optional action shown at the end of the header row (e.g. an Edit button).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}
