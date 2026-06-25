import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moodcraft/l10n/app_localizations.dart';

import '../../app/theme/tokens.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/enums.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/providers/sensory_settings_provider.dart';
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
  late TextEditingController _usernameCtrl;
  late TextEditingController _phoneCtrl;
  late AppLanguage _language;

  // Displayed values in view mode — updated after each successful save so the
  // screen reflects changes without waiting for the auth stream to re-emit.
  late String _displayName;
  late String _displayUsername;
  late String _displayPhone;
  late AppLanguage _displayLanguage;

  bool _editing = false;
  bool _saving = false;
  String? _usernameError;

  @override
  void initState() {
    super.initState();
    _seedControllers();
  }

  void _seedControllers() {
    final user = ref.read(currentUserProvider);
    _displayName = user?.name ?? '';
    _displayUsername = user?.username ?? '';
    _displayPhone = user?.phone ?? '';
    _displayLanguage = user?.language ?? AppLanguage.en;
    _nameCtrl = TextEditingController(text: _displayName);
    _usernameCtrl = TextEditingController(text: _displayUsername);
    _phoneCtrl = TextEditingController(text: _displayPhone);
    _language = _displayLanguage;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _startEdit() => setState(() => _editing = true);

  void _cancelEdit() {
    setState(() {
      _nameCtrl.text = _displayName;
      _usernameCtrl.text = _displayUsername;
      _phoneCtrl.text = _displayPhone;
      _language = _displayLanguage;
      _usernameError = null;
      _editing = false;
    });
  }

  Future<void> _confirm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _usernameError = null;
    });
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final newUsername = _usernameCtrl.text.trim().toLowerCase();
    final usernameChanged = newUsername != user.username;

    if (usernameChanged) {
      final db = FirebaseFirestore.instance;
      final snap =
          await db
              .collection(FirestoreCollections.usernameDirectory)
              .doc(newUsername)
              .get();
      if (snap.exists) {
        if (mounted) {
          setState(() {
            _saving = false;
            _usernameError = 'That username is already taken.';
          });
        }
        return;
      }
      // Swap directory entries atomically via a batch.
      final batch = db.batch();
      batch.delete(
        db
            .collection(FirestoreCollections.usernameDirectory)
            .doc(user.username),
      );
      batch.set(
        db.collection(FirestoreCollections.usernameDirectory).doc(newUsername),
        {'uid': user.uid, 'email': user.email},
      );
      await batch.commit();
    }

    final updated = user.copyWith(
      name: _nameCtrl.text.trim(),
      username: newUsername,
      phone: _phoneCtrl.text.trim(),
      language: _language,
    );
    await ref.read(userRepositoryProvider).upsert(updated);
    ref.invalidate(userProfileProvider);
    if (mounted) {
      setState(() {
        _displayName = _nameCtrl.text.trim();
        _displayUsername = newUsername;
        _displayPhone = _phoneCtrl.text.trim();
        _displayLanguage = _language;
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
            _InfoRow(
              label: l.emailLabel,
              value: user.email.isNotEmpty ? user.email : '—',
              theme: theme,
            ),
            const SizedBox(height: AppSpacing.md),
            _InfoRow(
              label: l.roleLabel,
              value: _roleLabel(user.role, l),
              theme: theme,
            ),
            const SizedBox(height: AppSpacing.lg),
            const Divider(),
            const SizedBox(height: AppSpacing.md),

            // ── Editable fields ────────────────────────────────────────────
            if (_editing) ...[
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(labelText: l.nameLabel),
                textCapitalization: TextCapitalization.words,
                validator:
                    (v) => (v == null || v.trim().isEmpty) ? l.errName : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _usernameCtrl,
                decoration: InputDecoration(
                  labelText: l.usernameLabel,
                  prefixText: '@',
                  errorText: _usernameError,
                ),
                autocorrect: false,
                validator: (v) => _isUsername(v) ? null : l.errUsername,
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
                  ButtonSegment(
                    value: AppLanguage.en,
                    label: Text(l.languageEnglish),
                  ),
                  ButtonSegment(
                    value: AppLanguage.ms,
                    label: Text(l.languageMalay),
                  ),
                ],
                selected: {_language},
                onSelectionChanged: (s) => setState(() => _language = s.first),
              ),
              if (user.role != UserRole.student) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(l.colourTheme, style: theme.textTheme.bodyMedium),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final t in AppColorTheme.values)
                      ChoiceChip(
                        label: Text(_themeLabel(t, l)),
                        selected:
                            ref.watch(sensorySettingsProvider).colorTheme == t,
                        onSelected:
                            (_) => ref
                                .read(sensorySettingsProvider.notifier)
                                .setColorTheme(t),
                      ),
                  ],
                ),
              ],
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
              _InfoRow(
                label: l.nameLabel,
                value: _displayName.isNotEmpty ? _displayName : '—',
                theme: theme,
              ),
              const SizedBox(height: AppSpacing.md),
              _InfoRow(
                label: l.usernameLabel,
                value: _displayUsername.isNotEmpty ? '@$_displayUsername' : '—',
                theme: theme,
              ),
              const SizedBox(height: AppSpacing.md),
              _InfoRow(
                label: l.phoneLabel,
                value: _displayPhone.isNotEmpty ? _displayPhone : '—',
                theme: theme,
              ),
              const SizedBox(height: AppSpacing.md),
              _InfoRow(
                label: l.languageLabel,
                value:
                    _displayLanguage == AppLanguage.en
                        ? l.languageEnglish
                        : l.languageMalay,
                theme: theme,
              ),
              if (user.role != UserRole.student) ...[
                const SizedBox(height: AppSpacing.md),
                _InfoRow(
                  label: l.colourTheme,
                  value: _themeLabel(
                    ref.watch(sensorySettingsProvider).colorTheme,
                    l,
                  ),
                  theme: theme,
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              BigButton(
                label: l.editProfile,
                icon: Icons.edit_rounded,
                onPressed: _startEdit,
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                icon: const Icon(Icons.logout_rounded),
                label: Text(l.signOut),
                onPressed: () => ref.read(authServiceProvider).signOut(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.theme,
  });
  final String label;
  final String value;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
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

bool _isUsername(String? v) =>
    v != null &&
    v.trim().length >= 3 &&
    RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v.trim());

String _themeLabel(AppColorTheme t, AppLocalizations l) => switch (t) {
  AppColorTheme.calmBlue => l.colourThemeCalmBlue,
  AppColorTheme.softGreen => l.colourThemeSoftGreen,
  AppColorTheme.warmNeutral => l.colourThemeWarmNeutral,
  AppColorTheme.lowStimGrey => l.colourThemeLowStimGrey,
};
