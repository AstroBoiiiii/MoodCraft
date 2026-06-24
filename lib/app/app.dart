import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moodcraft/l10n/app_localizations.dart';

import '../core/constants/app_constants.dart';
import '../core/providers/sensory_settings_provider.dart';
import 'router.dart';
import 'theme/app_theme.dart';

/// Root widget. The theme is rebuilt from [sensorySettingsProvider] so changing
/// a sensory setting (colour theme / animation) updates the whole app live.
class MoodCraftApp extends ConsumerWidget {
  const MoodCraftApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(sensorySettingsProvider);
    final router = ref.watch(goRouterProvider);

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
