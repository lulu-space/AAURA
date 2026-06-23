import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/event.dart';
import '../../models/volunteer_request.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/transitions.dart';
import '../../widgets/bird_avatar.dart';
import '../../widgets/club_card.dart';
import '../../widgets/event_card.dart';
import '../../widgets/forest_scene.dart';
import '../../widgets/stat_chip.dart';
import '../events/event_details_screen.dart';
import '../staff/approvals_screen.dart';
import '../staff/club_request_reviews_screen.dart';
import '../staff/event_reviews_screen.dart';
import '../staff/manage_events_screen.dart';
import '../staff/manage_volunteer_opportunities_screen.dart';
import 'feed_screen.dart';
import 'leaderboard_screen.dart';

// Mascot sheet cells (row, col, 0-indexed) cycled across the trending tiles.
const List<List<int>> _trendPoses = [
  [0, 2],
  [2, 2],
  [4, 0],
  [1, 2],
  [3, 0],
  [2, 1],
];

// Pastel tints cycled across trending cards (same palette as study sessions).
const List<Color> _trendTints = [
  Color(0xFFF4C9A0),
  Color(0xFFE9B6B4),
  Color(0xFFD9C2E0),
  Color(0xFFF2D6A8),
];

class HomeScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigate;
  const HomeScreen({super.key, this.onNavigate});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (state.isStudentAffairs && !state.isAdmin) {
      return _AffairsHome(onNavigate: widget.onNavigate);
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppPalette.dawnTop, AppColors.background],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xxl,
            ),
            children: [
              const _ForestHero()
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.05, end: 0),
              const SizedBox(height: AppSpacing.lg),
              const _SectionLabel('Trending now'),
              const SizedBox(height: 4),
              Text(
                'Matched to your interests and skills — not club activity.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _TrendingStrip(
                events: state.trendingEventsForHome,
                showCta: !state.isStaffOrAffairs,
                onEventTap: (e) => Navigator.of(context).push(
                  FadeSlidePageRoute(
                    builder: (_) => EventDetailsScreen(event: e),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _QuickLinksRow(
                onLeaderboard: () => Navigator.of(context).push(
                  FadeSlidePageRoute(builder: (_) => const LeaderboardScreen()),
                ),
                onFeed: () => Navigator.of(context).push(
                  FadeSlidePageRoute(builder: (_) => const FeedScreen()),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _CollapsibleSection(
                title: 'Events for you',
                subtitle: state.personalizationSkillNames.isNotEmpty ||
                        (state.profile?.interests.isNotEmpty ?? false)
                    ? 'Matched to your interests and skills'
                    : 'Based on your major and campus profile',
                initiallyExpanded: true,
                child: _SuggestedEvents(),
              ),
              const SizedBox(height: AppSpacing.md),
              _CollapsibleSection(
                title: 'Clubs for you',
                subtitle: state.personalizationSkillNames.isNotEmpty ||
                        (state.profile?.interests.isNotEmpty ?? false)
                    ? 'Matched to your interests and skills'
                    : 'Based on your major and interests',
                child: _SuggestedClubs(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hero
// ---------------------------------------------------------------------------

class _ForestHero extends StatelessWidget {
  const _ForestHero();

  @override
  Widget build(BuildContext context) {
    final titleColor = AppColors.background;
    final scrimColor = AppPalette.dawnLow;
    return SizedBox(
      height: 214,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.xl),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ForestScene(reveal: 1.0),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.center,
                  end: Alignment.bottomCenter,
                  colors: [
                    scrimColor.withValues(alpha: 0.0),
                    scrimColor.withValues(alpha: 0.66),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Discover',
                    style: GoogleFonts.cinzel(
                      color: titleColor,
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 6,
                      height: 1.0,
                      shadows: [
                        Shadow(
                          color: scrimColor.withValues(alpha: 0.8),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Find your people. Grow your story.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: titleColor.withValues(alpha: 0.88),
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 1.2,
                      shadows: [
                        Shadow(
                          color: scrimColor.withValues(alpha: 0.7),
                          blurRadius: 10,
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

// ---------------------------------------------------------------------------
// Section label
// ---------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(
        color: AppColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Trending strip (events only, inspo-style numbered cards with a peeking bird)
// ---------------------------------------------------------------------------

class _TrendingStrip extends StatelessWidget {
  final List<Event> events;
  final ValueChanged<Event> onEventTap;
  final bool showCta;

  const _TrendingStrip({
    required this.events,
    required this.onEventTap,
    this.showCta = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 248,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: events.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (_, i) {
          final e = events[i];
          final pose = _trendPoses[i % _trendPoses.length];
          final tint = _trendTints[i % _trendTints.length];
          return _TrendingCard(
            event: e,
            tint: tint,
            poseRow: pose[0],
            poseCol: pose[1],
            showCta: showCta,
            onTap: () => onEventTap(e),
          )
              .animate()
              .fadeIn(delay: (60 * i).ms, duration: 350.ms)
              .slideX(begin: 0.12, end: 0);
        },
      ),
    );
  }
}

class _TrendingCard extends StatelessWidget {
  final Event event;
  final Color tint;
  final int poseRow;
  final int poseCol;
  final VoidCallback onTap;
  final bool showCta;

  const _TrendingCard({
    required this.event,
    required this.tint,
    required this.poseRow,
    required this.poseCol,
    required this.onTap,
    this.showCta = true,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final favorited = state.isEventFavorite(event.id);
    final subtitle = event.about.trim().isNotEmpty
        ? event.about.trim()
        : event.date;
    final gradientBottom = Color.lerp(tint, AppPalette.ink, 0.18)!;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 188,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [tint, gradientBottom],
          ),
          borderRadius: BorderRadius.circular(AppRadii.xl),
          boxShadow: [
            BoxShadow(
              color: AppPalette.ink.withValues(alpha: 0.18),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: -8,
              right: -8,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.14),
                ),
                child: IgnorePointer(
                  child: BirdSticker(row: poseRow, col: poseCol, size: 64),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _TrendTag(
                        icon: Icons.auto_awesome_outlined,
                        label: '+${event.points} pts',
                        ink: true,
                      ),
                      _TrendTag(
                        icon: event.category.icon,
                        label: event.category.label,
                        ink: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    event.title.toLowerCase(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: AppPalette.ink,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: AppPalette.ink.withValues(alpha: 0.72),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1.25,
                    ),
                  ),
                  const Spacer(),
                  if (showCta)
                    Row(
                      children: [
                        Expanded(
                          child: Material(
                            color: AppPalette.ink,
                            borderRadius: BorderRadius.circular(AppRadii.pill),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(AppRadii.pill),
                              onTap: onTap,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 9,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 16,
                                      color: AppPalette.cream,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'View Details',
                                      style: GoogleFonts.inter(
                                        color: AppPalette.cream,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Material(
                          color: Colors.white.withValues(alpha: 0.35),
                          shape: const CircleBorder(
                            side: BorderSide(color: Colors.white54),
                          ),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => state.toggleFavoriteEvent(event.id),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Icon(
                                favorited
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                color: AppPalette.ink,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
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

class _TrendTag extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool ink;

  const _TrendTag({
    required this.icon,
    required this.label,
    this.ink = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = ink ? AppPalette.ink : Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(
          color: ink
              ? Colors.white.withValues(alpha: 0.55)
              : Colors.white.withValues(alpha: 0.65),
        ),
        color: ink
            ? Colors.white.withValues(alpha: 0.30)
            : Colors.white.withValues(alpha: 0.12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              color: fg,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quick links (Leaderboard + Feed only)
// ---------------------------------------------------------------------------

class _QuickLinksRow extends StatelessWidget {
  final VoidCallback onLeaderboard;
  final VoidCallback onFeed;

  const _QuickLinksRow({required this.onLeaderboard, required this.onFeed});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _QuickTile(
          icon: Icons.emoji_events_outlined,
          label: 'Leaderboard',
          onTap: onLeaderboard,
        ),
        const SizedBox(width: AppSpacing.md),
        _QuickTile(
          icon: Icons.feed_outlined,
          label: 'Feed',
          onTap: onFeed,
        ),
      ],
    );
  }
}

class _QuickTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickTile(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.14),
                ),
                child: Icon(icon, size: 21, color: AppColors.primary),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Collapsible section
// ---------------------------------------------------------------------------

class _CollapsibleSection extends StatefulWidget {
  final String title;
  final String? subtitle;
  final bool initiallyExpanded;
  final Widget child;

  const _CollapsibleSection({
    required this.title,
    this.subtitle,
    this.initiallyExpanded = false,
    required this.child,
  });

  @override
  State<_CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<_CollapsibleSection> {
  late bool _open = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final panel = Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: GoogleFonts.inter(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                        if (widget.subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.subtitle!,
                            style: GoogleFonts.inter(
                              color: AppColors.textMuted,
                              fontSize: 11.5,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 220),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.primary,
                      size: 26,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ClipRect(
            child: AnimatedAlign(
              alignment: Alignment.topCenter,
              heightFactor: _open ? 1 : 0,
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeInOut,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                child: widget.child,
              ),
            ),
          ),
        ],
      ),
    );

    return panel;
  }
}

// ---------------------------------------------------------------------------
// Section bodies (flow/handlers preserved from the original dashboard)
// ---------------------------------------------------------------------------

class _SuggestedEvents extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final events = state.suggestedEvents;
    if (events.isEmpty) {
      return Text(
        'No matching events yet. Add interests or skills on your profile.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < events.length; i++) ...[
          EventCard(
            event: events[i],
            joined: state.isEventJoined(events[i].id),
            favorite: state.isEventFavorite(events[i].id),
            onFavorite: state.isStaffOrAffairs
                ? null
                : () =>
                    context.read<AppState>().toggleFavoriteEvent(events[i].id),
            onView: () {
              Navigator.of(context).push(
                FadeSlidePageRoute(
                  builder: (_) => EventDetailsScreen(event: events[i]),
                ),
              );
            },
          ),
          if (i != events.length - 1) const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _SuggestedClubs extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final clubs = state.suggestedClubs;
    if (clubs.isEmpty) {
      return Text(
        'No clubs to suggest yet.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < clubs.length; i++) ...[
          ClubCard(
            club: clubs[i],
            joined: state.isClubJoined(clubs[i].id),
            onJoin: state.isStaffOrAffairs
                ? null
                : () => context.read<AppState>().toggleClubJoin(clubs[i].id),
          ),
          if (i != clubs.length - 1) const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Student Affairs dashboard (no suggested clubs/events)
// ---------------------------------------------------------------------------

class _AffairsHome extends StatelessWidget {
  final ValueChanged<int>? onNavigate;
  const _AffairsHome({this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final pendingVolunteer = state.volunteerRequests
        .where((r) => r.status == VolunteerRequestStatus.pending)
        .length;
    final pendingEvents = state.pendingEventReviewCount;
    final pendingClubs = state.pendingClubRequestCount;
    final name = (state.profile?.name ?? 'Student Affairs').split(' ').first;
    final trending = state.trendingEventsForHome;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppPalette.dawnTop, AppColors.background],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xxl,
            ),
            children: [
              Text(
                'Hello, $name',
                style: playfulDisplay(
                  size: 28,
                  weight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ).animate().fadeIn(duration: 400.ms),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Student Affairs dashboard',
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  if (pendingVolunteer > 0)
                    _AffairsStatChip(
                      icon: Icons.verified_outlined,
                      label: '$pendingVolunteer volunteer pending',
                      accent: AppColors.accent,
                    ),
                  if (pendingEvents > 0)
                    _AffairsStatChip(
                      icon: Icons.event_outlined,
                      label: '$pendingEvents event reviews',
                      accent: AppColors.primary,
                    ),
                  if (pendingClubs > 0)
                    _AffairsStatChip(
                      icon: Icons.groups_outlined,
                      label: '$pendingClubs club requests',
                      accent: const Color(0xFF5BA316),
                    ),
                  _AffairsStatChip(
                    icon: Icons.event_available,
                    label: '${state.allEvents.length} campus events',
                  ),
                  _AffairsStatChip(
                    icon: Icons.groups,
                    label: '${state.allClubs.length} clubs',
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              const _SectionLabel('Trending now'),
              const SizedBox(height: AppSpacing.sm),
              if (trending.isEmpty)
                Text(
                  'No campus events to show yet.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                )
              else
                _TrendingStrip(
                  events: trending,
                  showCta: false,
                  onEventTap: (e) => Navigator.of(context).push(
                    FadeSlidePageRoute(
                      builder: (_) => EventDetailsScreen(event: e),
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),
              _QuickLinksRow(
                onLeaderboard: () => Navigator.of(context).push(
                  FadeSlidePageRoute(builder: (_) => const LeaderboardScreen()),
                ),
                onFeed: () => Navigator.of(context).push(
                  FadeSlidePageRoute(builder: (_) => const FeedScreen()),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _AffairsFeedPreview(
                items: state.feedItems.take(4).toList(),
                onSeeAll: () => Navigator.of(context).push(
                  FadeSlidePageRoute(builder: (_) => const FeedScreen()),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const _SectionLabel('Quick actions'),
              const SizedBox(height: AppSpacing.sm),
              _AffairsActionTile(
                icon: Icons.event_note_outlined,
                title: 'Manage Events',
                subtitle: 'Create and edit your campus events',
                onTap: () => Navigator.of(context).push(
                  FadeSlidePageRoute(builder: (_) => const ManageEventsScreen()),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _AffairsActionTile(
                icon: Icons.campaign_outlined,
                title: 'Volunteer Opportunities',
                subtitle: state.openManagedVolunteerOpportunityCount > 0
                    ? '${state.openManagedVolunteerOpportunityCount} open announcements'
                    : 'Announce service roles for students',
                onTap: () => Navigator.of(context).push(
                  FadeSlidePageRoute(
                    builder: (_) => const ManageVolunteerOpportunitiesScreen(),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _AffairsActionTile(
                icon: Icons.verified_outlined,
                title: 'Volunteer Approvals',
                subtitle: pendingVolunteer > 0
                    ? '$pendingVolunteer submissions awaiting review'
                    : 'Approve, reject, or withdraw volunteer hours',
                badge: pendingVolunteer,
                onTap: () => Navigator.of(context).push(
                  FadeSlidePageRoute(builder: (_) => const ApprovalsScreen()),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _AffairsActionTile(
                icon: Icons.event_outlined,
                title: 'Event Reviews',
                subtitle: pendingEvents > 0
                    ? '$pendingEvents student events awaiting review'
                    : 'Approve, reject, or withdraw student events',
                badge: pendingEvents,
                onTap: () => Navigator.of(context).push(
                  FadeSlidePageRoute(builder: (_) => const EventReviewsScreen()),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _AffairsActionTile(
                icon: Icons.groups_outlined,
                title: 'Club Requests',
                subtitle: pendingClubs > 0
                    ? '$pendingClubs founding requests pending'
                    : 'Approve, decline, or revoke club proposals',
                badge: pendingClubs,
                onTap: () => Navigator.of(context).push(
                  FadeSlidePageRoute(
                    builder: (_) => const ClubRequestReviewsScreen(),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const _SectionLabel('Browse campus'),
              const SizedBox(height: AppSpacing.sm),
              _AffairsActionTile(
                icon: Icons.event,
                title: 'All Events',
                subtitle: 'View every published campus event',
                onTap: () => onNavigate?.call(1),
              ),
              const SizedBox(height: AppSpacing.sm),
              _AffairsActionTile(
                icon: Icons.groups,
                title: 'All Clubs',
                subtitle: 'View every active campus club',
                onTap: () => onNavigate?.call(2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AffairsStatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? accent;

  const _AffairsStatChip({
    required this.icon,
    required this.label,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final color = accent ?? AppColors.primary;
    return StatChip(
      icon: icon,
      label: label,
      background: color.withValues(alpha: 0.14),
      foreground: color,
    );
  }
}

class _AffairsFeedPreview extends StatelessWidget {
  final List<Map<String, String>> items;
  final VoidCallback onSeeAll;

  const _AffairsFeedPreview({
    required this.items,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: _SectionLabel('Feed')),
            TextButton(onPressed: onSeeAll, child: const Text('See all')),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (items.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: cardDecoration(),
            child: Text(
              'Campus activity will appear here — approvals, events, and club updates.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          )
        else
          for (final item in items) ...[
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppRadii.pill),
                        ),
                        child: Text(
                          item['category']?.toString() ?? 'Campus',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        item['when']?.toString() ?? item['date']?.toString() ?? '',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    item['title']?.toString() ?? '',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  if ((item['body']?.toString() ?? '').isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item['body'].toString(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ],
      ],
    );
  }
}

class _AffairsActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final int badge;

  const _AffairsActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              if (badge > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                  child: Text(
                    '$badge',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
