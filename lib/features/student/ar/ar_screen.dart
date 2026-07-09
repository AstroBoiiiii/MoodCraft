import 'package:flutter/material.dart';

import 'ar_view_web.dart' if (dart.library.io) 'ar_view_mobile.dart';

/// AR entry point (FR4). Milestone 1: tracking proof — a placeholder cube
/// anchored on a printed marker via WebAR (MindAR image tracking in a
/// WebView). Vision-only, so it runs on uncertified devices; no ARCore.
///
/// The web build must never reach camera code (CLAUDE.md sections 2 & 11),
/// so the conditional import gives web a calm fallback that pulls in zero
/// WebView/camera dependencies. Web AR later = receive a stream from a
/// connected mobile device, never native camera access.
class ArScreen extends StatelessWidget {
  const ArScreen({super.key});

  @override
  Widget build(BuildContext context) => const ArView();
}
