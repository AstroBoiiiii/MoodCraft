import 'package:flutter/material.dart';

/// A circular avatar showing the first letter of [name] (or '?'). Centralises the
/// `CircleAvatar(child: Text(name[0]))` pattern repeated across rosters,
/// contacts, conversation tiles and profile headers.
class InitialAvatar extends StatelessWidget {
  const InitialAvatar({
    required this.name,
    this.radius = 20,
    this.background,
    this.foreground,
    super.key,
  });

  final String name;
  final double radius;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final letter = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: radius,
      backgroundColor: background ?? scheme.primaryContainer,
      child: Text(
        letter,
        style: TextStyle(
          color: foreground ?? scheme.onPrimaryContainer,
          fontWeight: FontWeight.w600,
          fontSize: radius * 0.9,
        ),
      ),
    );
  }
}
