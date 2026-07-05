import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:moodcraft/l10n/app_localizations.dart';
import 'package:permission_handler/permission_handler.dart';

/// The bundled WebAR page is served over http://localhost because
/// getUserMedia needs a secure origin and is blocked from file:// URLs;
/// localhost qualifies. Cleartext to localhost is allowed by
/// android/app/src/main/res/xml/network_security_config.xml.
const int _kArServerPort = 8477;
const String _kArPageUrl =
    'http://localhost:$_kArServerPort/assets/ar/index.html';

enum _ArStage { starting, cameraDenied, ready }

/// Mobile AR view (FR4, Milestone 1: tracking proof).
///
/// Hosts the MindAR image-tracking page (assets/ar/index.html) in an
/// InAppWebView. Two separate camera permission gates must BOTH pass or the
/// page shows a black screen: the OS permission requested in [_prepare], and
/// the in-WebView grant in `onPermissionRequest`.
class ArView extends StatefulWidget {
  const ArView({super.key});

  @override
  State<ArView> createState() => _ArViewState();
}

class _ArViewState extends State<ArView> with WidgetsBindingObserver {
  final InAppLocalhostServer _server =
      InAppLocalhostServer(port: _kArServerPort);
  _ArStage _stage = _ArStage.starting;
  bool _mustOpenSettings = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _prepare();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_server.isRunning()) {
      _server.close();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Coming back from the system settings screen after granting there.
    if (state == AppLifecycleState.resumed && _stage == _ArStage.cameraDenied) {
      _prepare();
    }
  }

  Future<void> _prepare() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    if (!status.isGranted) {
      setState(() {
        _stage = _ArStage.cameraDenied;
        // A permanently denied permission never shows the dialog again, so
        // the retry button has to send the user to the app settings instead.
        _mustOpenSettings = status.isPermanentlyDenied;
      });
      return;
    }
    if (!_server.isRunning()) {
      await _server.start();
    }
    if (!mounted) return;
    setState(() => _stage = _ArStage.ready);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.navAr)),
      body: switch (_stage) {
        _ArStage.starting => _CalmNote(
          message: l.arStarting,
          child: const CircularProgressIndicator(),
        ),
        _ArStage.cameraDenied => _CalmNote(
          message: l.arCameraNeeded,
          child: FilledButton(
            onPressed: () {
              if (_mustOpenSettings) {
                openAppSettings();
              } else {
                _prepare();
              }
            },
            child: Text(l.arAllowCamera),
          ),
        ),
        _ArStage.ready => InAppWebView(
          initialUrlRequest: URLRequest(url: WebUri(_kArPageUrl)),
          initialSettings: InAppWebViewSettings(
            mediaPlaybackRequiresUserGesture: false,
            allowsInlineMediaPlayback: true,
          ),
          // Second camera gate: the WebView asks again for getUserMedia even
          // though the OS permission is already granted.
          onPermissionRequest: (controller, request) async =>
              PermissionResponse(
                resources: request.resources,
                action: PermissionResponseAction.GRANT,
              ),
        ),
      },
    );
  }
}

class _CalmNote extends StatelessWidget {
  const _CalmNote({required this.message, required this.child});

  final String message;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            child,
          ],
        ),
      ),
    );
  }
}
