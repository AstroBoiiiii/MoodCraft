import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moodcraft/l10n/app_localizations.dart';

import '../../app/theme/tokens.dart';
import '../../core/models/enums.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/widgets/big_button.dart';
import '../../core/widgets/calm_scaffold.dart';

class AccountProfileScreen extends ConsumerStatefulWidget {
  const AccountProfileScreen({super.key});

  @override
  ConsumerState<AccountProfileScreen> createState() =>
      _AccountProfileScreenState();
}

class _AccountProfileScreenState extends ConsumerState<AccountProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late AppLanguage _language;
  bool _editing = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _seedControllers();
  }

  void _seedControllers() {
    final user = ref.read(currentUserProvider);
    _nameCtrl = TextEditingController(text: user?.name ?? '');
    _phoneCtrl = TextEditingController(text: user?.phone ?? '');
    _language = user?.language ?? AppLanguage.en;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _startEdit() => setState(() => _editing = true);

  void _cancelEdit() {
    final user = ref.read(currentUserProvider);
    setState(() {
      _nameCtrl.text = user?.name ?? '';
      _phoneCtrl.text = user?.phone ?? '';
      _language = user?.language ?? AppLanguage.en;
      _editing = false;
    });
  }

  Future<void> _confirm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final updated = user.copyWith(
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      language: _language,
    );
    await ref.read(userRepositoryProvider).upsert(updated);
    ref.invalidate(userProfileProvider);
    if (mounted) {
      setState(() {
        _saving = false;
        _editing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();

    return CalmScaffold(
      title: l.profileTitle,
      icon: Icons.manage_accounts_rounded,
      body: Form(
        key: _formKey,
        child: ListView(
          children: [
            // ── Read-only identity fields ──────────────────────────────────
            _InfoRow(label: l.emailLabel, value: user.email.isNotEmpty ? user.email : '—', theme: theme),
            const SizedBox(height: AppSpacing.md),
            _InfoRow(label: l.usernameLabel, value: user.username.isNotEmpty ? '@${user.username}' : '—', theme: theme),
            const SizedBox(height: AppSpacing.md),
            _InfoRow(label: l.roleLabel, value: _roleLabel(user.role, l), theme: theme),
            const SizedBox(height: AppSpacing.lg),
            const Divider(),
            const SizedBox(height: AppSpacing.md),

            // ── Editable fields ────────────────────────────────────────────
            if (_editing) ...[
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(labelText: l.nameLabel),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? l.errName : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _phoneCtrl,
                decoration: InputDecoration(labelText: l.phoneLabel),
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final digits = v.replaceAll(RegExp(r'\D'), '');
                  return digits.length < 7 ? l.errPhone : null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(l.languageLabel, style: theme.textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.sm),
              SegmentedButton<AppLanguage>(
                segments: [
                  ButtonSegment(value: AppLanguage.en, label: Text(l.languageEnglish)),
                  ButtonSegment(value: AppLanguage.ms, label: Text(l.languageMalay)),
                ],
                selected: {_language},
                onSelectionChanged: (s) => setState(() => _language = s.first),
              ),
              const SizedBox(height: AppSpacing.xl),
              BigButton(
                label: l.confirmEdit,
                icon: Icons.check_rounded,
                onPressed: _saving ? null : _confirm,
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton(
                onPressed: _saving ? null : _cancelEdit,
                child: Text(l.cancelEdit),
              ),
            ] else ...[
              _InfoRow(label: l.nameLabel, value: user.name.isNotEmpty ? user.name : '—', theme: theme),
              const SizedBox(height: AppSpacing.md),
              _InfoRow(label: l.phoneLabel, value: user.phone.isNotEmpty ? user.phone : '—', theme: theme),
              const SizedBox(height: AppSpacing.md),
              _InfoRow(label: l.languageLabel, value: user.language == AppLanguage.en ? l.languageEnglish : l.languageMalay, theme: theme),
              const SizedBox(height: AppSpacing.xl),
              BigButton(
                label: l.editProfile,
                icon: Icons.edit_rounded,
                onPressed: _startEdit,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, required this.theme});
  final String label;
  final String value;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 2),
        Text(value, style: theme.textTheme.bodyLarge),
      ],
    );
  }
}

String _roleLabel(UserRole role, AppLocalizations l) => switch (role) {
  UserRole.student => l.roleStudent,
  UserRole.teacher => l.roleTeacher,
  UserRole.parent => l.roleParent,
};
