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

/// FR3 Milestone 2 — the 3D companion stage on mobile: the full-body
/// TalkingHead avatar (assets/companion/index.html) in an InAppWebView.
///
/// Step 2 bridge: the page calls the `stageReady` handler once the avatar has
/// loaded, then every [expression] change is pushed into the page via
/// `window.mc.setEmotion(...)` so the avatar's face and posture follow the
/// lesson and chat flow. [intensity] is reserved for later motion scaling.
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
  InAppWebViewController? _webView;
  bool _stageReady = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(CompanionStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expression != widget.expression) {
      _pushExpression();
    }
  }

  /// Best-effort: a dropped frame of expression is invisible next to the
  /// avatar's own idle motion, so failures are quietly ignored.
  Future<void> _pushExpression() async {
    if (!_stageReady) return;
    try {
      await _webView?.evaluateJavascript(
        source: "window.mc && window.mc.setEmotion('${widget.expression.name}')",
      );
    } catch (_) {
      // The page is reloading or gone; the next push catches up.
    }
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
                  onWebViewCreated: (controller) {
                    _webView = controller;
                    controller.addJavaScriptHandler(
                      handlerName: 'stageReady',
                      callback: (_) {
                        _stageReady = true;
                        // Catch the avatar up with whatever the screen shows.
                        _pushExpression();
                      },
                    );
                  },
                )
                : ColoredBox(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: const Center(child: CircularProgressIndicator()),
                ),
      ),
    );
  }
}
