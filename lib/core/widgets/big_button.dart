import 'package:flutter/material.dart';

import '../constants/app_constants.dart';

/// A large, calm primary action. One clear action per screen, big tap target
/// (CLAUDE.md section 4.5). Full-width by default with an optional leading icon.
class BigButton extends StatelessWidget {
  const BigButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = true,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  /// Stretch to the available width (default) or size to content.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final child = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppConstants.minTapTarget),
      child:
          icon == null
              ? ElevatedButton(onPressed: onPressed, child: Text(label))
              : ElevatedButton.icon(
                onPressed: onPressed,
                icon: Icon(icon, size: 28),
                label: Text(label),
              ),
    );
    if (!expand) return child;
    return SizedBox(width: double.infinity, child: child);
  }
}
