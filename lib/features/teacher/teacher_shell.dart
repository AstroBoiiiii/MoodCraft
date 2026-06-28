import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:moodcraft/l10n/app_localizations.dart';

/// Teacher app shell. The teacher works on **both** a phone and the web/projector
/// (CLAUDE.md section 2), so the navigation adapts: a side [NavigationRail] on a
/// wide window (laptop/projector) and a bottom [NavigationBar] on a phone. Same
/// five sections either way.
class TeacherShell extends StatelessWidget {
  const TeacherShell(this.navigationShell, {super.key});

  final StatefulNavigationShell navigationShell;

  /// Width at/above which the side rail is shown instead of the bottom bar.
  static const double _railBreakpoint = 720;

  void _go(int index) => navigationShell.goBranch(
    index,
    initialLocation: index == navigationShell.currentIndex,
  );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final destinations = <({IconData icon, String label})>[
      (icon: Icons.dashboard_rounded, label: l.navDashboard),
      (icon: Icons.groups_rounded, label: l.navStudents),
      (icon: Icons.cast_for_education_rounded, label: l.navClassroom),
      (icon: Icons.message_rounded, label: l.navMessages),
      (icon: Icons.assessment_rounded, label: l.navReports),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= _railBreakpoint) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: navigationShell.currentIndex,
                  labelType: NavigationRailLabelType.all,
                  onDestinationSelected: _go,
                  destinations: [
                    for (final d in destinations)
                      NavigationRailDestination(
                        icon: Icon(d.icon),
                        label: Text(d.label),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: navigationShell),
              ],
            ),
          );
        }
        return Scaffold(
          body: navigationShell,
          bottomNavigationBar: NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: _go,
            destinations: [
              for (final d in destinations)
                NavigationDestination(icon: Icon(d.icon), label: d.label),
            ],
          ),
        );
      },
    );
  }
}
