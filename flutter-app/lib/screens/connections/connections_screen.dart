import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../models/connection.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/transitions.dart';
import '../../widgets/pill_tab_bar.dart';
import 'connection_chat_screen.dart';
import 'peer_messages_inbox_panel.dart';

class ConnectionsScreen extends StatefulWidget {
  final int initialSegment;

  const ConnectionsScreen({super.key, this.initialSegment = 0});

  @override
  State<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends State<ConnectionsScreen> {
  late int _segment;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _segment = widget.initialSegment.clamp(0, 2);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final onMessagesTab = _segment == 2;
    final query = _searchCtrl.text.trim().toLowerCase();
    Iterable<Connection> source = state.suggestedConnections;
    if (_segment == 1) {
      source = state.myConnections;
    }
    if (!onMessagesTab && query.isNotEmpty) {
      source = source.where((c) =>
          c.name.toLowerCase().contains(query) ||
          c.major.toLowerCase().contains(query) ||
          c.interests.any((i) => i.toLowerCase().contains(query)));
    }
    final list = source.toList();
    final unreadMessages = state.unreadPeerMessageCount;
    final messageTabLabel =
        unreadMessages > 0 ? 'Messages ($unreadMessages)' : 'Messages';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(onMessagesTab ? 'Messages' : 'Connections'),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppGradients.campusPage),
        child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.accent],
                ),
                borderRadius: BorderRadius.circular(AppRadii.lg),
                boxShadow: glow(AppColors.primary,
                    alpha: 0.22, blurRadius: 18, offset: const Offset(0, 10)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.connect_without_contact,
                      color: Colors.white, size: 28),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          onMessagesTab
                              ? 'Campus inbox'
                              : 'AI-suggested peers',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        Text(
                          onMessagesTab
                              ? 'Text-only chats with your connections.'
                              : 'Match by major, interests and activity.',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color:
                                        Colors.white.withValues(alpha: 0.85),
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!onMessagesTab)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search by name, major or interest',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchCtrl.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() {});
                          },
                        ),
                ),
              ),
            ),
          if (!onMessagesTab) const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: PillTabBar(
              labels: ['Suggested', 'My Connections', messageTabLabel],
              selectedIndex: _segment,
              onSelected: (i) {
                setState(() => _segment = i);
                if (i == 2) {
                  context.read<AppState>().loadPeerInbox();
                }
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: onMessagesTab
                ? const PeerMessagesInboxPanel()
                : list.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Text(
                        _segment == 1
                            ? "You haven't connected with anyone yet."
                            : 'No matches.',
                        textAlign: TextAlign.center,
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl),
                    itemCount: list.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (_, i) => _ConnectionCard(
                      connection: list[i],
                      accent: AppAccents.at(i),
                    )
                        .animate()
                        .fadeIn(delay: (40 * i).ms)
                        .slideX(begin: 0.05, end: 0),
                  ),
          ),
        ],
        ),
      ),
    );
  }
}

class _ConnectionCard extends StatelessWidget {
  final Connection connection;
  final Color accent;
  const _ConnectionCard(
      {required this.connection, this.accent = AppColors.primary});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final connected = state.isConnected(connection.id);
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.lg),
      onTap: () => _showSheet(context),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: cardDecoration(),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.lerp(accent, Colors.white, 0.25)!,
                    accent,
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: glow(accent,
                    alpha: 0.22, blurRadius: 12, offset: const Offset(0, 5)),
              ),
              alignment: Alignment.center,
              child: Text(
                connection.initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    connection.name,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    '${connection.major} · ${connection.year}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  if (connection.interests.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          for (final t
                              in connection.interests.take(3))
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.12),
                                borderRadius:
                                    BorderRadius.circular(AppRadii.pill),
                                border: Border.all(
                                    color: accent.withValues(alpha: 0.28)),
                              ),
                              child: Text(t,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(color: accent)),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            if (connected) ...[
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    FadeSlidePageRoute(
                      builder: (_) =>
                          ConnectionChatScreen(connection: connection),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: accent,
                  side: BorderSide(color: accent.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: const Text('Message'),
              ),
              const SizedBox(width: 6),
              TextButton(
                onPressed: () async {
                  await context.read<AppState>().toggleConnection(connection.id);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Removed connection with ${connection.name}.')),
                  );
                },
                child: const Text('Remove'),
              ),
            ] else
              ElevatedButton(
                onPressed: () =>
                    context.read<AppState>().toggleConnection(connection.id),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  backgroundColor: accent,
                ),
                child: const Text('Connect'),
              ),
          ],
        ),
      ),
    );
  }

  void _showSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
      ),
      builder: (sheetCtx) {
        final state = sheetCtx.watch<AppState>();
        final connected = state.isConnected(connection.id);
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color.lerp(accent, Colors.white, 0.25)!,
                          accent,
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      connection.initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 28,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(connection.name,
                            style: Theme.of(sheetCtx)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800)),
                        Text(
                            '${connection.major} · ${connection.year}',
                            style:
                                Theme.of(sheetCtx).textTheme.bodyMedium?.copyWith(
                                      color: AppColors.textSecondary,
                                    )),
                        if (connection.quickTitle != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.14),
                                borderRadius:
                                    BorderRadius.circular(AppRadii.pill),
                              ),
                              child: Text(
                                connection.quickTitle!,
                                style: Theme.of(sheetCtx)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: accent,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Interests',
                  style: Theme.of(sheetCtx)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final t in connection.interests)
                    Chip(
                      label: Text(t),
                      backgroundColor: AppColors.surfaceMuted,
                    ),
                ],
              ),
              if (connected) ...[
                const SizedBox(height: AppSpacing.lg),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Why connect?',
                        style: Theme.of(sheetCtx)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _connectionUtility(state, connection),
                        style: Theme.of(sheetCtx).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              if (connected) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(sheetCtx).pop();
                      Navigator.of(context).push(
                        FadeSlidePageRoute(
                          builder: (_) =>
                              ConnectionChatScreen(connection: connection),
                        ),
                      );
                    },
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('Message'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final wasConnected = connected;
                    await sheetCtx
                        .read<AppState>()
                        .toggleConnection(connection.id);
                    if (!sheetCtx.mounted) return;
                    Navigator.of(sheetCtx).pop();
                    if (wasConnected && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Removed connection with ${connection.name}.',
                          ),
                        ),
                      );
                    }
                  },
                  icon: Icon(connected
                      ? Icons.person_remove_alt_1
                      : Icons.person_add_alt_1),
                  label: Text(connected ? 'Remove connection' : 'Connect'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        connected ? AppColors.danger : accent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _connectionUtility(AppState state, Connection connection) {
    final mine = state.profile?.interests ?? const <String>[];
    final shared = connection.interests
        .where((i) => mine.any((m) => m.toLowerCase() == i.toLowerCase()))
        .toList();
    if (shared.isNotEmpty) {
      return 'You both care about ${shared.take(3).join(', ')}. Invite them to a study session from Academics or share an event from Events.';
    }
    final profile = state.profile;
    if (profile != null &&
        connection.major.isNotEmpty &&
        profile.major.toLowerCase() == connection.major.toLowerCase()) {
      return 'Same major — pair up for study sessions or club events in ${connection.major}.';
    }
    return 'Use Connections to find study partners and event buddies. Check Academics for open study rooms.';
  }
}
