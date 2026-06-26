import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/volunteer_request.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/transitions.dart';
import '../../widgets/bird_avatar.dart';
import '../../widgets/glow_widgets.dart';
import '../../widgets/gradient_hero.dart';
import '../../widgets/section_header.dart';
import '../../widgets/skill_actions.dart';
import '../../widgets/skill_progress_card.dart';
import '../../widgets/stat_chip.dart';
import '../academics/skill_progress_screen.dart';
import '../attend/attend_event_screen.dart';
import '../connections/connections_screen.dart';
import '../shop/shop_screen.dart';
import '../staff/approvals_screen.dart';
import '../staff/club_request_reviews_screen.dart';
import '../staff/event_reviews_screen.dart';
import '../staff/manage_events_screen.dart';
import '../staff/manage_volunteer_opportunities_screen.dart';
import '../dean/dean_dashboard_screen.dart';
import '../dean/dean_events_screen.dart';
import '../dean/dean_clubs_screen.dart';
import '../dean/dean_reports_screen.dart';
import '../../data/dean_faculties.dart';
import 'enrolled_events_screen.dart';
import '../../utils/university_id.dart';
import 'package:file_picker/file_picker.dart';
import 'badges_screen.dart';
import 'career_readiness_screen.dart';
import 'notifications_screen.dart';
import 'settings_screen.dart';
import '../onboarding/onboarding_chat_screen.dart';
import 'shams_update_chat_screen.dart';
import 'volunteer_hours_screen.dart';

