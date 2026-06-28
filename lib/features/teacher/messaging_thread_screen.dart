import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: AppDurations.fast,
          curve: Curves.easeOut,
        );
      }
    });
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
    _scrollToBottom();
  }

  Future<void> _confirmDelete(Message message) async {
    final l = AppLocalizations.of(context);
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

    // Scroll to bottom whenever new messages arrive.
    ref.listen(messageThreadProvider(widget.conversationId), (_, next) {
      next.whenData((_) => _scrollToBottom());
    });

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
              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
                itemCount: messages.length,
                itemBuilder:
                    (context, i) => _MessageBubble(
                      message: messages[i],
                      isMe: messages[i].fromUid == myUid,
                      meLabel: l.msgYou,
                      onDelete:
                          messages[i].fromUid == myUid
                              ? () => _confirmDelete(messages[i])
                              : null,
                    ),
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
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
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
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(AppRadii.md),
                topRight: const Radius.circular(AppRadii.md),
                bottomLeft: Radius.circular(isMe ? AppRadii.md : AppRadii.sm),
                bottomRight: Radius.circular(isMe ? AppRadii.sm : AppRadii.md),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    message.text,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: textColor,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  timeStr,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: timeColor,
                    fontSize: 10,
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
