import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:moodcraft/l10n/app_localizations.dart';

/// Teacher app shell. The teacher works on **both** a phone and the web/projector
/// (CLAUDE.md section 2), so the navigation adapts: a side [NavigationRail] on a
/// wide window (laptop/projector) and a bottom [NavigationBar] on a phone.
///
/// The **Classroom** projection layer (launching a game on the big screen) is
/// web-only, so it is dropped from the phone's navigation — teacher mobile is
/// for managing students and messaging parents. Every visible destination keeps
/// its real shell-branch index, so filtering one out never misroutes the rest.
class TeacherShell extends StatelessWidget {
  const TeacherShell(this.navigationShell, {super.key});

  final StatefulNavigationShell navigationShell;

  /// Width at/above which the side rail is shown instead of the bottom bar.
  static const double _railBreakpoint = 720;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    // (shell branch index, icon, label). The branch index is the position in the
    // StatefulShellRoute in the router; it must stay attached to each item so a
    // hidden destination (Classroom on mobile) doesn't shift the others.
    final all = <({int branch, IconData icon, String label})>[
      (branch: 0, icon: Icons.dashboard_rounded, label: l.navDashboard),
      (branch: 1, icon: Icons.groups_rounded, label: l.navStudents),
      (
        branch: 2,
        icon: Icons.cast_for_education_rounded,
        label: l.navClassroom,
      ),
      (branch: 3, icon: Icons.book_rounded, label: l.navJournal),
      (branch: 4, icon: Icons.message_rounded, label: l.navMessages),
      (branch: 5, icon: Icons.assignment_turned_in_rounded, label: l.navTasks),
    ];
    // Classroom projection (branch 2) is web-only.
    final destinations =
        kIsWeb ? all : all.where((d) => d.branch != 2).toList();

    // Map the active shell branch to its slot in the visible list (fall back to
    // the first tab if the current branch is one that's hidden here).
    final selected = destinations.indexWhere(
      (d) => d.branch == navigationShell.currentIndex,
    );
    final selectedIndex = selected < 0 ? 0 : selected;

    void go(int visibleIndex) {
      final branch = destinations[visibleIndex].branch;
      navigationShell.goBranch(
        branch,
        initialLocation: branch == navigationShell.currentIndex,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= _railBreakpoint) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: selectedIndex,
                  labelType: NavigationRailLabelType.all,
                  onDestinationSelected: go,
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
            selectedIndex: selectedIndex,
            onDestinationSelected: go,
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