Future<void> _pickAvatar(BuildContext context) async {
  final result = await FilePicker.pickFiles(
    type: FileType.image,
    withData: true,
  );
  if (result == null || result.files.isEmpty) return;
  final file = result.files.first;
  final bytes = file.bytes;
  if (bytes == null || !context.mounted) return;

  final ext = (file.extension ?? 'jpg').toLowerCase();
  final contentType = ext == 'png'
      ? 'image/png'
      : ext == 'webp'
          ? 'image/webp'
          : 'image/jpeg';

  final ok = await context.read<AppState>().uploadAvatar(bytes, contentType);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        ok ? 'Profile photo updated.' : 'Could not upload photo. Try again.',
      ),
    ),
  );
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  List<Widget> _heroChips(AppState state) {
    if (state.isDeanOfFaculty) {
      final dashboard = state.deanDashboard;
      return [
        StatChip(
          icon: Icons.school_outlined,
          label: state.assignedFaculty ?? 'Set faculty',
        ),
        StatChip(
          icon: Icons.event_outlined,
          label: '${dashboard?['events']?['total'] ?? state.deanFacultyEvents.length} events',
        ),
        StatChip(
          icon: Icons.groups_outlined,
          label: '${dashboard?['clubs']?['total'] ?? state.deanFacultyClubs.length} clubs',
        ),
      ];
    }
    if (state.isStudentAffairs) {
      final pendingVolunteer = state.volunteerRequests
          .where((r) => r.status == VolunteerRequestStatus.pending)
          .length;
      return [
        StatChip(
          icon: Icons.event_available,
          label: '${state.publishedEvents.length} events',
        ),
        if (pendingVolunteer > 0)
        StatChip(
          icon: Icons.verified_outlined,
            label: '$pendingVolunteer volunteer pending',
          ),
        if (state.pendingClubRequestCount > 0)
          StatChip(
            icon: Icons.groups_outlined,
            label: '${state.pendingClubRequestCount} club requests',
          ),
        if (state.pendingEventReviewCount > 0)
          StatChip(
            icon: Icons.event_outlined,
            label: '${state.pendingEventReviewCount} event reviews',
        ),
      ];
    }
    return [
      StatChip(icon: Icons.stars, label: '${state.points} pts'),
      StatChip(
        icon: Icons.groups_outlined,
        label: '${state.joinedClubsCount} clubs',
      ),
      StatChip(
        icon: Icons.event_available,
        label: '${state.joinedEventsCount} events',
      ),
      StatChip(icon: Icons.access_time, label: '${state.volunteerHours}/${AppState.mandatoryVolunteerHours}h'),
    ];
  }

  List<Widget> _affairsBody(BuildContext context, AppState state) {
    final profile = state.profile;
    final pendingVolunteer = state.volunteerRequests
        .where((r) => r.status == VolunteerRequestStatus.pending)
        .length;
    final pendingEvents = state.pendingEventReviewCount;
    return [
      _PivotTile(
        icon: Icons.event_note_outlined,
        title: 'Manage Events',
        subtitle: 'Create, edit, and publish your campus events',
        onTap: () => Navigator.of(context).push(
          FadeSlidePageRoute(builder: (_) => const ManageEventsScreen()),
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      _PivotTile(
        icon: Icons.campaign_outlined,
        title: 'Volunteer Opportunities',
        subtitle: state.openManagedVolunteerOpportunityCount > 0
            ? '${state.openManagedVolunteerOpportunityCount} open announcements'
            : 'Announce service roles for students to join',
        onTap: () => Navigator.of(context).push(
          FadeSlidePageRoute(
            builder: (_) => const ManageVolunteerOpportunitiesScreen(),
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      _PivotTile(
        icon: Icons.verified_outlined,
        title: 'Volunteer Approvals',
        subtitle: pendingVolunteer > 0
            ? '$pendingVolunteer submissions awaiting review'
            : 'Approve, reject, or withdraw volunteer hours',
        onTap: () => Navigator.of(context).push(
          FadeSlidePageRoute(builder: (_) => const ApprovalsScreen()),
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      _PivotTile(
        icon: Icons.event_outlined,
        title: 'Event Reviews',
        subtitle: pendingEvents > 0
            ? '$pendingEvents student events awaiting review'
            : 'Approve, reject, or withdraw student events',
        onTap: () => Navigator.of(context).push(
          FadeSlidePageRoute(builder: (_) => const EventReviewsScreen()),
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      _PivotTile(
        icon: Icons.groups_outlined,
        title: 'Club Requests',
        subtitle: state.pendingClubRequestCount > 0
            ? '${state.pendingClubRequestCount} pending founding requests'
            : 'Approve, decline, or revoke club proposals',
        onTap: () => Navigator.of(context).push(
          FadeSlidePageRoute(
            builder: (_) => const ClubRequestReviewsScreen(),
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.lg),
      const SectionHeader(title: 'About', padding: EdgeInsets.zero),
      _AboutCard(
        name: profile?.name ?? '-',
        role: profile?.role.label ?? '-',
        major: profile?.major ?? '-',
        year: '${DateTime.now().year}',
        interests: const [],
        showMajor: false,
        showInterests: false,
      ),
    ];
  }

  List<Widget> _deanBody(BuildContext context, AppState state) {
    final profile = state.profile;
    return [
      const _DeanProfileLoader(),
      _PivotTile(
        icon: Icons.dashboard_outlined,
        title: 'Dean dashboard',
        subtitle: state.assignedFaculty != null
            ? '${state.assignedFaculty} faculty overview'
            : 'Select your faculty to unlock scoped data',
        onTap: () => Navigator.of(context).push(
          FadeSlidePageRoute(builder: (_) => const DeanDashboardScreen()),
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      _PivotTile(
        icon: Icons.event_outlined,
        title: 'Faculty events',
        subtitle: '${state.deanFacultyEvents.length} events in your faculty',
        onTap: () => Navigator.of(context).push(
          FadeSlidePageRoute(builder: (_) => const DeanEventsScreen()),
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      _PivotTile(
        icon: Icons.groups_outlined,
        title: 'Faculty clubs',
        subtitle: '${state.deanFacultyClubs.length} clubs in your faculty',
        onTap: () => Navigator.of(context).push(
          FadeSlidePageRoute(builder: (_) => const DeanClubsScreen()),
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      _PivotTile(
        icon: Icons.assessment_outlined,
        title: 'Faculty reports',
        subtitle: 'Events, clubs, volunteering, and engagement',
        onTap: () => Navigator.of(context).push(
          FadeSlidePageRoute(builder: (_) => const DeanReportsScreen()),
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      _PivotTile(
        icon: Icons.campaign_outlined,
        title: 'Faculty announcement',
        subtitle: 'Send a notification to students in your faculty',
        onTap: () async {
          final titleCtrl = TextEditingController();
          final bodyCtrl = TextEditingController();
          final send = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Faculty announcement'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: bodyCtrl,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(labelText: 'Message'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Send'),
                ),
              ],
            ),
          );
          if (send != true || !context.mounted) {
            titleCtrl.dispose();
            bodyCtrl.dispose();
            return;
          }
          final error = await context.read<AppState>().sendDeanAnnouncement(
                title: titleCtrl.text.trim(),
                body: bodyCtrl.text.trim(),
              );
          titleCtrl.dispose();
          bodyCtrl.dispose();
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                error ?? 'Announcement sent to your faculty students.',
              ),
            ),
          );
        },
      ),
      const SizedBox(height: AppSpacing.sm),
      _PivotTile(
        icon: Icons.swap_horiz,
        title: 'Assigned faculty',
        subtitle: state.assignedFaculty ?? 'Tap to choose your faculty',
        onTap: () async {
          final selected = await showModalBottomSheet<String>(
            context: context,
            showDragHandle: true,
            builder: (ctx) => SafeArea(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final faculty in DeanFaculties.options)
                    ListTile(
                      title: Text(faculty),
                      onTap: () => Navigator.pop(ctx, faculty),
                    ),
                ],
              ),
            ),
          );
          if (selected == null || !context.mounted) return;
          final error =
              await context.read<AppState>().setAssignedFaculty(selected);
          if (!context.mounted) return;
          if (error != null) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(error)));
          }
        },
      ),
      if (state.deanAnnouncements.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.lg),
        const SectionHeader(title: 'Your announcements', padding: EdgeInsets.zero),
        for (final row in state.deanAnnouncements.take(5))
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _DeanAnnouncementTile(row: row),
          ),
      ],
      const SizedBox(height: AppSpacing.lg),
      const SectionHeader(title: 'About', padding: EdgeInsets.zero),
      _AboutCard(
        name: profile?.name ?? '-',
        role: profile?.role.label ?? '-',
        major: state.assignedFaculty ?? '-',
        year: '${DateTime.now().year}',
        interests: const [],
        showMajor: false,
        facultyLabel: state.assignedFaculty,
        showInterests: false,
      ),
    ];
  }

  List<Widget> _studentBody(
    BuildContext context,
    AppState state,
    String name,
    profile,
  ) {
    return [
      _VolunteerProgressCard(
        approved: state.volunteerHours,
        remaining: state.volunteerHoursRemaining,
        goal: AppState.mandatoryVolunteerHours,
        progress: state.volunteerProgress,
        onTap: () => Navigator.of(context).push(
          FadeSlidePageRoute(builder: (_) => const VolunteerHoursScreen()),
        ),
      ),
      const SizedBox(height: AppSpacing.lg),
      Row(
        children: [
          Expanded(
            child: _ActionTile(
              icon: Icons.shopping_bag_outlined,
              label: 'Shop',
              accent: AppAccents.at(0),
              onTap: () => Navigator.of(context).push(
                FadeSlidePageRoute(builder: (_) => const ShopScreen()),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _ActionTile(
              icon: Icons.qr_code_scanner,
              label: 'Scan',
              accent: AppAccents.at(1),
              onTap: () => Navigator.of(context).push(
                FadeSlidePageRoute(builder: (_) => const AttendEventScreen()),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _ActionTile(
              icon: Icons.assignment_ind_outlined,
              label: 'CV',
              accent: AppAccents.at(2),
              onTap: () => Navigator.of(context).push(
                FadeSlidePageRoute(builder: (_) => const CareerReadinessScreen()),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _ActionTile(
              icon: Icons.handshake_outlined,
              label: 'Connect',
              accent: AppAccents.at(3),
              badgeCount: state.unreadPeerMessageCount,
              onTap: () => Navigator.of(context).push(
                FadeSlidePageRoute(
                  builder: (_) => ConnectionsScreen(
                    initialSegment: state.unreadPeerMessageCount > 0 ? 2 : 0,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.lg),
      _PivotTile(
        icon: Icons.volunteer_activism_outlined,
        title: 'Volunteer Hours',
        subtitle: state.volunteerHoursRemaining > 0
            ? '${state.volunteerHoursRemaining}h left of ${AppState.mandatoryVolunteerHours} · browse opportunities'
            : 'Mandatory ${AppState.mandatoryVolunteerHours}h complete',
        onTap: () => Navigator.of(context).push(
          FadeSlidePageRoute(builder: (_) => const VolunteerHoursScreen()),
        ),
      ),
      const SizedBox(height: AppSpacing.lg),
      _ShamsUpdateButton(
        onTap: () => Navigator.of(context).push(
          FadeSlidePageRoute(
            builder: (_) => const OnboardingChatScreen(isProfileUpdate: true),
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.lg),
      const SectionHeader(title: 'About', padding: EdgeInsets.zero),
      _AboutCard(
        name: name,
        role: profile?.role.label ?? 'Student',
        major: profile?.major ?? '-',
        year: profile?.year ?? '-',
        bio: profile?.bio,
        careerGoal: profile?.careerGoal,
        campus: profile?.campus,
        interests: profile?.interests ?? const [],
        onEditInterests: () => Navigator.of(context).push(
          FadeSlidePageRoute(builder: (_) => const ShamsUpdateChatScreen()),
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      SectionHeader(
        title: 'Badges Earned',
        padding: EdgeInsets.zero,
        action: 'View all',
        onAction: () => Navigator.of(context).push(
          FadeSlidePageRoute(builder: (_) => const BadgesScreen()),
        ),
      ),
      Text(
        'Earn badges by attending events, volunteering, hosting study sessions, '
        'leading clubs, building skills to 90%, and collecting campus points.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
      ),
      const SizedBox(height: AppSpacing.sm),
      Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.md,
        children: [
          for (var i = 0; i < state.allBadges.length; i++)
            _BadgeChip(
              name: state.allBadges[i].name,
              icon: state.allBadges[i].icon,
              accent: AppAccents.at(i),
              locked: state.allBadges[i].locked,
            ),
        ],
      ),
      const SizedBox(height: AppSpacing.lg),
      const _ProfilePanel(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final profile = state.profile;
    final name = profile?.name ?? 'Student';
    return Scaffold(
      backgroundColor: AppColors.background,
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppGradients.campusPage),
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxl),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                children: [
                  GlowIconButton(
                    icon: Icons.notifications_none_rounded,
                    tooltip: 'Notifications',
                    onTap: () => Navigator.of(context).push(
                      FadeSlidePageRoute(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    ),
                      ),
                      if (state.unreadNotificationCount > 0)
                        Positioned(
                          right: 4,
                          top: 4,
                          child: _CountBadge(
                            count: state.unreadNotificationCount,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  GlowIconButton(
                    icon: Icons.settings_outlined,
                    tooltip: 'Settings',
                    onTap: () => Navigator.of(context).push(
                      FadeSlidePageRoute(
                        builder: (_) => const SettingsScreen(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _ProfileHero(
                name: name,
                role: profile?.role.label ?? 'Student',
                profileId: UniversityId.isValid(profile?.studentId)
                    ? profile!.studentId
                    : '',
                avatarUrl: profile?.avatarUrl,
                uploading: state.avatarUploading,
                onAvatarTap: () => _pickAvatar(context),
                chips: _heroChips(state),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (state.isDeanOfFaculty)
                ..._deanBody(context, state)
              else if (state.isStudentAffairs)
                ..._affairsBody(context, state)
              else
                ..._studentBody(context, state, name, profile),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _ProfileHero extends StatelessWidget {
  final String name;
  final String role;
  final String profileId;
  final String? avatarUrl;
  final bool uploading;
  final VoidCallback? onAvatarTap;
  final List<Widget> chips;
  const _ProfileHero({
    required this.name,
    required this.role,
    required this.profileId,
    this.avatarUrl,
    this.uploading = false,
    this.onAvatarTap,
    this.chips = const [],
  });

  @override
  Widget build(BuildContext context) {
    return GradientHero(
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: uploading ? null : onAvatarTap,
              child: Stack(
                alignment: Alignment.center,
          children: [
            Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                      gradient: avatarUrl == null
                          ? RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.35),
                    Colors.white.withValues(alpha: 0.12),
                  ],
                            )
                          : null,
                      image: avatarUrl != null
                          ? DecorationImage(
                              image: NetworkImage(avatarUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.6), width: 2),
                    ),
                    child: avatarUrl == null
                        ? Icon(
                            Icons.person_outline,
                            size: 44,
                            color: Colors.white.withValues(alpha: 0.85),
                          )
                        : null,
                  ),
                  if (uploading)
                    const Positioned.fill(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  else if (onAvatarTap != null)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt_outlined, size: 16),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              name,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(AppRadii.pill),
                border:
                    Border.all(color: Colors.white.withValues(alpha: 0.35)),
              ),
              child: Text(
                profileId.isEmpty ? role : '$role · $profileId',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            if (chips.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 6,
                children: chips,
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 240.ms).slideY(begin: 0.1, end: 0);
  }
}

// ---------------------------------------------------------------------------
// Action tiles
// ---------------------------------------------------------------------------

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color accent;
  final int badgeCount;
  const _ActionTile(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.accent = AppColors.primary,
      this.badgeCount = 0});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.lg),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: cardDecoration(),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
          children: [
            Container(
              width: 42,
              height: 42,
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
              child: Icon(icon, color: Colors.white, size: 20),
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: _CountBadge(count: badgeCount),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Chat with Shams button (students)
// ---------------------------------------------------------------------------

class _ShamsUpdateButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ShamsUpdateButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.xl),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          gradient: AppGradients.header,
          borderRadius: BorderRadius.circular(AppRadii.xl),
          boxShadow: glow(AppColors.primary,
              alpha: 0.30, blurRadius: 20, offset: const Offset(0, 10)),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.25),
                border:
                    Border.all(color: Colors.white.withValues(alpha: 0.5)),
              ),
              child: const BirdSticker(row: 2, col: 2, size: 48),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Chat with Shams',
                        style: GoogleFonts.fraunces(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.auto_awesome,
                          color: Colors.white, size: 16),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Refresh your profile with Shams or the manual form',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// About card
// ---------------------------------------------------------------------------

class _AboutCard extends StatelessWidget {
  final String name;
  final String role;
  final String major;
  final String year;
  final List<String> interests;
  final bool showMajor;
  final bool showInterests;
  final String? facultyLabel;
  final String? bio;
  final String? careerGoal;
  final String? campus;
  final VoidCallback? onEditInterests;

  const _AboutCard({
    required this.name,
    required this.role,
    required this.major,
    required this.year,
    required this.interests,
    this.showMajor = true,
    this.showInterests = true,
    this.facultyLabel,
    this.bio,
    this.careerGoal,
    this.campus,
    this.onEditInterests,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surface,
            Color.lerp(AppColors.surface, AppColors.primary, 0.06)!,
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.10)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 12,
            top: 12,
            child: Icon(Icons.auto_awesome,
                color: AppColors.primary.withValues(alpha: 0.35), size: 20),
          ),
          Positioned(
            right: 30,
            top: 30,
            child: Icon(Icons.auto_awesome,
                color: AppColors.magenta.withValues(alpha: 0.30), size: 12),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _kv(context, 'Name', name),
                _kv(context, 'Role', role),
                if (facultyLabel != null && facultyLabel!.trim().isNotEmpty)
                  _kv(context, 'Faculty', facultyLabel!),
                if (showMajor) _kv(context, 'Major', major),
                _kv(context, 'Year', year),
                if (campus != null && campus!.trim().isNotEmpty)
                  _kv(context, 'Campus', campus!),
                if (careerGoal != null && careerGoal!.trim().isNotEmpty)
                  _kv(context, 'Career goal', careerGoal!),
                if (bio != null && bio!.trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text('Bio',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                          )),
                  const SizedBox(height: 4),
                  Text(bio!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          )),
                ],
                if (showInterests) ...[
                const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                Text('Interests',
                          style:
                              Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                        )),
                      const Spacer(),
                      if (onEditInterests != null)
                        TextButton.icon(
                          onPressed: onEditInterests,
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: const Text('Edit'),
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ),
                    ],
                  ),
                const SizedBox(height: 6),
                if (interests.isEmpty)
                  Text('No interests yet',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.textMuted))
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final i in interests)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.10),
                              borderRadius:
                                  BorderRadius.circular(AppRadii.pill),
                            border: Border.all(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.20)),
                          ),
                          child: Text(
                            i,
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _kv(BuildContext context, String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(k,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    )),
          ),
          Expanded(
            child: Text(v,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tabbed panel: Skill Progress / Event History / Semester Goals
// ---------------------------------------------------------------------------

class _ProfilePanel extends StatefulWidget {
  const _ProfilePanel();

  @override
  State<_ProfilePanel> createState() => _ProfilePanelState();
}

class _ProfilePanelState extends State<_ProfilePanel> {
  int _tab = 0;
  static const _tabs = ['Skill Progress', 'Event History', 'Semester Goals'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (var i = 0; i < _tabs.length; i++)
              _TabButton(
                label: _tabs[i],
                selected: _tab == i,
                onTap: () => setState(() => _tab = i),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: switch (_tab) {
            0 => const _SkillTab(key: ValueKey('skill')),
            1 => const _HistoryTab(key: ValueKey('history')),
            _ => const _GoalsTab(key: ValueKey('goals')),
          },
        ),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TabButton(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: selected ? AppColors.textPrimary : AppColors.textMuted,
              fontSize: 14,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            height: 3,
            width: selected ? 26 : 0,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppRadii.pill),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillTab extends StatelessWidget {
  const _SkillTab({super.key});

  Future<void> _addSkill(BuildContext context) async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add a skill'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'e.g. Public speaking'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty || !context.mounted) return;
    final ok = await context.read<AppState>().addManualSkill(name);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Skill added.' : 'That skill is already on your profile.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: IconButton.filledTonal(
            tooltip: 'Add skill',
            onPressed: () => _addSkill(context),
            icon: const Icon(Icons.add),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Percentages start from your Shams profile baseline, then rise when you '
          'join events, study sessions, complete goals, and volunteer. Rings cap at 90%.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SkillProgressCard(
          onSkillTap: (index, skill) =>
              showSkillActionsSheet(context, index, skill),
      onMore: () => Navigator.of(context).push(
        FadeSlidePageRoute(builder: (_) => const SkillProgressScreen()),
      ),
        ),
      ],
    );
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final joined = state.joinedEventsSorted();
    if (joined.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: cardDecoration(),
        child: Row(
          children: [
            Icon(Icons.event_outlined, color: AppColors.textMuted),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Enroll in events to start building your campus history.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: cardDecoration(),
      child: Column(
        children: [
          for (final row in joined.take(3)) ...[
            _HistoryRow(
              title: row.event.title,
              organizer: row.event.organizer,
              category: row.event.category.label,
              points: row.event.points,
            ),
            if (row != joined.take(3).last)
              const Divider(height: AppSpacing.lg),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              TextButton.icon(
                onPressed: () => Navigator.of(context).push(
                  FadeSlidePageRoute(
                    builder: (_) => const EnrolledEventsScreen(),
                  ),
                ),
                icon: const Icon(Icons.list_alt_outlined),
                label: const Text('View all'),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => Navigator.of(context).push(
                  FadeSlidePageRoute(
                    builder: (_) => const CareerReadinessScreen(),
                  ),
                ),
                icon: const Icon(Icons.assignment_ind_outlined),
                label: const Text('View my CV'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GoalsTab extends StatelessWidget {
  const _GoalsTab({super.key});

  Future<void> _addGoal(BuildContext context) async {
    final ctrl = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add a goal'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'e.g. Earn first badge'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (text == null || text.isEmpty || !context.mounted) return;
    await context.read<AppState>().addSemesterGoal(text);
  }

  Future<void> _editGoal(BuildContext context, String goal) async {
    final ctrl = TextEditingController(text: goal);
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit goal'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (text == null || text.isEmpty || text == goal || !context.mounted) {
      return;
    }
    await context.read<AppState>().updateSemesterGoal(goal, text);
  }

  Future<void> _deleteGoal(BuildContext context, String goal) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete goal?'),
        content: Text('Remove "$goal" from your semester goals?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await context.read<AppState>().removeSemesterGoal(goal);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final goals = state.semesterGoals;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: cardDecoration(),
      child: goals.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
                  Text(
                    'No goals yet. Chat with Shams to generate your semester goals, '
                    'or add your own with +.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton.filledTonal(
                      tooltip: 'Add goal',
                      onPressed: () => _addGoal(context),
                      icon: const Icon(Icons.add),
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.sm,
                    AppSpacing.md,
                    AppSpacing.sm,
                    0,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Tap to track progress · hold ⋮ to edit',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ),
                      IconButton.filledTonal(
                        tooltip: 'Add goal',
                        onPressed: () => _addGoal(context),
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ),
                for (final goal in goals)
                  Builder(
                    builder: (context) {
                      final done = state.isGoalDone(goal);
                      return CheckboxListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm),
                        title: Text(
                          goal,
                          style: done
                              ? Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppColors.textMuted,
                                    decoration: TextDecoration.lineThrough,
                                    decorationColor: AppColors.textMuted,
                                  )
                              : null,
                        ),
                        value: done,
                        onChanged: (_) =>
                            context.read<AppState>().toggleGoal(goal),
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: AppColors.primary,
                        secondary: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, size: 20),
                          onSelected: (action) {
                            if (action == 'edit') {
                              _editGoal(context, goal);
                            } else if (action == 'delete') {
                              _deleteGoal(context, goal);
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                        ),
                      );
                    },
            ),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final String title;
  final String organizer;
  final String category;
  final int points;
  const _HistoryRow({
    required this.title,
    required this.organizer,
    required this.category,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.accentLight,
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          child: const Icon(Icons.event_available,
              color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              Text('$organizer · $category',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      )),
            ],
          ),
        ),
        Text('+$points',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                )),
      ],
    );
  }
}

class _DeanProfileLoader extends StatefulWidget {
  const _DeanProfileLoader();

  @override
  State<_DeanProfileLoader> createState() => _DeanProfileLoaderState();
}

class _DeanProfileLoaderState extends State<_DeanProfileLoader> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppState>().refreshDeanData();
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _DeanAnnouncementTile extends StatelessWidget {
  final Map<String, dynamic> row;

  const _DeanAnnouncementTile({required this.row});

  @override
  Widget build(BuildContext context) {
    final title = row['title']?.toString() ?? 'Announcement';
    final body = row['body']?.toString() ?? '';
    final sentAt = row['created_at']?.toString() ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          if (body.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
          if (sentAt.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              sentAt,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PivotTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _PivotTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.lg),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: cardDecoration(),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: AppGradients.header,
                borderRadius: BorderRadius.circular(AppRadii.md),
                boxShadow: glow(AppColors.primary,
                    alpha: 0.22, blurRadius: 12, offset: const Offset(0, 5)),
              ),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_rounded, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  final String name;
  final IconData icon;
  final bool locked;
  final Color accent;
  const _BadgeChip(
      {required this.name,
      required this.icon,
      required this.locked,
      this.accent = AppColors.primary});

  @override
  Widget build(BuildContext context) {
    final color = locked ? AppColors.textMuted : accent;
    return SizedBox(
      width: 100,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: locked
                  ? AppColors.surfaceMuted
                  : accent.withValues(alpha: 0.16),
              shape: BoxShape.circle,
              boxShadow: locked
                  ? null
                  : glow(accent,
                      alpha: 0.18, blurRadius: 10, offset: const Offset(0, 4)),
            ),
            child: Icon(
              locked ? Icons.lock_outline : icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;

  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final label = count > 9 ? '9+' : '$count';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.magenta,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: AppColors.surface, width: 1.5),
      ),
      constraints: const BoxConstraints(minWidth: 18),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 10,
            ),
      ),
    );
  }
}

class _VolunteerProgressCard extends StatelessWidget {
  final int approved;
  final int remaining;
  final int goal;
  final double progress;
  final VoidCallback onTap;

  const _VolunteerProgressCard({
    required this.approved,
    required this.remaining,
    required this.goal,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: AppGradients.header,
            borderRadius: BorderRadius.circular(AppRadii.lg),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.volunteer_activism_outlined,
                      color: Colors.white, size: 28),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mandatory volunteering',
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        Text(
                          '$approved / $goal hours approved',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      color: Colors.white.withValues(alpha: 0.85)),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                remaining > 0
                    ? '$remaining hours left to complete'
                    : 'Requirement complete',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.pill),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.25),
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
