import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:linkify/linkify.dart' show linkify;
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../../app/theme/tokens.dart';
import '../../core/models/message.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/repository_providers.dart';
import '../../l10n/app_localizations.dart';

/// Full-screen chat thread between a teacher and a parent about one student.
/// Used for both teacher (pushed full-screen) and embedded in the parent shell.
class MessagingThreadScreen extends ConsumerStatefulWidget {
  const MessagingThreadScreen({
    super.key,
    required this.conversationId,
    required this.toUid,
    required this.studentId,
    required this.displayTitle,
    this.showAppBar = true,
  });

  /// Canonical conversation id — `studentId__uid1__uid2` (sorted uids).
  final String conversationId;
  final String toUid;
  final String studentId;

  /// Shown in the AppBar.
  final String displayTitle;

  /// Set to false when embedding inside a parent screen that already has a
  /// scaffold / app bar.
  final bool showAppBar;

  @override
  ConsumerState<MessagingThreadScreen> createState() =>
      _MessagingThreadScreenState();
}

class _MessagingThreadScreenState extends ConsumerState<MessagingThreadScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // On web, suppress the browser's native right-click menu so our own
    // "Delete message" menu can show instead. Restored in dispose.
    if (kIsWeb) BrowserContextMenu.disableContextMenu();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final myUid = ref.read(currentUserProvider)?.uid;
      if (myUid != null) {
        ref
            .read(messageRepositoryProvider)
            .markThreadRead(widget.conversationId, myUid);
      }
    });
  }

  @override
  void dispose() {
    if (kIsWeb) BrowserContextMenu.enableContextMenu();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final myUid = ref.read(currentUserProvider)?.uid;
    if (myUid == null) return;

    // Clear input immediately — the user sees their message appear via the
    // Firestore stream, which fires from the local cache before the network
    // write completes (no spinner needed).
    _controller.clear();

    final message = Message(
      id: const Uuid().v4(),
      fromUid: myUid,
      toUid: widget.toUid,
      studentId: widget.studentId,
      conversationId: widget.conversationId,
      participants: [myUid, widget.toUid],
      text: text,
      timestamp: DateTime.now(),
    );

    ref.read(messageRepositoryProvider).send(message);
  }

  Future<void> _confirmDelete(Message message) async {
    final l = AppLocalizations.of(context);
    // Drop input focus so the keyboard doesn't pop up when the dialog (and the
    // preceding context menu) closes and focus would otherwise return here.
    FocusManager.instance.primaryFocus?.unfocus();
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(l.msgDeleteMessage),
            content: Text(l.msgDeleteConfirm),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l.cancelEdit),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(l.actionDelete),
              ),
            ],
          ),
    );
    if (confirmed != true) return;

    await ref.read(messageRepositoryProvider).delete(message.id);
    if (!mounted) return;
    FocusManager.instance.primaryFocus?.unfocus();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l.msgDeleted)));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final myUid = ref.watch(currentUserProvider)?.uid ?? '';
    final messagesAsync = ref.watch(
      messageThreadProvider(widget.conversationId),
    );

    final body = Column(
      children: [
        Expanded(
          child: messagesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Center(child: Text(l.comingSoon)),
            data: (messages) {
              if (messages.isEmpty) {
                return Center(
                  child: Text(
                    l.msgNoConversations,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              }
              // `reverse: true` anchors the list to the newest message at the
              // bottom, so it stays put even as link preview cards load and
              // change height (otherwise the view jumps around). Index 0 is the
              // newest, so we read the list back to front.
              return ListView.builder(
                controller: _scrollController,
                reverse: true,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
                itemCount: messages.length,
                itemBuilder: (context, i) {
                  final message = messages[messages.length - 1 - i];
                  return _MessageBubble(
                    message: message,
                    isMe: message.fromUid == myUid,
                    meLabel: l.msgYou,
                    onDelete:
                        message.fromUid == myUid
                            ? () => _confirmDelete(message)
                            : null,
                  );
                },
              );
            },
          ),
        ),
        _InputBar(
          controller: _controller,
          hint: l.msgTypeHere,
          sendLabel: l.msgSend,
          onSend: _send,
        ),
      ],
    );

    if (!widget.showAppBar) return body;

    return Scaffold(
      appBar: AppBar(title: Text(widget.displayTitle)),
      body: body,
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.meLabel,
    this.onDelete,
  });

  final Message message;
  final bool isMe;
  final String meLabel;

  /// Non-null only for the current user's own messages — long-press (mobile) or
  /// right-click (web/desktop) opens a Delete menu.
  final VoidCallback? onDelete;

  /// Shows a small "Delete" menu at [position]; runs [onDelete] if chosen.
  /// Works the same on touch and mouse, so web (Chrome) gets a usable
  /// affordance where a mouse long-press is unreliable.
  Future<void> _showDeleteMenu(BuildContext context, Offset position) async {
    final onDelete = this.onDelete;
    if (onDelete == null) return;
    final l = AppLocalizations.of(context);
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final selected = await showMenu<bool>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        overlay.size.width - position.dx,
        overlay.size.height - position.dy,
      ),
      items: [
        PopupMenuItem<bool>(
          value: true,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.delete_outline_rounded,
                size: 20,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(l.msgDeleteMessage),
            ],
          ),
        ),
      ],
    );
    if (selected == true) onDelete();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final bubbleColor =
        isMe
            ? theme.colorScheme.primary
            : theme.colorScheme.surfaceContainerHighest;
    final textColor =
        isMe ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface;
    final timeColor =
        isMe
            ? theme.colorScheme.onPrimary.withAlpha(180)
            : theme.colorScheme.onSurfaceVariant;

    final time = message.timestamp;
    final timeStr =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    // First link in the message, if any — drives the rich preview card.
    final previewUrl = _firstUrl(message.text);
    final hasPreview = previewUrl != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: GestureDetector(
            onLongPressStart:
                onDelete == null
                    ? null
                    : (d) => _showDeleteMenu(context, d.globalPosition),
            onSecondaryTapDown:
                onDelete == null
                    ? null
                    : (d) => _showDeleteMenu(context, d.globalPosition),
            child: Container(
              // With a preview card we use an even, all-round inset so the card
              // sits neatly centred inside the bubble instead of being padded
              // unevenly and pushed against one side.
              padding:
                  hasPreview
                      ? const EdgeInsets.all(AppSpacing.xs)
                      : const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(AppRadii.md),
                  topRight: const Radius.circular(AppRadii.md),
                  bottomLeft: Radius.circular(isMe ? AppRadii.md : AppRadii.sm),
                  bottomRight: Radius.circular(
                    isMe ? AppRadii.sm : AppRadii.md,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment:
                    hasPreview
                        ? CrossAxisAlignment.stretch
                        : CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasPreview) ...[
                    _LinkPreviewCard(url: previewUrl),
                    const SizedBox(height: AppSpacing.xs),
                  ],
                  Padding(
                    // Text/time get a little side padding only when the bubble
                    // itself has been trimmed to the tight preview inset.
                    padding:
                        hasPreview
                            ? const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                            )
                            : EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Linkify(
                          text: message.text,
                          onOpen: (link) => _openUrl(link.url),
                          options: const LinkifyOptions(
                            looseUrl: true,
                            humanize: false,
                          ),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: textColor,
                          ),
                          linkStyle: theme.textTheme.bodyMedium?.copyWith(
                            color:
                                isMe
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            timeStr,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: timeColor,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.hint,
    required this.sendLabel,
    required this.onSend,
  });

  final TextEditingController controller;
  final String hint;
  final String sendLabel;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: hint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton.filled(
              onPressed: onSend,
              icon: const Icon(Icons.send_rounded),
              tooltip: sendLabel,
            ),
          ],
        ),
      ),
    );
  }
}

