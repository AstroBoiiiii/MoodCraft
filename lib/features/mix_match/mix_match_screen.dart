import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moodcraft/l10n/app_localizations.dart';

import '../../app/theme/tokens.dart';
import '../../core/constants/app_constants.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/widgets/calm_scaffold.dart';
import '../../core/widgets/sensory_settings_sheet.dart' show accountActions;

/// Arguments for the Mix-and-Match play route. [studentId] null = teacher
/// classroom/projection mode (no session, no progress bump).
typedef MixMatchArgs = ({MixMatchType type, String? studentId});

/// FR6 entry screen for the student: pick a level. The four card types are the
/// four levels, ordered concrete → abstract. Levels unlock in order (finishing
/// one opens the next) but every unlocked level stays replayable — never a fail
/// gate. Locked levels show a calm hint, never a scolding.
class MixMatchHomeScreen extends ConsumerWidget {
  const MixMatchHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final student = ref.watch(activeStudentProvider).value;
    final unlockedThrough = student?.mixMatchLevel ?? 0;

    return CalmScaffold(
      title: l.navMatch,
      icon: Icons.extension_rounded,
      actions: accountActions(context, ref),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            children: [
              Text(l.mixMatchIntro, style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.md),
              MixMatchLevelGrid(
                isUnlocked: (i) => i <= unlockedThrough,
                onPick: (type) {
                  if (student == null) return;
                  context.push(
                    '/student/mixmatch/play',
                    extra: (type: type, studentId: student.id),
                  );
                },
                onLocked:
                    () =>
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            SnackBar(content: Text(l.mixMatchLocked)),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Reusable 2-column grid of the four Mix-and-Match levels. Shared by the
/// student level picker and the teacher's classroom launcher (where every level
/// is unlocked). [isUnlocked] gates by level index; [onLocked] fires when a
/// locked tile is tapped.
class MixMatchLevelGrid extends StatelessWidget {
  const MixMatchLevelGrid({
    required this.isUnlocked,
    required this.onPick,
    this.onLocked,
    super.key,
  });

  final bool Function(int index) isUnlocked;
  final void Function(MixMatchType type) onPick;
  final VoidCallback? onLocked;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      childAspectRatio: 1.05,
      children: [
        for (final type in MixMatchType.values)
          _LevelTile(
            type: type,
            unlocked: isUnlocked(type.index),
            onTap:
                () => isUnlocked(type.index) ? onPick(type) : onLocked?.call(),
          ),
      ],
    );
  }
}

class _LevelTile extends StatelessWidget {
  const _LevelTile({
    required this.type,
    required this.unlocked,
    required this.onTap,
  });

  final MixMatchType type;
  final bool unlocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final accent = activityAccent('mixmatch');
    final tint = unlocked ? accent : theme.colorScheme.outline;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: Ink(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: tint.withValues(alpha: 0.35), width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  unlocked ? mixMatchTypeIcon(type) : Icons.lock_rounded,
                  size: 34,
                  color: tint,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                mixMatchTypeLabel(type, l),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
              Text(
                l.mixMatchLevelN(type.index + 1),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Friendly label for a level type.
String mixMatchTypeLabel(MixMatchType type, AppLocalizations l) =>
    switch (type) {
      MixMatchType.face => l.mixMatchTypeFace,
      MixMatchType.body => l.mixMatchTypeBody,
      MixMatchType.situation => l.mixMatchTypeSituation,
      MixMatchType.word => l.mixMatchTypeWord,
    };

/// Placeholder icon per level type (real art swaps in later).
IconData mixMatchTypeIcon(MixMatchType type) => switch (type) {
  MixMatchType.face => Icons.face_rounded,
  MixMatchType.body => Icons.accessibility_new_rounded,
  MixMatchType.situation => Icons.image_rounded,
  MixMatchType.word => Icons.text_fields_rounded,
};
