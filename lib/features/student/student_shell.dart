import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:moodcraft/l10n/app_localizations.dart';

/// Student app shell: a simple, predictable bottom navigation
/// (Home / Journal / Rewards). Activities open full-screen over this shell.
class StudentShell extends StatelessWidget {
  const StudentShell(this.navigationShell, {super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_rounded),
            label: l.navHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.book_rounded),
            label: l.navJournal,
          ),
          NavigationDestination(
            icon: const Icon(Icons.star_rounded),
            label: l.navRewards,
          ),
        ],
      ),
    );
  }
}
