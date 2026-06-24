import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moodcraft/l10n/app_localizations.dart';

import '../../app/theme/tokens.dart';
import '../models/enums.dart';
import '../providers/auth_provider.dart';
import '../providers/sensory_settings_provider.dart';

/// Opens the sensory settings sheet. Changes apply live because the root
/// MaterialApp watches [sensorySettingsProvider] and rebuilds the theme.
void showSensorySettings(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => const _SensorySettingsSheet(),
  );
}

/// Standard app-bar actions for the landing screens: sensory settings + sign
/// out. Kept in one place so all three role homes stay consistent.
List<Widget> accountActions(BuildContext context, WidgetRef ref) {
  final l = AppLocalizations.of(context);
  return [
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

class _SensorySettingsSheet extends ConsumerWidget {
  const _SensorySettingsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final settings = ref.watch(sensorySettingsProvider);
    final controller = ref.read(sensorySettingsProvider.notifier);

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
            Text(l.sensorySettings, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.lg),
            Text(l.colourTheme),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final theme in AppColorTheme.values)
                  ChoiceChip(
                    label: Text(_themeLabel(theme)),
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
              onSelectionChanged: (s) =>
                  controller.setAnimationIntensity(s.first),
            ),
            const SizedBox(height: AppSpacing.sm),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.music),
              value: settings.musicEnabled,
              onChanged: controller.setMusicEnabled,
            ),
          ],
        ),
      ),
    );
  }
}

String _themeLabel(AppColorTheme theme) => switch (theme) {
  AppColorTheme.calmBlue => 'Calm Blue',
  AppColorTheme.softGreen => 'Soft Green',
  AppColorTheme.warmNeutral => 'Warm',
  AppColorTheme.lowStimGrey => 'Low Stim',
};
