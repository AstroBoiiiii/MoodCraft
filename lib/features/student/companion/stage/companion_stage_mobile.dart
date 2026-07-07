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
/// lesson and chat flow.
class CompanionStage extends StatefulWidget {
  const CompanionStage({
    required this.expression,
    required this.volume,
    this.focusFace = false,
    this.demonstrate = false,
    this.controller,
    super.key,
  });

  final Emotion expression;

  /// True while the current line talks about the face: the camera dollies to
  /// the avatar's head so the expression is actually readable, then pulls
  /// back to full body when the next line lets go of it.
  final bool focusFace;

  /// True while a lesson or a guessing round is running: the body-language
  /// clip loops for the whole activity instead of settling after one pass,
  /// so the child can study the pose for as long as they need.
  final bool demonstrate;

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
    if (oldWidget.expression != widget.expression ||
        oldWidget.demonstrate != widget.demonstrate) {
      _pushExpression();
    }
    if (oldWidget.focusFace != widget.focusFace) {
      _pushView();
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

  /// A demonstration loops its pose clip for up to an hour (any lesson or
  /// round is over long before that); outside one, the clip plays once.
  Future<void> _pushExpression() => _js(
    "window.mc && window.mc.setEmotion("
    "'${widget.expression.name}', ${widget.demonstrate ? 3600 : 8})",
  );

  Future<void> _pushView() async {
    if (widget.focusFace) {
      if (widget.expression == Emotion.scared) {
        // Scared ducks the whole body down and keeps gently swaying, so a
        // tight head shot loses the face as it moves. Track it instead: keep
        // the cower playing and use a wider, lower-aimed view that follows
        // the duck without needing to stand the avatar back up. (Tuned by
        // headless screenshot against the actual clip, not guessed.)
        await _js(
          "window.mc && window.mc.setView("
          "'upper', {cameraY: 0.5, cameraDistance: -1.5})",
        );
      } else {
        // Stand up first: other clips (e.g. surprised's lean-back) move the
        // head too, and the head camera frames the standing avatar's face.
        await _js("window.mc && window.mc.stopPose && window.mc.stopPose()");
        await _js("window.mc && window.mc.setView('head')");
      }
    } else {
      await _js("window.mc && window.mc.setView('full')");
      // Pulling back mid-activity: resume the looping demonstration.
      if (widget.demonstrate) await _pushExpression();
    }
  }

  Future<void> _start() async {
    if (!_server.isRunning()) {
      await _server.start();
    }
    if (mounted) setState(() => _ready = true);
  }

  /// Leaving the screen must cut the voice right now: the native WebView can
  /// outlive this widget for a moment while the platform view tears down, and
  /// queued speech would keep talking into the next screen. Best-effort and
  /// fire-and-forget; goes straight to the controller because [_js] and the
  /// bound stage controller are already being torn down at this point.
  Future<void> _silence() async {
    try {
      await _webView?.evaluateJavascript(
        source: "window.mc && window.mc.stopSpeaking()",
      );
      // Android: pauses the WebView's processing, audio included, in case
      // the native view lingers past this frame.
      await _webView?.pause();
    } catch (_) {
      // The WebView may already be gone; silence achieved either way.
    }
  }

  @override
  void dispose() {
    _silence();
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
                        _pushView();
                        _js(
                          "window.mc && window.mc.setVolume(${widget.volume})",
                        );
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
