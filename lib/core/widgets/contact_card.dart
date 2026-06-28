import 'package:flutter/material.dart';

import '../../app/theme/tokens.dart';
import '../models/app_user.dart';
import 'initial_avatar.dart';

/// A linked teacher/parent contact: avatar, name, @username and phone. Shared by
/// the parent monitoring, student-detail and account-profile screens so contacts
/// look identical everywhere. Pass [onRemove] to show an unlink button.
///
/// Filled with `surfaceContainerHighest` so it reads a level above both the
/// scaffold background and a [SectionCard] surface.
class ContactCard extends StatelessWidget {
  const ContactCard({
    required this.user,
    this.onRemove,
    this.removeTooltip,
    super.key,
  });

  final AppUser user;
  final VoidCallback? onRemove;
  final String? removeTooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Row(
        children: [
          InitialAvatar(name: user.name),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name.isNotEmpty ? user.name : '—',
                  style: theme.textTheme.titleSmall,
                ),
                if (user.username.isNotEmpty)
                  Text(
                    '@${user.username}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                if (user.phone.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      children: [
                        Icon(
                          Icons.phone_rounded,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(user.phone, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (onRemove != null)
            IconButton(
              tooltip: removeTooltip,
              icon: Icon(
                Icons.person_remove_rounded,
                color: theme.colorScheme.error,
              ),
              onPressed: onRemove,
            ),
        ],
      ),
    );
  }
}
