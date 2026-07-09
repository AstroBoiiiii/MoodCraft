import 'package:flutter/material.dart';
import 'package:moodcraft/l10n/app_localizations.dart';

import '../models/enums.dart';
import '../models/sensory_settings.dart';

/// Read-only display of a student's [SensorySettings]. Used by teacher's
/// student detail screen and parent's child profile view.
class SensoryReadOnlyView extends StatelessWidget {
  const SensoryReadOnlyView({required this.settings, super.key});

  final SensorySettings settings;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.palette_outlined),
          title: Text(l.colourTheme),
          trailing: Text(_themeLabel(settings.colorTheme, l)),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(Icons.music_note_outlined),
          title: Text(l.music),
          value: settings.musicEnabled,
          onChanged: null,
        ),
      ],
    );
  }
}

String _themeLabel(AppColorTheme theme, AppLocalizations l) => switch (theme) {
  AppColorTheme.calmBlue => l.colourThemeCalmBlue,
  AppColorTheme.softGreen => l.colourThemeSoftGreen,
  AppColorTheme.warmNeutral => l.colourThemeWarmNeutral,
  AppColorTheme.lowStimGrey => l.colourThemeLowStimGrey,
};
