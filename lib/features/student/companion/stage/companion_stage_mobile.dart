import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../../../../app/theme/tokens.dart';
import '../../../../core/models/enums.dart';

/// The bundled TalkingHead page is served over http://localhost like the AR
/// page (ES modules and fetch need an http origin, not file://; cleartext to
/// localhost is allowed by network_security_config.xml). Own port so the
/// companion and AR screens never fight over a server.
const int _kStageServerPort = 8478;
const String _kStagePageUrl =
    'http://localhost:$_kStageServerPort/assets/companion/index.html';

/// FR3 Milestone 2, step 1 — the 3D companion stage on mobile: the full-body
/// TalkingHead avatar (assets/companion/index.html) in an InAppWebView.
///
/// [expression] and [intensity] are accepted now so call sites don't change
/// when step 2 wires the Dart to JS bridge (mood + camera + poses); the stage
/// does not react to them yet.
class CompanionStage extends StatefulWidget {
  const CompanionStage({
    required this.expression,
    required this.intensity,
    super.key,
  });

  final Emotion expression;
  final AnimationIntensity intensity;

  @override
  State<CompanionStage> createState() => _CompanionStageState();
}

class _CompanionStageState extends State<CompanionStage> {
  final InAppLocalhostServer _server = InAppLocalhostServer(
    port: _kStageServerPort,
  );
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    if (!_server.isRunning()) {
      await _server.start();
    }
    if (mounted) setState(() => _ready = true);
  }

  @override
  void dispose() {
    if (_server.isRunning()) {
      _server.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 320,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.md),
        child:
            _ready
                ? InAppWebView(
                  initialUrlRequest: URLRequest(url: WebUri(_kStagePageUrl)),
                  initialSettings: InAppWebViewSettings(
                    mediaPlaybackRequiresUserGesture: false,
                    transparentBackground: true,
                  ),
                )
                : ColoredBox(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: const Center(child: CircularProgressIndicator()),
                ),
      ),
    );
  }
}