/// Returns the first URL found in [text], or null. Uses the same parser as the
/// inline [Linkify] text so the preview and the clickable link always agree.
String? _firstUrl(String text) {
  for (final element in linkify(
    text,
    options: const LinkifyOptions(looseUrl: true, humanize: false),
  )) {
    if (element is UrlElement) return element.url;
  }
  return null;
}

/// Adds an `https://` scheme if the link was typed without one (e.g. a bare
/// `shopee.com.my/...`), so both launching and metadata fetching work.
String _normalizeUrl(String url) {
  final trimmed = url.trim();
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }
  return 'https://$trimmed';
}

/// Opens [url] in the device browser (or a new tab on web).
Future<void> _openUrl(String url) async {
  final uri = Uri.tryParse(_normalizeUrl(url));
  if (uri == null) return;
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

/// Lightweight link metadata used to build the preview card.
class _LinkMeta {
  const _LinkMeta({this.title, this.image});

  final String? title;
  final String? image;
}

/// In-memory cache so the same link isn't re-fetched every time the message
/// list rebuilds or scrolls.
final Map<String, Future<_LinkMeta?>> _metaCache = {};

/// Reads title + preview image for [rawUrl] via microlink, a free proxy that
/// works from the web build (the browser blocks reading other sites directly)
/// and follows short-link redirects. `prerender=true` runs the page's
/// JavaScript so JS-heavy stores (Shopee, Lazada) expose a real product image.
/// Returns null on any failure so the caller can fall back to a plain card.
Future<_LinkMeta?> _fetchMeta(String rawUrl) {
  final target = _normalizeUrl(rawUrl);
  return _metaCache.putIfAbsent(target, () async {
    final api = Uri.https('api.microlink.io', '/', {
      'url': target,
      'prerender': 'true',
    });
    try {
      final res = await http.get(api).timeout(const Duration(seconds: 25));
      if (res.statusCode != 200) return null;
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (body['status'] != 'success') return null;
      final data = body['data'] as Map<String, dynamic>?;
      if (data == null) return null;
      return _LinkMeta(
        title: data['title'] as String?,
        // Only a real preview image, never the tiny favicon `logo`.
        image: (data['image'] as Map<String, dynamic>?)?['url'] as String?,
      );
    } catch (_) {
      return null;
    }
  });
}

/// Rich link preview shown inside a message bubble. Shows the picture when the
/// page has one (e.g. a long product link), otherwise shows the clean
/// [_LinkFallback] card. Always tappable.
class _LinkPreviewCard extends StatefulWidget {
  const _LinkPreviewCard({required this.url});

  final String url;

  @override
  State<_LinkPreviewCard> createState() => _LinkPreviewCardState();
}

class _LinkPreviewCardState extends State<_LinkPreviewCard> {
  late Future<_LinkMeta?> _metadata = _fetchMeta(widget.url);

  @override
  void didUpdateWidget(_LinkPreviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) _metadata = _fetchMeta(widget.url);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<_LinkMeta?>(
      future: _metadata,
      builder: (context, snapshot) {
        final image = snapshot.data?.image;
        final title = snapshot.data?.title;
        // No image to show (still loading, failed, or page has none): use the
        // clean link card so it never looks broken.
        if (image == null || image.isEmpty) {
          return _LinkFallback(url: widget.url);
        }
        return Material(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadii.sm),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _openUrl(widget.url),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 140,
                  width: double.infinity,
                  child: Image.network(
                    image,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      );
                    },
                    errorBuilder:
                        (context, _, __) => _LinkFallback(url: widget.url),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (title != null && title.isNotEmpty)
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall,
                        ),
                      const SizedBox(height: 4),
                      Text(
                        Uri.tryParse(_normalizeUrl(widget.url))?.host ??
                            widget.url,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Clean tappable link card shown when there is no preview image (or the page
/// can't be read). Built purely from the URL itself (a link icon, the site
/// name, and the address), so it always renders instantly and never errors.
class _LinkFallback extends StatelessWidget {
  const _LinkFallback({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final normalized = _normalizeUrl(url);
    final host = Uri.tryParse(normalized)?.host ?? url;

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(AppRadii.sm),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openUrl(url),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Icon(
                  Icons.link_rounded,
                  size: 22,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      host,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      normalized,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
