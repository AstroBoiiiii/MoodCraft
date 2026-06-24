import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moodcraft/l10n/app_localizations.dart';

import '../../app/theme/tokens.dart';
import '../../core/models/enums.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/widgets/big_button.dart';
import '../../core/widgets/calm_scaffold.dart';

/// Dev-only sign-in: tap a role to drop straight into its shell. Replaces real
/// login until Firebase auth + a login UI are wired (stub-first foundation).
class DevRolePickerScreen extends ConsumerWidget {
  const DevRolePickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final auth = ref.read(authServiceProvider);

    return CalmScaffold(
      title: l.appName,
      icon: Icons.emoji_emotions_rounded,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l.chooseRole,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              BigButton(
                label: l.roleStudent,
                icon: Icons.child_care_rounded,
                onPressed: () => auth.signInAsRole(UserRole.student),
              ),
              const SizedBox(height: AppSpacing.md),
              BigButton(
                label: l.roleTeacher,
                icon: Icons.school_rounded,
                onPressed: () => auth.signInAsRole(UserRole.teacher),
              ),
              const SizedBox(height: AppSpacing.md),
              BigButton(
                label: l.roleParent,
                icon: Icons.family_restroom_rounded,
                onPressed: () => auth.signInAsRole(UserRole.parent),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
