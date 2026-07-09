import 'package:flutter/material.dart';

import '../../app/theme/tokens.dart';
import 'initial_avatar.dart';

/// The centered header for a person: big initial avatar, name, an optional
/// subtitle (e.g. age) and a level/stars chip. Shared by the parent monitoring
/// and teacher student-detail screens so a child's profile reads the same way
/// in both places.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    required this.name,
    required this.chipLabel,
    this.subtitle,
    this.avatarRadius = 40,
    super.key,
  });

  final String name;

  /// Localised level/stars label shown in the chip below the name.
  final String chipLabel;

  /// Optional line under the name (e.g. "7 years old").
  final String? subtitle;
  final double avatarRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        InitialAvatar(name: name, radius: avatarRadius),
        const SizedBox(height: AppSpacing.md),
        Text(
          name,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall,
        ),
        if (subtitle != null && subtitle!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        Chip(
          avatar: const Icon(Icons.star_rounded, size: 18),
          label: Text(chipLabel),
        ),
      ],
    );
  }
}
