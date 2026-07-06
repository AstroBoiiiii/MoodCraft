import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_constants.dart';
import '../core/models/enums.dart';
import '../core/providers/auth_provider.dart';
import '../features/account/account_profile_screen.dart';
import '../features/auth/dev_role_picker_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/auth/web_mobile_only_screen.dart';
import '../features/parent/parent_screens.dart';
import '../features/parent/parent_shell.dart';
import '../features/mix_match/mix_match_screen.dart';
import '../features/mix_match/mix_match_play_screen.dart';
import '../features/quiz/quiz_play_screen.dart';
import '../features/story/story_home_screen.dart';
import '../features/story/story_play_screen.dart';
import '../features/student/ar/ar_screen.dart';
import '../features/student/companion/companion_screen.dart';
import '../features/student/student_screens.dart';
import '../features/student/student_shell.dart';
import '../features/teacher/messaging_thread_screen.dart';
import '../features/teacher/student_profile_detail_screen.dart';
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
      // Routes reachable while signed out (auth flow).
      const publicRoutes = {
        '/login',
        '/register',
        '/dev-login',
        '/mobile-only',
      };
      final onPublic = publicRoutes.contains(state.matchedLocation);

      // Signed out: only the auth-flow routes are allowed.
      if (user == null) return onPublic ? null : '/login';

      // TODO(demo): re-enable the teacher-only web gate before the demo.
      // Web is the teacher's classroom + office layer only (FR1); the gate that
      // sent a signed-in student/parent to /mobile-only is removed temporarily
      // so every role can be tested on Chrome while the UI is being finished.

      // Routes reachable by any signed-in role (not role-specific sections).
      const sharedSignedInPaths = {'/account/profile'};

      // Signed in: bounce away from the auth flow, and keep each role inside
      // its own section.
      final section =
          state.uri.pathSegments.isEmpty ? '' : state.uri.pathSegments.first;
      if (onPublic ||
          (!sharedSignedInPaths.contains(state.matchedLocation) &&
              section != _sectionFor(user.role))) {
        return _homeFor(user.role);
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      // Calm landing for a non-teacher who reaches the web app (FR1).
      GoRoute(
        path: '/mobile-only',
        builder: (context, state) => const WebMobileOnlyScreen(),
      ),
      // Debug-only fast role switch (works with the in-memory stub auth).
      if (kDebugMode)
        GoRoute(
          path: '/dev-login',
          builder: (context, state) => const DevRolePickerScreen(),
        ),

      // Shared profile screen — accessible from any role.
      GoRoute(
        path: '/account/profile',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AccountProfileScreen(),
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
        builder: (context, state) => const StoryHomeScreen(),
      ),
      // Story Mode episode (FR5). `extra` carries the story, episode and the
      // student id (null id = teacher classroom mode).
      GoRoute(
        path: '/student/story/play',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final args = state.extra as StoryPlayArgs;
          return StoryPlayScreen(
            studentId: args.studentId,
            storyId: args.storyId,
            level: args.level,
          );
        },
      ),
      GoRoute(
        path: '/student/mixmatch',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const MixMatchHomeScreen(),
      ),
      // Mix-and-Match round (FR6). `extra` carries the chosen level + the
      // student id (null id = teacher classroom mode).
      GoRoute(
        path: '/student/mixmatch/play',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final args = state.extra as MixMatchArgs;
          return MixMatchPlayScreen(type: args.type, studentId: args.studentId);
        },
      ),
      GoRoute(
        path: '/student/quiz',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const QuizScreen(),
      ),
      // Stress-free quiz round (FR7). `extra` carries the chosen daily set + the
      // student id (null id = teacher classroom mode).
      GoRoute(
        path: '/student/quiz/play',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final args = state.extra as QuizPlayArgs;
          return QuizPlayScreen(
            studentId: args.studentId,
            setIndex: args.setIndex,
          );
        },
      ),
      GoRoute(
        path: '/student/schedule',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ScheduleScreen(),
      ),

      // Teacher classroom projection of Mix-and-Match (FR6). Same play screen,
      // classroom mode (null studentId) — no per-child session is recorded.
      GoRoute(
        path: '/teacher/mixmatch/play',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final type = state.extra as MixMatchType;
          return MixMatchPlayScreen(type: type, studentId: null);
        },
      ),

      // Teacher classroom projection of a story episode (FR5). Same play screen
      // in classroom mode (null studentId) — every episode open, no record.
      GoRoute(
        path: '/teacher/story/play',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final args = state.extra as StoryPlayArgs;
          return StoryPlayScreen(
            studentId: null,
            storyId: args.storyId,
            level: args.level,
          );
        },
      ),

      // Teacher classroom projection of the stress-free quiz (FR7). Same play
      // screen in classroom mode (null studentId) — a group demo, no record.
      // `extra` is the chosen daily set index.
      GoRoute(
        path: '/teacher/quiz/play',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final setIndex = state.extra as int;
          return QuizPlayScreen(studentId: null, setIndex: setIndex);
        },
      ),

      // Teacher messaging thread — pushed full-screen over the shell so the
      // nav rail disappears while chatting (mirrors mobile DM conventions).
      GoRoute(
        path: '/teacher/messages/thread',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra as Map<String, String>;
          return MessagingThreadScreen(
            conversationId: extra['conversationId']!,
            toUid: extra['toUid']!,
            studentId: extra['studentId']!,
            displayTitle: extra['title']!,
          );
        },
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
                builder: (context, state) => const TeacherClassroomScreen(),
                routes: [
                  GoRoute(
                    path: 'student/:id',
                    builder:
                        (context, state) => StudentProfileDetailScreen(
                          studentId: state.pathParameters['id']!,
                        ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/teacher/classroom',
                builder: (context, state) => const TeacherProfilesScreen(),
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
