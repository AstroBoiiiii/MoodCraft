import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:moodcraft/l10n/app_localizations.dart';

/// Parent app shell: a small bottom navigation (Progress / Messages). The
/// child's homework is viewed inside the Progress tab (read-only) — parents are
/// never handed tasks of their own, so there is no separate Tasks tab.
class ParentShell extends StatelessWidget {
  const ParentShell(this.navigationShell, {super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected:
            (index) => navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            ),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.insights_rounded),
            label: l.navProgress,
          ),
          NavigationDestination(
            icon: const Icon(Icons.message_rounded),
            label: l.navMessages,
          ),
        ],
      ),
    );
  }
}
