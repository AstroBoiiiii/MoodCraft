import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moodcraft/l10n/app_localizations.dart';

import '../../app/theme/tokens.dart';
import '../models/enums.dart';
import '../providers/auth_provider.dart';
import '../providers/repository_providers.dart';
import '../providers/sensory_settings_provider.dart';
import 'big_button.dart';

/// Opens the sensory settings sheet. Changes apply live because the root
/// MaterialApp watches [sensorySettingsProvider] and rebuilds the theme.
void showSensorySettings(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => const _SensorySettingsSheet(),
  );
}

/// Standard app-bar actions for the landing screens: profile + sensory settings
/// + sign out. Kept in one place so all three role homes stay consistent.
List<Widget> accountActions(BuildContext context, WidgetRef ref) {
  final l = AppLocalizations.of(context);
  return [
    IconButton(
      tooltip: l.profileTitle,
      icon: const Icon(Icons.manage_accounts_rounded),
      onPressed: () => context.push('/account/profile'),
    ),
    IconButton(
      tooltip: l.sensorySettings,
      icon: const Icon(Icons.tune_rounded),
      onPressed: () => showSensorySettings(context),
    ),
    IconButton(
      tooltip: l.signOut,
      icon: const Icon(Icons.logout_rounded),
      onPressed: () => ref.read(authServiceProvider).signOut(),
    ),
  ];
}

class _SensorySettingsSheet extends ConsumerStatefulWidget {
  const _SensorySettingsSheet();

  @override
  ConsumerState<_SensorySettingsSheet> createState() =>
      _SensorySettingsSheetState();
}

class _SensorySettingsSheetState extends ConsumerState<_SensorySettingsSheet> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final settings = ref.watch(sensorySettingsProvider);
    final controller = ref.read(sensorySettingsProvider.notifier);
    final user = ref.read(currentUserProvider);
    final isStudent = user?.role == UserRole.student;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.sensorySettings,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(l.colourTheme),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final theme in AppColorTheme.values)
                  ChoiceChip(
                    label: Text(_themeLabel(theme, l)),
                    selected: settings.colorTheme == theme,
                    onSelected: (_) => controller.setColorTheme(theme),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(l.animation),
            const SizedBox(height: AppSpacing.sm),
            SegmentedButton<AnimationIntensity>(
              segments: [
                ButtonSegment(
                  value: AnimationIntensity.full,
                  label: Text(l.animationFull),
                ),
                ButtonSegment(
                  value: AnimationIntensity.reduced,
                  label: Text(l.animationReduced),
                ),
                ButtonSegment(
                  value: AnimationIntensity.off,
                  label: Text(l.animationOff),
                ),
              ],
              selected: {settings.animationIntensity},
              onSelectionChanged:
                  (s) => controller.setAnimationIntensity(s.first),
            ),
            const SizedBox(height: AppSpacing.sm),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.music),
              value: settings.musicEnabled,
              onChanged: controller.setMusicEnabled,
            ),
            if (isStudent) ...[
              const SizedBox(height: AppSpacing.lg),
              BigButton(
                label: l.saveProfile,
                onPressed: _saving ? null : _save,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final user = ref.read(currentUserProvider);
    if (user == null || user.linkedStudentIds.isEmpty) return;
    setState(() => _saving = true);
    final repo = ref.read(studentRepositoryProvider);
    await ref
        .read(sensorySettingsProvider.notifier)
        .saveToStudent(repo, user.linkedStudentIds.first);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}

String _themeLabel(AppColorTheme theme, AppLocalizations l) => switch (theme) {
  AppColorTheme.calmBlue => l.colourThemeCalmBlue,
  AppColorTheme.softGreen => l.colourThemeSoftGreen,
  AppColorTheme.warmNeutral => l.colourThemeWarmNeutral,
  AppColorTheme.lowStimGrey => l.colourThemeLowStimGrey,
};
