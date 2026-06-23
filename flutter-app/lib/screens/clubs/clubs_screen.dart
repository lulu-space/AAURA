import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../models/club_request.dart';
import '../../models/club.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/transitions.dart';
import '../../widgets/bird_avatar.dart';
import '../../widgets/club_grid_card.dart';
import '../../widgets/dawn_scene.dart';
import '../../widgets/glow_widgets.dart';
import 'club_request_form_screen.dart';
import 'club_server_screen.dart';

const List<List<int>> _sheetPoses = [
  [0, 2],
  [2, 2],
  [4, 0],
  [1, 2],
  [3, 0],
  [2, 1],
];

class ClubsScreen extends StatefulWidget {
  const ClubsScreen({super.key});

  @override
  State<ClubsScreen> createState() => _ClubsScreenState();
}

class _ClubsScreenState extends State<ClubsScreen> {
  int _segment = 0; // 0 = Discover, 1 = My Clubs
  ClubCategory? _category; // null = All
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppGradients.campusPage),
        child: Stack(
          children: [
            Positioned.fill(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: const DawnScene(reveal: 1.0),
              ),
            ),
            Positioned.fill(
              child: ColoredBox(
                color: AppColors.background.withValues(alpha: 0.45),
              ),
            ),
            SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: GlowSearchBar(
                              controller: _searchCtrl,
                              hintText: 'Search for clubs...',
                              onChanged: (v) => setState(() => _query = v),
                              onClear: () {
                                _searchCtrl.clear();
                                setState(() => _query = '');
                              },
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          _categoryFilter(),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _segmentChips(state),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ),
                ),
                Expanded(child: _buildBody(state)),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _categoryFilter() {
    final accent = _category == null
        ? AppColors.primary
        : ClubCategoryStyle.accent(_category!);
    final icon = _category?.icon ?? Icons.tune_rounded;
    final label = _category?.label ?? 'All';

    return PopupMenuButton<int>(
      tooltip: 'Filter by type',
      offset: const Offset(0, 52),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      onSelected: (v) => setState(
        () => _category = v < 0 ? null : ClubCategory.values[v],
      ),
      itemBuilder: (_) => [
        _filterItem(-1, Icons.tune_rounded, 'All', AppColors.primary),
        for (int i = 0; i < ClubCategory.values.length; i++)
          _filterItem(
            i,
            ClubCategory.values[i].icon,
            ClubCategory.values[i].label,
            ClubCategoryStyle.accent(ClubCategory.values[i]),
          ),
      ],
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          border: Border.all(color: AppColors.divider),
          boxShadow: glow(accent,
              alpha: 0.12, blurRadius: 14, offset: const Offset(0, 6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: accent),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.keyboard_arrow_down_rounded,
                size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<int> _filterItem(
      int value, IconData icon, String label, Color accent) {
    final selected = (value < 0 && _category == null) ||
        (value >= 0 && _category == ClubCategory.values[value]);
    return PopupMenuItem<int>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: accent),
          const SizedBox(width: AppSpacing.sm),
          Text(label,
              style: TextStyle(
                fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
              )),
          if (selected) ...[
            const Spacer(),
            Icon(Icons.check_rounded, size: 16, color: accent),
          ],
        ],
      ),
    );
  }

  Widget _segmentChips(AppState state) {
    if (!state.canJoinOrCreateClubs) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Browse campus clubs',
          style: playfulDisplay(
            size: 16,
            weight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      );
    }
    const labels = ['Discover', 'My Clubs'];
    const icons = [Icons.auto_awesome, Icons.favorite_rounded];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        children: [
          for (int i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _segment = i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color:
                        _segment == i ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                    boxShadow: _segment == i
                        ? glow(AppColors.primary, alpha: 0.30, blurRadius: 14)
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icons[i],
                          size: 15,
                          color: _segment == i
                              ? Colors.white
                              : AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        labels[i],
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: _segment == i
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _matches(Club c) {
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty &&
        !(c.name.toLowerCase().contains(q) ||
            c.focus.toLowerCase().contains(q))) {
      return false;
    }
    if (_category != null && c.category != _category) return false;
    return true;
  }

  Widget _buildBody(AppState state) {
    if (state.canJoinOrCreateClubs && _segment == 1) {
      return _buildMyClubs(state);
    }
    final clubs = state.allClubs.where(_matches).toList();
    if (clubs.isEmpty) {
      return _emptyMessage('No clubs match your search.');
    }

    final children = <Widget>[];
    if (_category == null) {
      for (final cat in ClubCategory.values) {
        final inCat = clubs.where((c) => c.category == cat).toList();
        if (inCat.isEmpty) continue;
        children.add(_sectionTitle(cat.label));
        children.add(const SizedBox(height: AppSpacing.sm));
        children.add(_grid(inCat, state));
        children.add(const SizedBox(height: AppSpacing.lg));
      }
    } else {
      children.add(_grid(clubs, state));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl),
      children: children,
    );
  }

  Widget _buildMyClubs(AppState state) {
    final led = state.allClubs
        .where((c) => state.isClubLeader(c.id) && _matches(c))
        .toList();
    final member = state.allClubs
        .where((c) =>
            state.isClubJoined(c.id) &&
            !state.isClubLeader(c.id) &&
            _matches(c))
        .toList();

    final children = <Widget>[
      if (state.canJoinOrCreateClubs) ...[
        Row(
          children: [
            Expanded(
              child: Text(
                state.useBackendData
                    ? 'Start a club'
                    : 'Start your own',
                style: playfulDisplay(
                  size: 18,
                  weight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            GlowIconButton(
              icon: Icons.add_rounded,
              tooltip: state.useBackendData
                  ? 'Request a new club'
                  : 'Create a club',
              onTap: () => _openStartClubFlow(context, state),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    ];

    final pendingRequests = state.myClubRequests
        .where((r) => r.status == ClubRequestStatus.pending)
        .toList();
    if (pendingRequests.isNotEmpty) {
      children.add(_pendingRequestsCard(pendingRequests));
      children.add(const SizedBox(height: AppSpacing.md));
    }

    if (led.isEmpty && member.isEmpty) {
      children.add(_emptyCard(
        state.useBackendData && !state.isStudentAffairs
            ? 'You haven\'t joined any clubs yet.\nDiscover clubs on the Discover tab, or tap + to submit a founding request for staff review.'
            : 'You haven\'t joined any clubs yet.\nDiscover some on the Discover tab, or tap + to start your own.',
      ));
    } else {
      if (led.isNotEmpty) {
        children.add(_sectionTitle('Clubs you lead'));
        children.add(const SizedBox(height: AppSpacing.sm));
        children.add(_ledStrip(led, state));
        children.add(const SizedBox(height: AppSpacing.lg));
      }
      if (member.isNotEmpty) {
        children.add(_sectionTitle('Clubs you\'re in'));
        children.add(const SizedBox(height: AppSpacing.sm));
        children.add(_grid(member, state));
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl),
      children: children,
    );
  }

  Widget _ledStrip(List<Club> clubs, AppState state) {
    return SizedBox(
      height: 188,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: clubs.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (_, i) {
          final club = clubs[i];
          return SizedBox(
            width: 168,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClubGridCard(
                    club: club,
                    joined: true,
                    seed: i,
                    onTap: () => Navigator.of(context).push(
                      FadeSlidePageRoute(
                        builder: (_) => ClubServerScreen(club: club),
                      ),
                    ),
                  ),
                ),
                const Positioned(top: 8, right: 8, child: _LeaderBadge()),
              ],
            ),
          )
              .animate()
              .fadeIn(delay: (50 * i).ms, duration: 280.ms)
              .slideX(begin: 0.1, end: 0);
        },
      ),
    );
  }

  Widget _emptyMessage(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppColors.textSecondary),
        ),
      ),
    );
  }

  Widget _emptyCard(String message) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: cardDecoration(),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
      ),
    );
  }

  void _openStartClubFlow(BuildContext context, AppState state) {
    if (!state.canJoinOrCreateClubs) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Student Affairs can browse clubs only — use Club Requests to review proposals.',
          ),
        ),
      );
      return;
    }
    if (state.isStudentAffairs) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Student Affairs reviews club requests — students submit founding proposals for approval.',
          ),
        ),
      );
      return;
    }
    if (AppConfig.backendEnabled && state.authenticated && state.isStudent) {
      final eligibility = state.clubRequestEligibility;
      if (eligibility != null && !eligibility.eligible) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(eligibility.primaryReason)),
        );
        return;
      }
      if (state.myClubRequests
          .any((r) => r.status == ClubRequestStatus.pending)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You already have a pending club request.'),
          ),
        );
        return;
      }
      Navigator.of(context).push(
        FadeSlidePageRoute(builder: (_) => const ClubRequestFormScreen()),
      );
      return;
    }
    _showCreateClubSheet(context);
  }

  Widget _pendingRequestsCard(List<ClubRequest> requests) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: cardDecoration(color: AppColors.accentLight.withValues(alpha: 0.35)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.hourglass_top_outlined, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Pending review',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final r in requests)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '"${r.proposedName}" — submitted ${r.submittedWhen.isNotEmpty ? r.submittedWhen : "recently"}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ),
          Text(
            'Student Affairs will notify you when reviewed.',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textMuted,
                ),
          ),
        ],
      ),
    );
  }

  void _showCreateClubSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
      ),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
        ),
        child: _CreateClubSheet(
          onCreate: (name, description, focus, category, roles) async {
            final navigator = Navigator.of(sheetCtx);
            final messenger = ScaffoldMessenger.of(context);
            final id = await sheetCtx.read<AppState>().createClub(
                  name: name,
                  description: description,
                  focus: focus,
                  category: category,
                  roles: roles,
                );
            navigator.pop();
            if (!mounted) return;
            if (id == null) {
              final isStudent = sheetCtx.read<AppState>().isStudent;
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    isStudent
                        ? 'Pending approval from Student Affairs. Use + to submit a founding request.'
                        : 'Could not create club. A club organizer account is required.',
                  ),
                ),
              );
              return;
            }
            setState(() => _segment = 1);
            final club = context.read<AppState>().clubById(id);
            if (club == null) return;
            Navigator.of(context).push(
              FadeSlidePageRoute(builder: (_) => ClubServerScreen(club: club)),
            );
          },
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Text(
          title,
          style: playfulDisplay(
            size: 18,
            weight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _grid(List<Club> clubs, AppState state) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 1.0,
      ),
      itemCount: clubs.length,
      itemBuilder: (_, i) {
        final club = clubs[i];
        return ClubGridCard(
          club: club,
          joined: state.isClubJoined(club.id),
          seed: i,
          onTap: () => _openClub(club, state),
        )
            .animate()
            .fadeIn(delay: (40 * i).ms, duration: 280.ms)
            .slideY(begin: 0.06, end: 0);
      },
    );
  }

  void _openClub(Club club, AppState state) {
    final inMyNetwork =
        state.isClubJoined(club.id) || state.isClubLeader(club.id);
    if (inMyNetwork && state.canJoinOrCreateClubs) {
      Navigator.of(context).push(
        FadeSlidePageRoute(builder: (_) => ClubServerScreen(club: club)),
      );
    } else {
      _showClubSheet(context, club, viewOnly: !state.canJoinOrCreateClubs);
    }
  }

  void _showClubSheet(
    BuildContext context,
    Club club, {
    bool viewOnly = false,
  }) {
    final accent = ClubCategoryStyle.accent(club.category);
    final pose = _sheetPoses[club.id.hashCode.abs() % _sheetPoses.length];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
      ),
      builder: (sheetCtx) {
        final joined = sheetCtx.watch<AppState>().isClubJoined(club.id);
        return SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SheetHeader(club: club, pose: pose),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        club.description,
                        style:
                            Theme.of(sheetCtx).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                  height: 1.4,
                                ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text('Roles available',
                          style: Theme.of(sheetCtx)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      for (final r in club.roles)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.circle, size: 7, color: accent),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(r,
                                    style: Theme.of(sheetCtx)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                            color: AppColors.textSecondary)),
                              ),
                            ],
                          ),
                        ),
                      if (club.nextEvent != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(AppRadii.md),
                            border: Border.all(
                                color: accent.withValues(alpha: 0.20)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.event_outlined, color: accent),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text('Next event: ${club.nextEvent}',
                                    style: Theme.of(sheetCtx)
                                        .textTheme
                                        .bodyMedium),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      if (viewOnly)
                        Text(
                          'Browse only for Student Affairs — review founding '
                          'requests from Profile → Club Requests.',
                          style: Theme.of(sheetCtx).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.35,
                              ),
                        )
                      else
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              sheetCtx.read<AppState>().toggleClubJoin(club.id);
                              Navigator.of(sheetCtx).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: joined
                                  ? accent.withValues(alpha: 0.45)
                                  : accent,
                            ),
                            icon: Icon(joined
                                ? Icons.check_circle
                                : Icons.group_add_outlined),
                            label: Text(joined ? 'Leave club' : 'Join club'),
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

