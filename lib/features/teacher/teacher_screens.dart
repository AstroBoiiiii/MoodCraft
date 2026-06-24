import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moodcraft/l10n/app_localizations.dart';

import '../../core/widgets/placeholder_screen.dart';
import '../../core/widgets/sensory_settings_sheet.dart';

/// Teacher dashboard — the landing screen for the web portal. Carries the
/// account actions (sensory settings + sign out).
class TeacherDashboardScreen extends ConsumerWidget {
  const TeacherDashboardScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => PlaceholderScreen(
    title: AppLocalizations.of(context).navDashboard,
    icon: Icons.dashboard_rounded,
    actions: accountActions(context, ref),
  );
}

class TeacherProfilesScreen extends StatelessWidget {
  const TeacherProfilesScreen({super.key});
  @override
  Widget build(BuildContext context) => PlaceholderScreen(
    title: AppLocalizations.of(context).navStudents,
    icon: Icons.groups_rounded,
  );
}

class TeacherClassroomScreen extends StatelessWidget {
  const TeacherClassroomScreen({super.key});
  @override
  Widget build(BuildContext context) => PlaceholderScreen(
    title: AppLocalizations.of(context).navClassroom,
    icon: Icons.cast_for_education_rounded,
  );
}

class TeacherMessagesScreen extends StatelessWidget {
  const TeacherMessagesScreen({super.key});
  @override
  Widget build(BuildContext context) => PlaceholderScreen(
    title: AppLocalizations.of(context).navMessages,
    icon: Icons.message_rounded,
  );
}

class TeacherReportsScreen extends StatelessWidget {
  const TeacherReportsScreen({super.key});
  @override
  Widget build(BuildContext context) => PlaceholderScreen(
    title: AppLocalizations.of(context).navReports,
    icon: Icons.assessment_rounded,
  );
}
