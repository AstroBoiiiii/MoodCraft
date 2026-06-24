import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:moodcraft/l10n/app_localizations.dart';

import '../../../core/widgets/placeholder_screen.dart';

/// AR is mobile-only. The web build must never reach AR/camera code
/// (CLAUDE.md sections 2 & 11), so this screen shows a fallback on web and
/// **never imports an AR plugin**. The real ARCore/ARKit plugin is added later,
/// guarded so it is unreachable on web.
class ArScreen extends StatelessWidget {
  const ArScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PlaceholderScreen(
      title: l.navAr,
      icon: Icons.view_in_ar_rounded,
      message: kIsWeb ? l.arMobileOnly : l.arPlaceholder,
    );
  }
}
