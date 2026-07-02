import 'package:flutter/material.dart';

import '../../app/theme/tokens.dart';

/// A large, calm tile for the student home activity grid: a soft accent-tinted
/// icon badge over a centered label, on a surface card with a gentle accent
/// outline. Big tap target, one tap per card (CLAUDE.md section 4.5). The accent
/// only tints the badge + border — the card stays a soft surface, so nothing is
/// harsh or over-saturated (section 4).
class ActivityCard extends StatelessWidget {
  const ActivityCard({
    required this.label,
    required this.icon,
    required this.accent,
    required this.onTap,
    super.key,
  });

  final String label;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: Ink(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: accent.withValues(alpha: 0.35), width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 40, color: accent),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
