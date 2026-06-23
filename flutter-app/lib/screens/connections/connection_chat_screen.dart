import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/connection.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';

class ConnectionChatScreen extends StatefulWidget {
  final Connection connection;

  const ConnectionChatScreen({super.key, required this.connection});

  @override
  State<ConnectionChatScreen> createState() => _ConnectionChatScreenState();
}

class _ConnectionChatScreenState extends State<ConnectionChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _loading = true;
  Timer? _pollTimer;
  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _refresh());
  }

  Future<void> _load() async {
    await context.read<AppState>().loadPeerMessages(widget.connection.id);
    if (!mounted) return;
    setState(() => _loading = false);
    _scrollToBottom(animated: false);
  }

  Future<void> _refresh() async {
    if (!mounted || _loading) return;
    final state = context.read<AppState>();
    final before = state.peerMessagesWith(widget.connection.id).length;
    await state.loadPeerMessages(widget.connection.id);
    if (!mounted) return;
    final after = state.peerMessagesWith(widget.connection.id).length;
    if (after != before || after != _lastMessageCount) {
      _lastMessageCount = after;
      _scrollToBottom();
    }
  }

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final target = _scrollController.position.maxScrollExtent;
      if (animated) {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(target);
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final ok = await context
        .read<AppState>()
        .sendPeerMessage(widget.connection.id, text);
    if (!mounted) return;
    if (ok) {
      _controller.clear();
      _lastMessageCount =
          context.read<AppState>().peerMessagesWith(widget.connection.id).length;
      _scrollToBottom();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not send message. Stay connected and try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final messages = state.peerMessagesWith(widget.connection.id);
    final me = state.userId ?? '';
    _lastMessageCount = messages.length;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.connection.name),
            Text(
              '${widget.connection.major} · ${widget.connection.year}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await state.toggleConnection(widget.connection.id);
              if (!context.mounted) return;
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Removed connection with ${widget.connection.name}.'),
                ),
              );
            },
            child: const Text('Remove'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : messages.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Text(
                            'Say hi to ${widget.connection.name}. Messages stay between connected students.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          final mine = msg.isMine(me);
                          return Align(
                            alignment: mine
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.sm,
                              ),
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.sizeOf(context).width * 0.78,
                              ),
                              decoration: BoxDecoration(
                                color: mine
                                    ? AppColors.primary
                                    : AppColors.surfaceMuted,
                                borderRadius: BorderRadius.circular(AppRadii.md),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    msg.body,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: mine
                                              ? Colors.white
                                              : AppColors.textPrimary,
                                        ),
                                  ),
                                  if (msg.createdAt != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      _timeLabel(msg.createdAt!),
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: mine
                                                ? Colors.white
                                                    .withValues(alpha: 0.75)
                                                : AppColors.textMuted,
                                          ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      decoration: const InputDecoration(
                        hintText: 'Write a message…',
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  IconButton.filled(
                    onPressed: _send,
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _timeLabel(DateTime time) {
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}
