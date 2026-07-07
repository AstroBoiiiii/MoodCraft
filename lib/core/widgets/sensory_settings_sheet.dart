import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moodcraft/l10n/app_localizations.dart';

import '../../app/theme/tokens.dart';
import '../models/enums.dart';
import '../providers/auth_provider.dart';
import '../providers/sensory_settings_provider.dart';
import '../services/background_music_service.dart';

/// Opens the sensory settings sheet. Changes apply live because the root
/// MaterialApp watches [sensorySettingsProvider] and rebuilds the theme.
void showSensorySettings(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => const _SensorySettingsSheet(),
  );
}

/// Standard app-bar actions for the landing screens: profile + (for students)
/// sensory settings. Kept in one place so all three role homes stay consistent.
List<Widget> accountActions(BuildContext context, WidgetRef ref) {
  final l = AppLocalizations.of(context);
  final role = ref.read(currentUserProvider)?.role;
  return [
    IconButton(
      tooltip: l.profileTitle,
      icon: const Icon(Icons.manage_accounts_rounded),
      onPressed: () => context.push('/account/profile'),
    ),
    if (role == UserRole.student)
      IconButton(
        tooltip: l.sensorySettings,
        icon: const Icon(Icons.tune_rounded),
        onPressed: () => showSensorySettings(context),
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
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final settings = ref.watch(sensorySettingsProvider);
    final controller = ref.read(sensorySettingsProvider.notifier);

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
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
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.music),
              value: settings.musicEnabled,
              onChanged: (enabled) {
                controller.setMusicEnabled(enabled);
                final music = ref.read(backgroundMusicServiceProvider);
                if (enabled) {
                  music.play(settings.backgroundTrack, settings.masterVolume);
                } else {
                  music.stop();
                }
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.quizFeedbackNarration),
              value: settings.quizFeedbackNarration,
              onChanged: controller.setQuizFeedbackNarration,
            ),
            if (settings.musicEnabled) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(l.musicTrack),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final track in BackgroundTrack.values)
                    ChoiceChip(
                      label: Text(_trackLabel(track, l)),
                      selected: settings.backgroundTrack == track,
                      onSelected: (_) {
                        controller.setBackgroundTrack(track);
                        if (settings.musicEnabled) {
                          ref
                              .read(backgroundMusicServiceProvider)
                              .play(track, settings.masterVolume);
                        }
                      },
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Text(l.musicVolume),
                  const SizedBox(width: AppSpacing.sm),
                  const Icon(Icons.volume_down_rounded, size: 20),
                  Expanded(
                    child: Slider(
                      value: settings.masterVolume,
                      min: 0.0,
                      max: 1.0,
                      divisions: 10,
                      onChanged: (v) {
                        controller.setMasterVolume(v);
                        ref.read(backgroundMusicServiceProvider).setVolume(v);
                      },
                    ),
                  ),
                  const Icon(Icons.volume_up_rounded, size: 20),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _themeLabel(AppColorTheme theme, AppLocalizations l) => switch (theme) {
  AppColorTheme.calmBlue => l.colourThemeCalmBlue,
  AppColorTheme.softGreen => l.colourThemeSoftGreen,
  AppColorTheme.warmNeutral => l.colourThemeWarmNeutral,
  AppColorTheme.lowStimGrey => l.colourThemeLowStimGrey,
};

String _trackLabel(BackgroundTrack track, AppLocalizations l) =>
    switch (track) {
      BackgroundTrack.track1 => l.musicTrack1,
      BackgroundTrack.track2 => l.musicTrack2,
      BackgroundTrack.track3 => l.musicTrack3,
    };