class _SheetHeader extends StatelessWidget {
  final Club club;
  final List<int> pose;
  const _SheetHeader({required this.club, required this.pose});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppGradients.clubCategory(club.category),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadii.xl),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadii.xl),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -28,
              bottom: -40,
              child: _Blob(size: 130, alpha: 0.12),
            ),
            Positioned(
              right: 6,
              top: 18,
              child: BirdSticker(size: 104, row: pose[0], col: pose[1]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      _chip(club.category.icon, club.category.label),
                      const SizedBox(width: AppSpacing.sm),
                      _chip(Icons.groups_outlined, '${club.members}'),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Padding(
                    padding: const EdgeInsets.only(right: 84),
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
                  Text(
                    'Activity Level: ${club.activityLevel.label}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
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

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  final double size;
  final double alpha;
  const _Blob({required this.size, required this.alpha});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: alpha),
      ),
    );
  }
}

class _LeaderBadge extends StatelessWidget {
  const _LeaderBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 13, color: Colors.white),
          SizedBox(width: 4),
          Text(
            'Leader',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

typedef _CreateClubCallback = Future<void> Function(
  String name,
  String description,
  String focus,
  ClubCategory category,
  List<String> roles,
);

class _CreateClubSheet extends StatefulWidget {
  final _CreateClubCallback onCreate;
  const _CreateClubSheet({required this.onCreate});

  @override
  State<_CreateClubSheet> createState() => _CreateClubSheetState();
}

class _CreateClubSheetState extends State<_CreateClubSheet> {
  final _name = TextEditingController();
  final _focus = TextEditingController();
  final _description = TextEditingController();
  final _roles = TextEditingController();
  ClubCategory _category = ClubCategory.academic;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _focus.dispose();
    _description.dispose();
    _roles.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Give your club a name first.')),
      );
      return;
    }
    setState(() => _busy = true);
    final roles = _roles.text
        .split(',')
        .map((r) => r.trim())
        .where((r) => r.isNotEmpty)
        .toList();
    await widget.onCreate(
      _name.text.trim(),
      _description.text.trim().isEmpty
          ? 'A brand new community on AAURA.'
          : _description.text.trim(),
      _focus.text.trim().isEmpty ? 'Community' : _focus.text.trim(),
      _category,
      roles,
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = ClubCategoryStyle.accent(_category);
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
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
            Text(
              'Create a club',
              style: playfulDisplay(
                size: 22,
                weight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Set it up like your own server. You will be its leader.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _name,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Club name'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _focus,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Focus (one line)',
                hintText: 'e.g. Robotics and hardware tinkering',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _description,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _roles,
              decoration: const InputDecoration(
                labelText: 'Roles members can take (optional)',
                hintText: 'comma separated, e.g. Mentor, Designer',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Category',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final cat in ClubCategory.values)
                  ChoiceChip(
                    label: Text(cat.label),
                    avatar: Icon(
                      cat.icon,
                      size: 16,
                      color: _category == cat
                          ? Colors.white
                          : ClubCategoryStyle.accent(cat),
                    ),
                    selected: _category == cat,
                    selectedColor: ClubCategoryStyle.accent(cat),
                    labelStyle: TextStyle(
                      color: _category == cat
                          ? Colors.white
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                    onSelected: (_) => setState(() => _category = cat),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _busy ? null : _submit,
                style: ElevatedButton.styleFrom(backgroundColor: accent),
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.add_rounded),
                label: const Text('Create club'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
