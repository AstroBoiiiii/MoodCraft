import 'package:flutter/material.dart';
import 'package:moodcraft/l10n/app_localizations.dart';

import '../../app/theme/tokens.dart';
import 'calm_scaffold.dart';
import 'narrated_text.dart';

/// A calm, consistent stand-in for a feature that isn't built yet. Used while we
/// lay the foundation (CLAUDE.md build order Phase 0) — real activity UIs
/// replace these per-feature.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    required this.title,
    required this.icon,
    this.message,
    this.actions,
    super.key,
  });

  final String title;
  final IconData icon;
  final String? message;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CalmScaffold(
      title: title,
      icon: icon,
      actions: actions,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 144,
                height: 144,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(
                    alpha: 0.4,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 72, color: theme.colorScheme.primary),
              ),
              const SizedBox(height: AppSpacing.xl),
              NarratedText(
                message ?? AppLocalizations.of(context).comingSoon,
                style: theme.textTheme.headlineSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
