import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_notification.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/transitions.dart';
import '../../widgets/bird_avatar.dart';
import '../connections/connection_chat_screen.dart';
import '../connections/connections_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().refreshNotifications();
      context.read<AppState>().refreshVolunteerRecords();
    });
  }

  static const _accents = [
    AppColors.primary,
    AppColors.accent,
    AppColors.magenta,
    AppColors.warning,
  ];

  static const _icons = [
    Icons.celebration_outlined,
    Icons.event_available_outlined,
    Icons.local_mall_outlined,
    Icons.auto_awesome,
  ];

  Future<void> _openNotification(
    BuildContext context,
    AppNotification notification,
  ) async {
    final state = context.read<AppState>();
    if (!notification.isRead) {
      await state.markNotificationRead(notification.id);
    }

    if (!context.mounted) return;

    if (notification.isMessage && notification.peerUserId != null) {
      final connection = state.connectionForPeer(notification.peerUserId!);
      if (connection != null) {
        await Navigator.of(context).push(
          FadeSlidePageRoute(
            builder: (_) => ConnectionChatScreen(connection: connection),
          ),
        );
        return;
      }
      if (!context.mounted) return;
      await Navigator.of(context).push(
        FadeSlidePageRoute(
          builder: (_) => const ConnectionsScreen(initialSegment: 2),
        ),
      );
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = context.watch<AppState>().notifications;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Notifications')),
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppGradients.campusPage),
        child: items.isEmpty
            ? _empty(context)
            : ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    _NotificationCard(
                      notification: items[i],
                      accent: items[i].isMessage
                          ? AppColors.primary
                          : _accents[i % _accents.length],
                      icon: items[i].isMessage
                          ? Icons.chat_bubble_outline
                          : _icons[i % _icons.length],
                      onTap: () => _openNotification(context, items[i]),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  Center(
                    child: Text(
                      "You're all caught up!",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                          ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _empty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BirdAvatar(size: 88),
          const SizedBox(height: AppSpacing.md),
          Text("You're all caught up!",
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('New notifications will show up here.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final String title;
  final String body;
  final String when;
  final Color accent;
  final IconData icon;
  final VoidCallback onTap;

  _NotificationCard({
    required AppNotification notification,
    required this.accent,
    required this.icon,
    required this.onTap,
  })  : title = notification.title,
        body = notification.body,
        when = notification.when,
        notification = notification;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: cardDecoration(
            color: notification.isRead
                ? AppColors.surface
                : AppColors.primary.withValues(alpha: 0.05),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accent, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: notification.isRead
                                        ? FontWeight.w700
                                        : FontWeight.w800,
                                  )),
                        ),
                        Text(when,
                            style:
                                Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: AppColors.textMuted,
                                    )),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(body,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.3,
                            )),
                  ],
                ),
              ),
              if (!notification.isRead)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
