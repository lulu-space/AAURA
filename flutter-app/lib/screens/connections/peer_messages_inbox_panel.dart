import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/connection.dart';
import '../../models/peer_conversation.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/transitions.dart';
import '../connections/connection_chat_screen.dart';

class PeerMessagesInboxPanel extends StatefulWidget {
  const PeerMessagesInboxPanel({super.key});

  @override
  State<PeerMessagesInboxPanel> createState() => _PeerMessagesInboxPanelState();
}

class _PeerMessagesInboxPanelState extends State<PeerMessagesInboxPanel> {
  Timer? _pollTimer;

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().loadPeerInbox();
    });
    _pollTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      if (!mounted) return;
      context.read<AppState>().loadPeerInbox();
    });
  }

  void _openChat(Connection connection) {
    Navigator.of(context).push(
      FadeSlidePageRoute(
        builder: (_) => ConnectionChatScreen(connection: connection),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final conversations = state.peerConversations;

    if (conversations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chat_bubble_outline,
                  size: 48, color: AppColors.textMuted.withValues(alpha: 0.7)),
              const SizedBox(height: AppSpacing.md),
              Text(
                'No conversations yet',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Message a connection from My Connections and your chats will show up here.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<AppState>().loadPeerInbox(),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        itemCount: conversations.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final conversation = conversations[index];
          return _ConversationTile(
            conversation: conversation,
            onTap: () {
              final connection = state.connectionForPeer(conversation.peerUserId);
              if (connection != null) {
                _openChat(connection);
              }
            },
          );
        },
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final PeerConversation conversation;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.conversation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = conversation.hasUnread ? AppColors.primary : AppColors.accent;
    final preview = conversation.lastMessageIsMine
        ? 'You: ${conversation.lastMessageBody}'
        : conversation.lastMessageBody;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: cardDecoration(
            color: conversation.hasUnread
                ? AppColors.primary.withValues(alpha: 0.04)
                : AppColors.surface,
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: accent.withValues(alpha: 0.15),
                child: Text(
                  conversation.initial,
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: conversation.hasUnread
                                      ? FontWeight.w800
                                      : FontWeight.w700,
                                ),
                          ),
                        ),
                        if (conversation.lastMessageAt != null)
                          Text(
                            _whenLabel(conversation.lastMessageAt!),
                            style:
                                Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: conversation.hasUnread
                                          ? AppColors.primary
                                          : AppColors.textMuted,
                                      fontWeight: conversation.hasUnread
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                    ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${conversation.major} · ${conversation.year}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.textMuted,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      preview,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: conversation.hasUnread
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                            fontWeight: conversation.hasUnread
                                ? FontWeight.w600
                                : FontWeight.w400,
                            height: 1.3,
                          ),
                    ),
                  ],
                ),
              ),
              if (conversation.hasUnread) ...[
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                  child: Text(
                    conversation.unreadCount > 9
                        ? '9+'
                        : '${conversation.unreadCount}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _whenLabel(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${time.month}/${time.day}';
  }
}
