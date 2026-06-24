import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moodcraft/l10n/app_localizations.dart';

import '../../core/widgets/placeholder_screen.dart';
import '../../core/widgets/sensory_settings_sheet.dart';

/// Parent monitoring — landing screen for the parent app. Carries the account
/// actions (sensory settings + sign out).
class ParentMonitoringScreen extends ConsumerWidget {
  const ParentMonitoringScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => PlaceholderScreen(
    title: AppLocalizations.of(context).navProgress,
    icon: Icons.insights_rounded,
    actions: accountActions(context, ref),
  );
}

class ParentMessagesScreen extends StatelessWidget {
  const ParentMessagesScreen({super.key});
  @override
  Widget build(BuildContext context) => PlaceholderScreen(
    title: AppLocalizations.of(context).navMessages,
    icon: Icons.message_rounded,
  );
}
