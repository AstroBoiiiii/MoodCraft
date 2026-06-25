import 'package:flutter/material.dart';
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
  });

  final Message message;
  final bool isMe;
  final String meLabel;

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
