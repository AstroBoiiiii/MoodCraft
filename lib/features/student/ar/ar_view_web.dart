import 'package:flutter/material.dart';
import 'package:moodcraft/l10n/app_localizations.dart';

import '../../../core/widgets/placeholder_screen.dart';

/// Web fallback for the AR screen. Imported when `dart.library.io` is
/// unavailable, so the web build compiles without the WebView/camera stack.
class ArView extends StatelessWidget {
  const ArView({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PlaceholderScreen(
      title: l.navAr,
      icon: Icons.view_in_ar_rounded,
      message: l.arMobileOnly,
    );
  }
}
