import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moodcraft/l10n/app_localizations.dart';

import '../../app/theme/tokens.dart';
import '../../core/models/enums.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/auth/auth_service.dart';
import '../../core/widgets/big_button.dart';
import '../../core/widgets/calm_scaffold.dart';
import '../../core/widgets/password_field.dart';

/// Account creation (FR1). One calm form whose extra fields adapt to the chosen
/// role: a student joins a class and names a parent, a parent names their child,
/// a teacher creates a class. Persists the profile, links relationships, and
/// signs in — the router redirects on success.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();
  final _parentEmail = TextEditingController();
  final _childEmail = TextEditingController();
  final _classCode = TextEditingController();
  final _className = TextEditingController();
  final _age = TextEditingController();
  // Web is teacher-only (FR1), so registration there creates a teacher and the
  // role chooser is hidden. Mobile starts on Student, the most common sign-up.
  UserRole _role = kIsWeb ? UserRole.teacher : UserRole.student;
  AppLanguage _language = AppLanguage.en;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _email.dispose();
    _password.dispose();
    _phone.dispose();
    _parentEmail.dispose();
    _childEmail.dispose();
    _classCode.dispose();
    _className.dispose();
    _age.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await ref
          .read(authServiceProvider)
          .register(
            name: _name.text,
            username: _username.text,
            email: _email.text,
            password: _password.text,
            role: _role,
            language: _language,
            phone: _phone.text,
            age:
                _role == UserRole.student
                    ? (int.tryParse(_age.text.trim()) ?? 0)
                    : 0,
            classCode: _role == UserRole.student ? _classCode.text : null,
            parentEmail: _role == UserRole.student ? _parentEmail.text : null,
            childEmail: _role == UserRole.parent ? _childEmail.text : null,
            className: _role == UserRole.teacher ? _className.text : null,
          );
      // The router redirects on the auth-state change; surface an unrecognised
      // class code as a calm, app-level note that survives the navigation.
      if (!result.classCodeRecognised && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).classCodeNotFound),
          ),
        );
      }
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Something went wrong. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return CalmScaffold(
      title: l.registerTitle,
      icon: Icons.emoji_emotions_rounded,
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // The role chooser is hidden on web, where sign-up is
                  // teacher-only (FR1); mobile picks between all three roles.
                  if (!kIsWeb) ...[
                    Text(
                      l.chooseRole,
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SegmentedButton<UserRole>(
                      segments: [
                        ButtonSegment(
                          value: UserRole.student,
                          label: Text(l.roleStudent),
                          icon: const Icon(Icons.child_care_rounded),
                        ),
                        ButtonSegment(
                          value: UserRole.teacher,
                          label: Text(l.roleTeacher),
                          icon: const Icon(Icons.school_rounded),
                        ),
                        ButtonSegment(
                          value: UserRole.parent,
                          label: Text(l.roleParent),
                          icon: const Icon(Icons.family_restroom_rounded),
                        ),
                      ],
                      selected: {_role},
                      onSelectionChanged:
                          _busy ? null : (s) => setState(() => _role = s.first),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  TextFormField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: l.nameLabel,
                      prefixIcon: const Icon(Icons.person_outline_rounded),
                    ),
                    validator:
                        (v) =>
                            (v != null && v.trim().isNotEmpty)
                                ? null
                                : l.errName,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _username,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    decoration: InputDecoration(
                      labelText: l.usernameLabel,
                      prefixIcon: const Icon(Icons.alternate_email_rounded),
                      hintText: 'e.g. ms_aida',
                    ),
                    validator: (v) => _isUsername(v) ? null : l.errUsername,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: l.emailLabel,
                      prefixIcon: const Icon(Icons.mail_outline_rounded),
                    ),
                    validator: (v) => _isEmail(v) ? null : l.errEmail,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  PasswordField(
                    controller: _password,
                    labelText: l.passwordLabel,
                    autofillHints: const [AutofillHints.newPassword],
                    textInputAction: TextInputAction.next,
                    validator:
                        (v) =>
                            (v != null && v.length >= 6) ? null : l.errPassword,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    autofillHints: const [AutofillHints.telephoneNumber],
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: l.phoneLabel,
                      prefixIcon: const Icon(Icons.phone_outlined),
                    ),
                    validator: (v) => _isPhone(v) ? null : l.errPhone,
                  ),
                  // Role-specific linking fields.
                  ..._roleFields(l),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    l.languageLabel,
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
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
                    onSelectionChanged:
                        _busy
                            ? null
                            : (s) => setState(() => _language = s.first),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    _ErrorBanner(_error!),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  BigButton(
                    label: l.registerTitle,
                    icon: Icons.person_add_alt_1_rounded,
                    onPressed: _busy ? null : _submit,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextButton(
                    onPressed: _busy ? null : () => context.pop(),
                    child: Text(l.toLogin),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Fields that only make sense for the selected role.
  List<Widget> _roleFields(AppLocalizations l) {
    switch (_role) {
      case UserRole.student:
        return [
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _age,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: l.ageLabel,
              prefixIcon: const Icon(Icons.cake_rounded),
            ),
            validator: (v) {
              final n = int.tryParse(v?.trim() ?? '');
              return (n != null && n >= 3 && n <= 18) ? null : l.errAge;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _classCode,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: l.classCodeLabel,
              prefixIcon: const Icon(Icons.tag_rounded),
            ),
            validator:
                (v) =>
                    (v != null && v.trim().length >= 4) ? null : l.errClassCode,
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _parentEmail,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: l.parentEmailLabel,
              prefixIcon: const Icon(Icons.family_restroom_rounded),
            ),
            validator: (v) => _isEmail(v) ? null : l.errEmail,
          ),
        ];
      case UserRole.parent:
        return [
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _childEmail,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: l.childEmailLabel,
              prefixIcon: const Icon(Icons.child_care_rounded),
            ),
            validator: (v) => _isEmail(v) ? null : l.errEmail,
          ),
        ];
      case UserRole.teacher:
        return [
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _className,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: l.classNameLabel,
              prefixIcon: const Icon(Icons.cast_for_education_rounded),
            ),
            // Optional — falls back to the teacher's name if left blank.
          ),
        ];
    }
  }
}

bool _isEmail(String? v) =>
    v != null && RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());

bool _isUsername(String? v) =>
    v != null &&
    v.trim().length >= 3 &&
    RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v.trim());

// 7–15 digits, allowing a leading + and spaces/dashes (stored as typed; never
// SMS-verified — that is out of scope for the demo).
bool _isPhone(String? v) {
  if (v == null) return false;
  final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
  return digits.length >= 7 && digits.length <= 15;
}

/// Calm inline message — no buzzer styling (CLAUDE.md section 4.1).
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: scheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
