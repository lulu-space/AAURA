import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme/app_theme.dart';

class AdminContentScreen extends StatefulWidget {
  const AdminContentScreen({super.key});

  @override
  State<AdminContentScreen> createState() => _AdminContentScreenState();
}

class _AdminContentScreenState extends State<AdminContentScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = context.read<AppState>();
      state.refreshAdminData();
      if (state.allEvents.isEmpty || state.allClubs.isEmpty) {
        state.refreshAll();
      }
    });
  }

  Future<void> _snack(String? error, String success) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? success)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final content = state.adminContent;
    var events =
        (content?['events'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    var clubs =
        (content?['clubs'] as List?)?.cast<Map<String, dynamic>>() ?? const [];

    if (events.isEmpty && state.allEvents.isNotEmpty) {
      events = state.allEvents
          .map(
            (e) => {
              'id': e.id,
              'title': e.title,
              'status': e.status,
              'is_hidden': false,
              'organizer_id': e.organizerId,
            },
          )
          .toList();
    }
    if (clubs.isEmpty && state.allClubs.isNotEmpty) {
      clubs = state.allClubs
          .map(
            (c) => {
              'id': c.id,
              'name': c.name,
              'is_active': c.isActive,
              'organizer_id': c.organizerId,
            },
          )
          .toList();
    }

    final posts = (content?['posts'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    final messages =
        (content?['messages'] as List?)?.cast<Map<String, dynamic>>() ?? const [];

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Content moderation'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Events'),
              Tab(text: 'Clubs'),
              Tab(text: 'Posts'),
              Tab(text: 'Messages'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ModerationList(
              empty: 'No events.',
              items: events,
              title: (row) => row['title']?.toString() ?? 'Event',
              subtitle: (row) => '${row['status']} · hidden=${row['is_hidden'] == true}',
              buildActions: (index) => [
                _ModAction('Hide', () async {
                  final err = await context.read<AppState>().adminModerateEvent(
                        events[index]['id']?.toString() ?? '',
                        'hide',
                      );
                  await _snack(err, 'Event hidden.');
                }),
                _ModAction('Cancel', () async {
                  final err = await context.read<AppState>().adminModerateEvent(
                        events[index]['id']?.toString() ?? '',
                        'cancel',
                      );
                  await _snack(err, 'Event cancelled.');
                }),
              ],
            ),
            _ModerationList(
              empty: 'No clubs.',
              items: clubs,
              title: (row) => row['name']?.toString() ?? 'Club',
              subtitle: (row) => 'active=${row['is_active'] != false}',
              buildActions: (index) => [
                _ModAction('Deactivate', () async {
                  final err = await context.read<AppState>().adminModerateClub(
                        clubs[index]['id']?.toString() ?? '',
                        'deactivate',
                      );
                  await _snack(err, 'Club deactivated.');
                }),
                _ModAction('Reactivate', () async {
                  final err = await context.read<AppState>().adminModerateClub(
                        clubs[index]['id']?.toString() ?? '',
                        'reactivate',
                      );
                  await _snack(err, 'Club reactivated.');
                }),
              ],
            ),
            _ModerationList(
              empty: 'No posts.',
              items: posts,
              title: (row) => row['title']?.toString() ?? 'Post',
              subtitle: (row) => row['body']?.toString() ?? '',
              buildActions: (index) => [
                _ModAction('Hide', () async {
                  final err = await context.read<AppState>().adminModeratePost(
                        posts[index]['id']?.toString() ?? '',
                        hidden: true,
                      );
                  await _snack(err, 'Post hidden.');
                }),
              ],
            ),
            _ModerationList(
              empty: 'No messages.',
              items: messages,
              title: (row) => row['body']?.toString() ?? 'Message',
              subtitle: (row) => 'channel ${row['channel_id']} · hidden=${row['is_hidden'] == true}',
              buildActions: (index) => [
                _ModAction('Hide', () async {
                  final err = await context.read<AppState>().adminModerateMessage(
                        messages[index]['id']?.toString() ?? '',
                        hidden: true,
                      );
                  await _snack(err, 'Message hidden.');
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ModAction {
  final String label;
  final Future<void> Function() onTap;
  const _ModAction(this.label, this.onTap);
}

class _ModerationList extends StatelessWidget {
  final String empty;
  final List<Map<String, dynamic>> items;
  final String Function(Map<String, dynamic>) title;
  final String Function(Map<String, dynamic>) subtitle;
  final List<_ModAction> Function(int index) buildActions;

  const _ModerationList({
    required this.empty,
    required this.items,
    required this.title,
    required this.subtitle,
    required this.buildActions,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(child: Text(empty));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final row = items[index];
        final rowActions = buildActions(index);
        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: AppColors.surfaceMuted),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title(row),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(subtitle(row), style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  for (final action in rowActions)
                    OutlinedButton(
                      onPressed: action.onTap,
                      child: Text(action.label),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
