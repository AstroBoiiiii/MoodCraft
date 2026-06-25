import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moodcraft/l10n/app_localizations.dart';

import '../../app/theme/tokens.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/widgets/big_button.dart';
import '../../core/widgets/calm_scaffold.dart';

/// Shown when a non-teacher reaches the web app (FR1: web is the teacher's
/// classroom + office layer only). It calmly signs them out and points them to
/// the mobile app — no error styling, no surprise.
class WebMobileOnlyScreen extends ConsumerStatefulWidget {
  const WebMobileOnlyScreen({super.key});

  @override
  ConsumerState<WebMobileOnlyScreen> createState() =>
      _WebMobileOnlyScreenState();
}

class _WebMobileOnlyScreenState extends ConsumerState<WebMobileOnlyScreen> {
  @override
  void initState() {
    super.initState();
    // Drop the non-teacher session so the web app stays teacher-only. The
    // router keeps this public route reachable while signed out.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authServiceProvider).signOut();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return CalmScaffold(
      title: l.webMobileOnlyTitle,
      icon: Icons.phone_iphone_rounded,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.phone_iphone_rounded, size: 72, color: scheme.primary),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l.webMobileOnlyBody,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              BigButton(
                label: l.signIn,
                icon: Icons.login_rounded,
                onPressed: () => context.go('/login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
