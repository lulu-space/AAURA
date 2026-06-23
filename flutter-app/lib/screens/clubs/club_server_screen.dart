import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/club_defaults.dart';
import '../../models/club.dart';
import '../../models/club_server.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/transitions.dart';
import '../../widgets/bird_avatar.dart';
import '../../widgets/event_card.dart';
import '../events/create_event_screen.dart';
import '../events/event_details_screen.dart';

const List<List<int>> _serverPoses = [
  [0, 2],
  [2, 2],
  [4, 0],
  [1, 2],
  [3, 0],
  [2, 1],
];

class ClubServerScreen extends StatefulWidget {
  final Club club;
  const ClubServerScreen({super.key, required this.club});

  @override
  State<ClubServerScreen> createState() => _ClubServerScreenState();
}

class _ClubServerScreenState extends State<ClubServerScreen> {
  int _channel = 0;
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  Club get _club => widget.club;
  Color get _accent => ClubCategoryStyle.accent(_club.category);
  ClubChannel get _activeChannel => kDefaultClubChannels[_channel];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadChannel());
  }

  void _loadChannel() {
    context
        .read<AppState>()
        .loadClubMessages(_club, _activeChannel.id);
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _jumpToBottom() {
    if (!_scrollCtrl.hasClients) return;
    _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
  }

  void _send() {
    final text = _msgCtrl.text;
    if (text.trim().isEmpty) return;
    final state = context.read<AppState>();
    if (_activeChannel.id == 'announcements' &&
        !state.canPostClubAnnouncements(_club.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only club leaders and officers can post announcements.'),
        ),
      );
      return;
    }
    state.sendClubMessage(_club, _activeChannel.id, text);
    _msgCtrl.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isLeader = state.isClubLeader(_club.id);
    final messages = state.clubChat(_club, _activeChannel.id);
    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToBottom());

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      endDrawer: _MembersDrawer(
        club: _club,
        isLeader: isLeader,
        currentUserName: state.profile?.name,
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _ServerHeader(
              club: _club,
              onOpenMembers: () => _scaffoldKey.currentState?.openEndDrawer(),
              onCreateEvent: isLeader
                  ? () => Navigator.of(context).push(
                        FadeSlidePageRoute(
                          builder: (_) =>
                              CreateEventScreen(clubId: _club.id),
                        ),
                      )
                  : null,
              onLeave: () async {
                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(context);
                await context.read<AppState>().toggleClubJoin(_club.id);
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(content: Text('Left ${_club.name}')),
                );
                navigator.maybePop();
              },
            ),
            _channelBar(),
            if (_activeChannel.id == 'events')
              Expanded(child: _eventsView(state, isLeader))
            else ...[
              Expanded(
                child: messages.isEmpty
                    ? Center(
                        child: Text(
                          'No messages yet. Say hi!',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.fromLTRB(AppSpacing.lg,
                            AppSpacing.md, AppSpacing.lg, AppSpacing.md),
                        itemCount: messages.length,
                        itemBuilder: (_, i) =>
                            _MessageBubble(message: messages[i], accent: _accent),
                      ),
              ),
              _inputBar(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _eventsView(AppState state, bool isLeader) {
    final events = state.eventsForClub(_club.id);
    if (events.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.event_outlined,
                  size: 44, color: _accent.withValues(alpha: 0.6)),
              const SizedBox(height: AppSpacing.md),
              Text(
                isLeader
                    ? 'No events yet. Tap the calendar icon above to create your first club event.'
                    : 'No events scheduled yet. Check back soon!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl),
      itemCount: events.length,
      itemBuilder: (_, i) {
        final event = events[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: EventCard(
            event: event,
            joined: state.isEventJoined(event.id),
            onView: () => Navigator.of(context).push(
              FadeSlidePageRoute(
                builder: (_) => EventDetailsScreen(event: event),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _channelBar() {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      alignment: Alignment.centerLeft,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: kDefaultClubChannels.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (_, i) {
          final ch = kDefaultClubChannels[i];
          final selected = i == _channel;
          return GestureDetector(
            onTap: () {
              setState(() => _channel = i);
              _loadChannel();
            },
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? _accent : AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(AppRadii.pill),
                boxShadow:
                    selected ? glow(_accent, alpha: 0.30, blurRadius: 12) : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(ch.icon,
                      size: 16,
                      color:
                          selected ? Colors.white : AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    ch.name,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: selected
                              ? Colors.white
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _inputBar() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
        child: Container(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 4, 4, 4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _msgCtrl,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  style: Theme.of(context).textTheme.bodyMedium,
                  decoration: InputDecoration(
                    isDense: true,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    hintText: 'Message #${_activeChannel.name}',
                    hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textMuted,
                        ),
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  onTap: _send,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _accent,
                      boxShadow: glow(_accent, alpha: 0.35, blurRadius: 14),
                    ),
                    child: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServerHeader extends StatelessWidget {
  final Club club;
  final VoidCallback onOpenMembers;
  final VoidCallback onLeave;
  final VoidCallback? onCreateEvent;

  const _ServerHeader({
    required this.club,
    required this.onOpenMembers,
    required this.onLeave,
    this.onCreateEvent,
  });

  @override
  Widget build(BuildContext context) {
    final pose = _serverPoses[club.id.hashCode.abs() % _serverPoses.length];
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppGradients.clubCategory(club.category),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppRadii.xl),
        ),
        boxShadow: glow(
          ClubCategoryStyle.accent(club.category),
          alpha: 0.30,
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppRadii.xl),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -10,
              top: 6,
              child: BirdSticker(size: 84, row: pose[0], col: pose[1]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm, AppSpacing.sm, AppSpacing.sm, AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back_rounded,
                            color: Colors.white),
                      ),
                      const Spacer(),
                      if (onCreateEvent != null)
                        IconButton(
                          tooltip: 'Create event',
                          onPressed: onCreateEvent,
                          icon: const Icon(Icons.add_circle_outline,
                              color: Colors.white),
                        ),
                      IconButton(
                        tooltip: 'Members',
                        onPressed: onOpenMembers,
                        icon: const Icon(Icons.people_alt_outlined,
                            color: Colors.white),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.white),
                        onSelected: (v) {
                          if (v == 'leave') onLeave();
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'leave',
                            child: Row(
                              children: [
                                Icon(Icons.logout_rounded),
                                SizedBox(width: 8),
                                Text('Leave club'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                        left: AppSpacing.sm, right: 80),
                    child: Text(
                      club.name,
                      style: playfulDisplay(
                        size: 24,
                        weight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.05,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.sm),
                    child: Row(
                      children: [
                        Icon(Icons.groups_outlined,
                            size: 14,
                            color: Colors.white.withValues(alpha: 0.9)),
                        const SizedBox(width: 4),
                        Text(
                          '${club.members} members  -  ${club.activityLevel.label}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ClubMessage message;
  final Color accent;
  const _MessageBubble({required this.message, required this.accent});

  @override
  Widget build(BuildContext context) {
    final isMe = message.isMe;
    final avatar = CircleAvatar(
      radius: 16,
      backgroundColor: accent.withValues(alpha: 0.18),
      child: Text(
        _initials(message.author),
        style: TextStyle(
          color: accent,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );

    final bubble = Column(
      crossAxisAlignment:
          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isMe ? 'You' : message.author,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            if (message.isLeader) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: Text(
                  'Leader',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
            const SizedBox(width: 6),
            Text(
              message.time,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: isMe ? accent : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: isMe ? null : Border.all(color: AppColors.divider),
          ),
          child: Text(
            message.text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isMe ? Colors.white : AppColors.textPrimary,
                  height: 1.3,
                ),
          ),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[avatar, const SizedBox(width: AppSpacing.sm)],
          Flexible(child: bubble),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}

class _MembersDrawer extends StatefulWidget {
  final Club club;
  final bool isLeader;
  final String? currentUserName;
  const _MembersDrawer({
    required this.club,
    this.isLeader = false,
    this.currentUserName,
  });

  @override
  State<_MembersDrawer> createState() => _MembersDrawerState();
}

class _MembersDrawerState extends State<_MembersDrawer> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().loadClubMembers(widget.club.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final accent = ClubCategoryStyle.accent(widget.club.category);
    final state = context.watch<AppState>();
    final members = state.clubMembers(widget.club);
    final leaders = [
      if (widget.isLeader)
        ClubMember(
          name: '${widget.currentUserName ?? 'You'} (You)',
          role: 'Leader',
          online: true,
        ),
      ...members.where((m) => m.isLeader),
    ];
    final regular = members.where((m) => !m.isLeader).toList();

    return Drawer(
      backgroundColor: AppColors.background,
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration:
                  BoxDecoration(gradient: AppGradients.clubCategory(widget.club.category)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About',
                    style: playfulDisplay(
                      size: 20,
                      weight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    widget.club.description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.92),
                      height: 1.4,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _aboutRow(Icons.groups_outlined, '${widget.club.members} members'),
                  _aboutRow(Icons.bolt_outlined,
                      'Activity: ${widget.club.activityLevel.label}'),
                  if (widget.club.nextEvent != null)
                    _aboutRow(Icons.event_outlined, widget.club.nextEvent!),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _sectionLabel(context, 'Leaders - ${leaders.length}'),
            for (final m in leaders) _memberTile(context, m, accent),
            const SizedBox(height: AppSpacing.sm),
            _sectionLabel(context, 'Members - ${regular.length}'),
            for (final m in regular) _memberTile(context, m, accent),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _aboutRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 15, color: Colors.white.withValues(alpha: 0.9)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xs),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
      ),
    );
  }

  Widget _memberTile(BuildContext context, ClubMember m, Color accent) {
    return ListTile(
      dense: true,
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: accent.withValues(alpha: 0.18),
            child: Text(
              m.initials,
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: m.online ? AppColors.success : AppColors.textMuted,
                border: Border.all(color: AppColors.background, width: 2),
              ),
            ),
          ),
        ],
      ),
      title: Text(
        m.name,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
      subtitle: Text(
        m.online ? 'Online' : 'Offline',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: m.online ? AppColors.success : AppColors.textMuted,
            ),
      ),
    );
  }
}
