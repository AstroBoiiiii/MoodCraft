import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moodcraft/l10n/app_localizations.dart';

import '../core/constants/app_constants.dart';
import '../core/providers/repository_providers.dart';
import '../core/providers/sensory_settings_provider.dart';
import '../core/services/background_music_service.dart';
import 'router.dart';
import 'theme/app_theme.dart';

/// Root widget. The theme is rebuilt from [sensorySettingsProvider] so changing
/// a sensory setting (colour theme / animation) updates the whole app live.
class MoodCraftApp extends ConsumerWidget {
  const MoodCraftApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(sensoryHydrationProvider);
    final settings = ref.watch(sensorySettingsProvider);
    final router = ref.watch(goRouterProvider);

    ref.listen(sensorySettingsProvider, (prev, next) {
      final music = ref.read(backgroundMusicServiceProvider);
      if (!next.musicEnabled) {
        music.stop();
      } else if (prev?.musicEnabled != next.musicEnabled ||
          prev?.backgroundTrack != next.backgroundTrack) {
        music.play(next.backgroundTrack, next.masterVolume);
      } else if (prev?.masterVolume != next.masterVolume) {
        music.setVolume(next.masterVolume);
      }
    });

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(settings),
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
