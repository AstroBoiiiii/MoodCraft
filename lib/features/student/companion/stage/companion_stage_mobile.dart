import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../../../../app/theme/tokens.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/enums.dart';
import 'companion_stage_controller.dart';

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
    required this.volume,
    this.controller,
    super.key,
  });

  final Emotion expression;
  final AnimationIntensity intensity;

  /// 0.0 to 1.0, the child's masterVolume sensory setting.
  final double volume;

  /// Bound once the avatar (and its TTS key) are ready, so the screen can
  /// route spoken lines through the lip-synced avatar.
  final CompanionStageController? controller;

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
    if (oldWidget.volume != widget.volume) {
      _js("window.mc && window.mc.setVolume(${widget.volume})");
    }
  }

  /// Fire-and-forget JS into the stage page; failures are quietly ignored
  /// (the page may be reloading, and every push is re-sent on the next call).
  Future<void> _js(String source) async {
    if (!_stageReady) return;
    try {
      await _webView?.evaluateJavascript(source: source);
    } catch (_) {
      // Best-effort.
    }
  }

  Future<void> _pushExpression() =>
      _js("window.mc && window.mc.setEmotion('${widget.expression.name}')");

  Future<void> _start() async {
    if (!_server.isRunning()) {
      await _server.start();
    }
    if (mounted) setState(() => _ready = true);
  }

  @override
  void dispose() {
    widget.controller?.unbind();
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
                  initialUrlRequest: URLRequest(
                    url: WebUri(
                      kTtsApiKey.isEmpty
                          ? _kStagePageUrl
                          : '$_kStagePageUrl?ttsKey=$kTtsApiKey',
                    ),
                  ),
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
                        _js("window.mc && window.mc.setVolume(${widget.volume})");
                        // The avatar only takes over the voice when it can
                        // actually speak (key present); otherwise the screen
                        // keeps using device narration.
                        if (kTtsApiKey.isNotEmpty) {
                          widget.controller?.bind(
                            speak:
                                (text) => _js(
                                  "window.mc && window.mc.speak(${jsonEncode(text)})",
                                ),
                            stop:
                                () => _js(
                                  "window.mc && window.mc.stopSpeaking()",
                                ),
                          );
                        }
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
