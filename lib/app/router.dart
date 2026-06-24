import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/models/enums.dart';
import '../core/providers/auth_provider.dart';
import '../features/auth/dev_role_picker_screen.dart';
import '../features/parent/parent_screens.dart';
import '../features/parent/parent_shell.dart';
import '../features/student/ar/ar_screen.dart';
import '../features/student/student_screens.dart';
import '../features/student/student_shell.dart';
import '../features/teacher/teacher_screens.dart';
import '../features/teacher/teacher_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

String _homeFor(UserRole role) => switch (role) {
  UserRole.student => '/student/home',
  UserRole.teacher => '/teacher/dashboard',
  UserRole.parent => '/parent/progress',
};

String _sectionFor(UserRole role) => switch (role) {
  UserRole.student => 'student',
  UserRole.teacher => 'teacher',
  UserRole.parent => 'parent',
};

/// Role-based router. Redirect rules:
///  - signed out -> /login (dev role picker)
///  - signed in but on /login or in the wrong role's section -> that role's home
final goRouterProvider = Provider<GoRouter>((ref) {
  // Re-run redirects whenever auth state changes.
  final refresh = ValueNotifier<int>(0);
  ref.listen(authStateProvider, (_, __) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    refreshListenable: refresh,
    redirect: (context, state) {
      final user = ref.read(authStateProvider).value;
      final atLogin = state.matchedLocation == '/login';

      if (user == null) return atLogin ? null : '/login';

      final section =
          state.uri.pathSegments.isEmpty ? '' : state.uri.pathSegments.first;
      if (atLogin || section != _sectionFor(user.role)) {
        return _homeFor(user.role);
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const DevRolePickerScreen(),
      ),

      // ---- Student (bottom nav: Home / Journal / Rewards) ----
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => StudentShell(shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/student/home',
                builder: (context, state) => const StudentHomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/student/journal',
                builder: (context, state) => const StudentJournalScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/student/rewards',
                builder: (context, state) => const StudentRewardsScreen(),
              ),
            ],
          ),
        ],
      ),
      // Student activities open full-screen over the shell (root navigator).
      GoRoute(
        path: '/student/companion',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CompanionScreen(),
      ),
      GoRoute(
        path: '/student/ar',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ArScreen(),
      ),
      GoRoute(
        path: '/student/story',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const StoryScreen(),
      ),
      GoRoute(
        path: '/student/mixmatch',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const MixMatchScreen(),
      ),
      GoRoute(
        path: '/student/quiz',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const QuizScreen(),
      ),
      GoRoute(
        path: '/student/schedule',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ScheduleScreen(),
      ),

      // ---- Teacher (nav rail, web portal) ----
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => TeacherShell(shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/teacher/dashboard',
                builder: (context, state) => const TeacherDashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/teacher/students',
                builder: (context, state) => const TeacherProfilesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/teacher/classroom',
                builder: (context, state) => const TeacherClassroomScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/teacher/messages',
                builder: (context, state) => const TeacherMessagesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/teacher/reports',
                builder: (context, state) => const TeacherReportsScreen(),
              ),
            ],
          ),
        ],
      ),

      // ---- Parent (bottom nav: Progress / Messages) ----
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => ParentShell(shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/parent/progress',
                builder: (context, state) => const ParentMonitoringScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/parent/messages',
                builder: (context, state) => const ParentMessagesScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
