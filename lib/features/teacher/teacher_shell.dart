import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:moodcraft/l10n/app_localizations.dart';

/// Teacher app shell: a side navigation rail, suited to the web portal on a
/// laptop/projector (CLAUDE.md section 2). Five sections.
class TeacherShell extends StatelessWidget {
  const TeacherShell(this.navigationShell, {super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: navigationShell.currentIndex,
            labelType: NavigationRailLabelType.all,
            onDestinationSelected: (index) => navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            ),
            destinations: [
              NavigationRailDestination(
                icon: const Icon(Icons.dashboard_rounded),
                label: Text(l.navDashboard),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.groups_rounded),
                label: Text(l.navStudents),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.cast_for_education_rounded),
                label: Text(l.navClassroom),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.message_rounded),
                label: Text(l.navMessages),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.assessment_rounded),
                label: Text(l.navReports),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: navigationShell),
        ],
      ),
    );
  }
}
