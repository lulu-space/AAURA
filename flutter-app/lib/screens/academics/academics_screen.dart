import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/study_session.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/transitions.dart';
import '../../widgets/bird_avatar.dart';
import '../../widgets/dawn_scene.dart';
import '../../widgets/glow_widgets.dart';
import 'create_study_session_screen.dart';
import 'study_reminder_screen.dart';

// Warm dawn tints + mascot poses reused for the study-session slideshow so the
// cards read as the same world as the Home "Trending" strip.
const List<Color> _sessionTints = [
  Color(0xFFF4C9A0),
  Color(0xFFE9B6B4),
  Color(0xFFD9C2E0),
  Color(0xFFF2D6A8),
];

const List<List<int>> _sessionPoses = [
  [0, 2],
  [2, 2],
  [4, 0],
  [1, 2],
  [3, 0],
  [2, 1],
];

class AcademicsScreen extends StatefulWidget {
  const AcademicsScreen({super.key});

  @override
  State<AcademicsScreen> createState() => _AcademicsScreenState();
}

class _AcademicsScreenState extends State<AcademicsScreen> {
  void _openJoinSheet(BuildContext context) {
    final state = context.read<AppState>();
    final all = state.activeStudySessions;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
      ),
      builder: (sheetCtx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          builder: (_, controller) {
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Consumer<AppState>(
                builder: (consumerCtx, st, _) => Column(
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
                    Text('Browse study rooms',
                        style: Theme.of(consumerCtx)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    Text('Tap Attend to join a room.',
                        style: Theme.of(consumerCtx)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: AppSpacing.md),
                    Expanded(
                      child: ListView.separated(
                        controller: controller,
                        itemCount: all.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (_, i) {
                          final s = all[i];
                          final joined = st.isSessionJoined(s.id);
                          return Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: cardDecoration(),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.accentLight,
                                    borderRadius:
                                        BorderRadius.circular(AppRadii.md),
                                  ),
                                  child: const Icon(Icons.menu_book,
                                      color: AppColors.primary),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(s.course,
                                          style: Theme.of(consumerCtx)
                                              .textTheme
                                              .titleSmall
                                              ?.copyWith(
                                                  fontWeight:
                                                      FontWeight.w700)),
                                      Text(
                                          '${s.type.label} · ${s.when}',
                                          style: Theme.of(consumerCtx)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                  color: AppColors
                                                      .textSecondary)),
                                      Text(
                                        s.seatsLeft == null
                                            ? 'Open session'
                                            : '${s.seatsLeft} seats left',
                                          style: Theme.of(consumerCtx)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                  color: AppColors.primary,
                                                  fontWeight:
                                                      FontWeight.w700)),
                                    ],
                                  ),
                                ),
                                OutlinedButton(
                                  onPressed: () {
                                    consumerCtx
                                        .read<AppState>()
                                        .toggleSessionJoin(s.id);
                                  },
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 8),
                                    backgroundColor: joined
                                        ? AppColors.accentLight
                                        : null,
                                  ),
                                  child: Text(
                                      joined ? 'Attending' : 'Attend'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _plannerItemSource(Map<String, String> item) {
    final explicit = item['source'];
    if (explicit != null && explicit.isNotEmpty) return explicit;
    if ((item['planId'] ?? '').isNotEmpty) return 'study_plan';
    if ((item['id'] ?? '').isNotEmpty) return 'calendar';
    return '';
  }

  bool _canEditPlannerItem(Map<String, String> item, AppState state) {
    if (!state.canManagePlanner) return false;
    if ((item['planId'] ?? '').isNotEmpty &&
        int.tryParse(item['entryIndex'] ?? '') != null) {
      return true;
    }
    return (item['id'] ?? '').isNotEmpty;
  }

  Future<void> _editCourse(BuildContext context, Map<String, String> course) async {
    final state = context.read<AppState>();
    final source = _plannerItemSource(course);
    if (source == 'study_plan') {
      final planId = course['planId'] ?? '';
      final entryIndex = int.tryParse(course['entryIndex'] ?? '');
      if (planId.isEmpty || entryIndex == null) return;
      final saved = await _PlannerActions.promptStudyEntry(
        context,
        title: 'Edit course',
        hint: 'Course name',
        initialTitle: course['title'] ?? '',
        initialNext: course['next'] ?? '',
      );
      if (saved == null || !context.mounted) return;
      final ok = await state.updateStudyPlanCourse(
        planId: planId,
        entryIndex: entryIndex,
        title: saved.$1,
        next: saved.$2,
      );
      if (!context.mounted) return;
      _plannerSnack(context, ok);
      return;
    }

    final id = course['id'] ?? '';
    if (id.isEmpty) return;
    final initialWhen = DateTime.tryParse(course['iso'] ?? '') ??
        DateTime.now().add(const Duration(days: 1));
    final saved = await _PlannerActions.promptCalendarItem(
      context,
      title: 'Edit course block',
      hint: 'e.g. CS401 lecture',
      initialTitle: course['title'] ?? '',
      initialWhen: initialWhen,
    );
    if (saved == null || !context.mounted) return;
    final ok = await state.updateCalendarCourse(
      id: id,
      title: saved.$1,
      startsAt: saved.$2,
    );
    if (!context.mounted) return;
    _plannerSnack(context, ok);
  }

  Future<void> _deleteCourse(BuildContext context, Map<String, String> course) async {
    final state = context.read<AppState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove course?'),
        content: Text('Remove "${course['title']}" from your schedule?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Remove')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    var removed = false;
    if (_plannerItemSource(course) == 'study_plan') {
      final planId = course['planId'] ?? '';
      final entryIndex = int.tryParse(course['entryIndex'] ?? '');
      if (planId.isNotEmpty && entryIndex != null) {
        removed = await state.deleteStudyPlanCourse(
          planId: planId,
          entryIndex: entryIndex,
        );
      }
    } else {
      final id = course['id'] ?? '';
      if (id.isNotEmpty) removed = await state.deleteCalendarCourse(id);
    }
    if (!context.mounted) return;
    _plannerSnack(context, removed);
  }

  Future<void> _editDeadline(BuildContext context, Map<String, String> deadline) async {
    final id = deadline['id'] ?? '';
    if (id.isEmpty) return;
    final state = context.read<AppState>();
    final initialWhen = DateTime.tryParse(deadline['iso'] ?? '') ??
        DateTime.now().add(const Duration(days: 3));
    final saved = await _PlannerActions.promptCalendarItem(
      context,
      title: 'Edit deadline',
      hint: 'e.g. Project proposal',
      initialTitle: deadline['title'] ?? '',
      initialWhen: initialWhen,
    );
    if (saved == null || !context.mounted) return;
    final ok = await state.updateCalendarDeadline(
      id: id,
      title: saved.$1,
      dueAt: saved.$2,
    );
    if (!context.mounted) return;
    _plannerSnack(context, ok);
  }

  Future<void> _deleteDeadline(
      BuildContext context, Map<String, String> deadline) async {
    final id = deadline['id'] ?? '';
    if (id.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove deadline?'),
        content: Text('Remove "${deadline['title']}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Remove')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final removed =
        await context.read<AppState>().deleteCalendarDeadline(id);
    if (!context.mounted) return;
    _plannerSnack(context, removed);
  }

  void _plannerSnack(BuildContext context, bool ok) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Planner updated.' : 'Could not update planner.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final firstName = (state.profile?.name ?? 'Student').split(' ').first;
    final sessions = state.suggestedStudySessions;
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
              _AcademicsHero(name: firstName)
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.05, end: 0),
              const SizedBox(height: AppSpacing.lg),

              // 1. Study Sessions — the main event, first.
              const _SectionLabel(
                title: 'Study Sessions',
                subtitle: 'Personalized to your major and interests',
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openJoinSheet(context),
                      icon: const Icon(Icons.group_outlined),
                      label: const Text('Join'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          FadeSlidePageRoute(
                            builder: (_) => const CreateStudySessionScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Create'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _StudySessionStrip(
                sessions: sessions,
                isJoined: state.isSessionJoined,
                isHost: state.isSessionHost,
                onTap: (s) => Navigator.of(context).push(
                  FadeSlidePageRoute(
                    builder: (_) => StudyReminderScreen(session: s),
                  ),
                ),
                onToggle: (s) =>
                    context.read<AppState>().toggleSessionJoin(s.id),
                onEdit: (s) => Navigator.of(context).push(
                  FadeSlidePageRoute(
                    builder: (_) => CreateStudySessionScreen(existing: s),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // 2. Planner calendar.
              const _SectionLabel(
                title: "What's planned",
                subtitle: 'Tap a day to see your plan',
              ),
              const SizedBox(height: AppSpacing.sm),
              _PlannerActions(),
              const SizedBox(height: AppSpacing.sm),
              _PlannerCalendar(
                sessions: sessions,
                courses: state.courseSchedule,
                deadlines: state.upcomingDeadlines,
                canEditItem: (item) => _canEditPlannerItem(item, state),
                onEditCourse: (c) => _editCourse(context, c),
                onDeleteCourse: (c) => _deleteCourse(context, c),
                onEditDeadline: (d) => _editDeadline(context, d),
                onDeleteDeadline: (d) => _deleteDeadline(context, d),
              ),
              const SizedBox(height: AppSpacing.lg),

              // 4. Courses (expanded — tap row or icons to edit/delete).
              _DreamyDropdown(
                title: 'My Courses & Schedule',
                icon: Icons.menu_book_outlined,
                initiallyExpanded: true,
                subtitle: state.canManagePlanner
                    ? 'Tap a row to edit · use icons to delete'
                    : null,
                child: state.courseSchedule.isEmpty
                    ? const _EmptyHint(
                        text:
                            'No courses yet. Add a study plan to build your schedule.',
                      )
                    : Column(
                        children: [
                          for (final c in state.courseSchedule)
                            _CourseTile(
                              key: ValueKey(
                                'course-${c['source']}-${c['id'] ?? c['planId']}-${c['entryIndex']}-${c['title']}',
                              ),
                              code: c['code'] ?? '',
                              title: c['title'] ?? '',
                              next: c['next'] ?? '',
                              canEdit: _canEditPlannerItem(c, state),
                              onEdit: () => _editCourse(context, c),
                              onDelete: () => _deleteCourse(context, c),
                            ),
                        ],
                      ),
              ),
              const SizedBox(height: AppSpacing.md),

              // 5. Deadlines (expanded — tap row or icons to edit/delete).
              _DreamyDropdown(
                title: 'Upcoming Deadlines',
                icon: Icons.flag_outlined,
                initiallyExpanded: true,
                subtitle: state.canManagePlanner
                    ? 'Tap a row to edit · use icons to delete'
                    : null,
                child: state.upcomingDeadlines.isEmpty
                    ? const _EmptyHint(
                        text:
                            'No deadlines yet. Add reminders to your calendar to see them here.',
                      )
                    : Column(
                        children: [
                          for (final d in state.upcomingDeadlines)
                            _DeadlineTile(
                              key: ValueKey('deadline-${d['id']}-${d['title']}'),
                              title: d['title'] ?? '',
                              due: d['due'] ?? '',
                              canEdit: _canEditPlannerItem(d, state),
                              onEdit: () => _editDeadline(context, d),
                              onDelete: () => _deleteDeadline(context, d),
                            ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hero
// ---------------------------------------------------------------------------

class _AcademicsHero extends StatelessWidget {
  final String name;
  const _AcademicsHero({required this.name});

  @override
  Widget build(BuildContext context) {
    final scrimColor = AppPalette.dawnLow;
    return SizedBox(
      height: 168,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.xl),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const DawnScene(reveal: 1.0),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    scrimColor.withValues(alpha: 0.0),
                    scrimColor.withValues(alpha: 0.62),
                  ],
                ),
              ),
            ),
            Positioned(
              right: -4,
              bottom: -6,
              child: IgnorePointer(
                child: const BirdSticker(row: 0, col: 1, size: 104)
                    .animate()
                    .fadeIn(delay: 250.ms, duration: 500.ms)
                    .slideX(begin: 0.3, end: 0, curve: Curves.easeOut),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hi, $name',
                    style: playfulDisplay(
                      size: 30,
                      weight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.0,
                    ).copyWith(
                      shadows: [
                        Shadow(
                          color: scrimColor.withValues(alpha: 0.8),
                          blurRadius: 14,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Here's your week — let's make it count.",
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
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
  final String title;
  final String? subtitle;
  const _SectionLabel({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: GoogleFonts.inter(
              color: AppColors.textMuted,
              fontSize: 11.5,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Study session slideshow
// ---------------------------------------------------------------------------

class _StudySessionStrip extends StatelessWidget {
  final List<StudySession> sessions;
  final bool Function(String id) isJoined;
  final bool Function(StudySession session) isHost;
  final ValueChanged<StudySession> onTap;
  final ValueChanged<StudySession> onToggle;
  final ValueChanged<StudySession> onEdit;

  const _StudySessionStrip({
    required this.sessions,
    required this.isJoined,
    required this.isHost,
    required this.onTap,
    required this.onToggle,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 224,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: sessions.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (_, i) {
          final s = sessions[i];
          final tint = _sessionTints[i % _sessionTints.length];
          final pose = _sessionPoses[i % _sessionPoses.length];
          return _StudySessionCard(
            tint: tint,
            session: s,
            joined: isJoined(s.id),
            showEdit: isHost(s),
            poseRow: pose[0],
            poseCol: pose[1],
            onTap: () => onTap(s),
            onToggle: () => onToggle(s),
            onEdit: () => onEdit(s),
          )
              .animate()
              .fadeIn(delay: (60 * i).ms, duration: 350.ms)
              .slideX(begin: 0.12, end: 0);
        },
      ),
    );
  }
}

class _StudySessionCard extends StatelessWidget {
  final Color tint;
  final StudySession session;
  final bool joined;
  final bool showEdit;
  final int poseRow;
  final int poseCol;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback onEdit;

  const _StudySessionCard({
    required this.tint,
    required this.session,
    required this.joined,
    this.showEdit = false,
    required this.poseRow,
    required this.poseCol,
    required this.onTap,
    required this.onToggle,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 210,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [tint, Color.lerp(tint, AppPalette.ink, 0.18)!],
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.xl),
          child: Stack(
            children: [
              if (showEdit)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Material(
                    color: Colors.white.withValues(alpha: 0.35),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onEdit,
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(Icons.edit_outlined, size: 16),
                      ),
                    ),
                  ),
                ),
              Positioned(
                right: -16,
                bottom: -10,
                child: IgnorePointer(
                  child: BirdSticker(row: poseRow, col: poseCol, size: 92),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SessionGlassChip(
                      icon: Icons.event_seat_outlined,
                      label: session.seatsLeft == null
                          ? 'Open'
                          : '${session.seatsLeft} seats',
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: 150,
                      child: Text(
                        session.course,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: AppPalette.ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 140,
                      child: Text(
                        session.when,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: AppPalette.ink.withValues(alpha: 0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    SizedBox(
                      width: 140,
                      child: Text(
                        session.type.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: AppPalette.ink.withValues(alpha: 0.6),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Spacer(),
                    _AttendButton(joined: joined, onTap: onToggle),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionGlassChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SessionGlassChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.30),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppPalette.ink),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              color: AppPalette.ink,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendButton extends StatelessWidget {
  final bool joined;
  final VoidCallback onTap;
  const _AttendButton({required this.joined, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: joined ? AppPalette.cream : AppPalette.ink,
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.pill),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                joined ? Icons.check_circle : Icons.arrow_forward_rounded,
                size: 15,
                color: joined ? AppPalette.ink : AppPalette.cream,
              ),
              const SizedBox(width: 6),
              Text(
                joined ? 'Attending' : 'Attend',
                style: GoogleFonts.inter(
                  color: joined ? AppPalette.ink : AppPalette.cream,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
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
// Planner calendar
// ---------------------------------------------------------------------------

enum _PlanKind { classItem, deadline, session }

class _PlanItem {
  final DateTime date;
  final String title;
  final String subtitle;
  final _PlanKind kind;
  final Map<String, String>? sourceItem;
  const _PlanItem({
    required this.date,
    required this.title,
    required this.subtitle,
    required this.kind,
    this.sourceItem,
  });
}

class _PlannerCalendar extends StatefulWidget {
  final List<StudySession> sessions;
  final List<Map<String, String>> courses;
  final List<Map<String, String>> deadlines;
  final bool Function(Map<String, String> item) canEditItem;
  final ValueChanged<Map<String, String>> onEditCourse;
  final ValueChanged<Map<String, String>> onDeleteCourse;
  final ValueChanged<Map<String, String>> onEditDeadline;
  final ValueChanged<Map<String, String>> onDeleteDeadline;

  const _PlannerCalendar({
    required this.sessions,
    required this.courses,
    required this.deadlines,
    required this.canEditItem,
    required this.onEditCourse,
    required this.onDeleteCourse,
    required this.onEditDeadline,
    required this.onDeleteDeadline,
  });

  @override
  State<_PlannerCalendar> createState() => _PlannerCalendarState();
}

class _PlannerCalendarState extends State<_PlannerCalendar> {
  static const int _days = 14;

  late DateTime _start;
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _start = DateTime(now.year, now.month, now.day);
    _selected = _start;
  }

  List<DateTime> get _window =>
      List.generate(_days, (i) => _start.add(Duration(days: i)));

  static const _weekdayNames = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  static const _monthAbbrev = {
    'jan': 1,
    'feb': 2,
    'mar': 3,
    'apr': 4,
    'may': 5,
    'jun': 6,
    'jul': 7,
    'aug': 8,
    'sep': 9,
    'oct': 10,
    'nov': 11,
    'dec': 12,
  };

  int? _weekdayFromText(String text) {
    final lower = text.toLowerCase();
    for (var i = 0; i < _weekdayNames.length; i++) {
      final full = _weekdayNames[i];
      if (lower.contains(full) || lower.contains(full.substring(0, 3))) {
        return i + 1; // DateTime.weekday is 1=Mon..7=Sun
      }
    }
    return null;
  }

  List<_PlanItem> _buildItems() {
    final items = <_PlanItem>[];
    final window = _window;

    // Classes and calendar study blocks — match weekday or exact date.
    for (final c in widget.courses) {
      final iso = c['iso'];
      if (iso != null && iso.isNotEmpty) {
        final dt = DateTime.tryParse(iso);
        if (dt != null) {
          final day = DateTime(dt.year, dt.month, dt.day);
          if (window.any((w) => _sameDay(w, day))) {
            items.add(_PlanItem(
              date: day,
              title: '${c['code']} · ${c['title']}',
              subtitle: c['next'] ?? '',
              kind: _PlanKind.classItem,
              sourceItem: Map<String, String>.from(c),
            ));
          }
          continue;
        }
      }
      final wd = _weekdayFromText(c['next'] ?? '');
      if (wd == null) continue;
      for (final day in window) {
        if (day.weekday == wd) {
          items.add(_PlanItem(
            date: day,
            title: '${c['code']} · ${c['title']}',
            subtitle: c['next'] ?? '',
            kind: _PlanKind.classItem,
            sourceItem: Map<String, String>.from(c),
          ));
        }
      }
    }

    // Deadlines — parse ISO first, then legacy mock strings.
    for (final d in widget.deadlines) {
      DateTime? date;
      final iso = d['iso'];
      if (iso != null && iso.isNotEmpty) {
        final dt = DateTime.tryParse(iso);
        if (dt != null) {
          date = DateTime(dt.year, dt.month, dt.day);
        }
      }
      date ??= _parseDeadline(d['due'] ?? '');
      if (date == null) continue;
      items.add(_PlanItem(
        date: date,
        title: d['title'] ?? '',
        subtitle: 'Due ${d['due']}',
        kind: _PlanKind.deadline,
        sourceItem: Map<String, String>.from(d),
      ));
    }

    // Study sessions — use real schedule when available.
    for (final s in widget.sessions) {
      if (s.startsAt != null) {
        final day = DateTime(
          s.startsAt!.year,
          s.startsAt!.month,
          s.startsAt!.day,
        );
        if (window.any((w) => _sameDay(w, day))) {
          items.add(_PlanItem(
            date: day,
            title: s.course,
            subtitle: '${s.type.label} · ${s.when}',
            kind: _PlanKind.session,
          ));
        }
        continue;
      }
      final wd = _weekdayFromText(s.when);
      if (wd == null) continue;
      for (final day in window) {
        if (day.weekday == wd) {
          items.add(_PlanItem(
            date: day,
            title: s.course,
            subtitle: '${s.type.label} · ${s.when}',
            kind: _PlanKind.session,
          ));
        }
      }
    }

    return items;
  }

  DateTime? _parseDeadline(String due) {
    // e.g. "Fri, 6 Feb" -> day 6, month Feb.
    final dayMatch = RegExp(r'(\d{1,2})').firstMatch(due);
    final monthMatch =
        RegExp(r'([A-Za-z]{3,})').allMatches(due).map((m) => m.group(1)!);
    if (dayMatch == null) return null;
    final day = int.tryParse(dayMatch.group(1)!);
    if (day == null) return null;
    int month = _start.month;
    for (final token in monthMatch) {
      final key = token.toLowerCase().substring(0, 3);
      if (_monthAbbrev.containsKey(key)) {
        month = _monthAbbrev[key]!;
        break;
      }
    }
    return DateTime(_start.year, month, day);
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Color _kindColor(_PlanKind kind) {
    switch (kind) {
      case _PlanKind.classItem:
        return AppColors.accent;
      case _PlanKind.deadline:
        return AppColors.warning;
      case _PlanKind.session:
        return AppColors.primary;
    }
  }

  IconData _kindIcon(_PlanKind kind) {
    switch (kind) {
      case _PlanKind.classItem:
        return Icons.menu_book_outlined;
      case _PlanKind.deadline:
        return Icons.flag_outlined;
      case _PlanKind.session:
        return Icons.groups_outlined;
    }
  }

  static const _weekdayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final window = _window;
    final items = _buildItems();
    final dayItems =
        items.where((it) => _sameDay(it.date, _selected)).toList();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 78,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              itemCount: window.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (_, i) {
                final day = window[i];
                final selected = _sameDay(day, _selected);
                final kinds = items
                    .where((it) => _sameDay(it.date, day))
                    .map((it) => it.kind)
                    .toSet()
                    .toList();
                return _DayPill(
                  key: ValueKey('day-${day.year}-${day.month}-${day.day}'),
                  letter: _weekdayLetters[day.weekday - 1],
                  number: day.day,
                  selected: selected,
                  dotColors: kinds.map(_kindColor).toList(),
                  onTap: () => setState(() => _selected = day),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (dayItems.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                children: [
                  const BirdSticker(row: 1, col: 1, size: 54),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Nothing planned this day — enjoy the calm.',
                      style: GoogleFonts.inter(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            ...dayItems.map(
              (it) {
                final source = it.sourceItem;
                final editable =
                    source != null && widget.canEditItem(source);
                VoidCallback? onEdit;
                VoidCallback? onDelete;
                if (editable) {
                  final item = source;
                  if (it.kind == _PlanKind.deadline) {
                    onEdit = () => widget.onEditDeadline(item);
                    onDelete = () => widget.onDeleteDeadline(item);
                  } else if (it.kind == _PlanKind.classItem) {
                    onEdit = () => widget.onEditCourse(item);
                    onDelete = () => widget.onDeleteCourse(item);
                  }
                }
                return Padding(
                  key: ValueKey('${it.kind.name}-${it.date}-${it.title}'),
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _PlanRow(
                    color: _kindColor(it.kind),
                    icon: _kindIcon(it.kind),
                    title: it.title,
                    subtitle: it.subtitle,
                    onEdit: onEdit,
                    onDelete: onDelete,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _DayPill extends StatelessWidget {
  final String letter;
  final int number;
  final bool selected;
  final List<Color> dotColors;
  final VoidCallback onTap;

  const _DayPill({
    super.key,
    required this.letter,
    required this.number,
    required this.selected,
    required this.dotColors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 46,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          gradient: selected ? AppGradients.header : null,
          color: selected ? null : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          boxShadow: selected
              ? glow(AppColors.primary,
                  alpha: 0.3, blurRadius: 14, offset: const Offset(0, 6))
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              letter,
              style: GoogleFonts.inter(
                color: selected
                    ? Colors.white.withValues(alpha: 0.85)
                    : AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$number',
              style: GoogleFonts.inter(
                color: selected ? Colors.white : AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            SizedBox(
              height: 6,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final c in dotColors.take(3)) ...[
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected ? Colors.white : c,
                      ),
                    ),
                    const SizedBox(width: 2),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanRow extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _PlanRow({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.18),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          if (onEdit != null || onDelete != null)
            _PlannerCrudActions(onEdit: onEdit, onDelete: onDelete),
        ],
      ),
    );
    if (onEdit == null) return content;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.md),
      onTap: onEdit,
      child: content,
    );
  }
}

// ---------------------------------------------------------------------------
// Courses & deadlines
// ---------------------------------------------------------------------------

class _CourseTile extends StatelessWidget {
  final String code;
  final String title;
  final String next;
  final bool canEdit;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _CourseTile({
    super.key,
    required this.code,
    required this.title,
    required this.next,
    this.canEdit = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final tile = Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: AppGradients.header,
              borderRadius: BorderRadius.circular(AppRadii.md),
              boxShadow: glow(AppColors.primary,
                  alpha: 0.22, blurRadius: 12, offset: const Offset(0, 5)),
            ),
            child: const Icon(Icons.menu_book_outlined, color: Colors.white),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$code · $title',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                Text('Next: $next',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          if (canEdit)
            _PlannerCrudActions(onEdit: onEdit, onDelete: onDelete),
        ],
      ),
    );
    if (!canEdit || onEdit == null) return tile;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.lg),
      onTap: onEdit,
      child: tile,
    );
  }
}

class _DeadlineTile extends StatelessWidget {
  final String title;
  final String due;
  final bool canEdit;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _DeadlineTile({
    super.key,
    required this.title,
    required this.due,
    this.canEdit = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final tile = Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.warning,
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(title,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ),
          Text(
            due,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
          ),
          if (canEdit) ...[
            const SizedBox(width: AppSpacing.xs),
            _PlannerCrudActions(onEdit: onEdit, onDelete: onDelete),
          ],
        ],
      ),
    );
    if (!canEdit || onEdit == null) return tile;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.lg),
      onTap: onEdit,
      child: tile,
    );
  }
}

class _PlannerCrudActions extends StatelessWidget {
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _PlannerCrudActions({this.onEdit, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onEdit != null)
          IconButton(
            tooltip: 'Edit',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: onEdit,
            icon: Icon(Icons.edit_outlined,
                size: 18, color: AppColors.primary.withValues(alpha: 0.9)),
          ),
        if (onDelete != null)
          IconButton(
            tooltip: 'Delete',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: onDelete,
            icon: Icon(Icons.delete_outline_rounded,
                size: 18, color: AppColors.danger.withValues(alpha: 0.85)),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Performance
// ---------------------------------------------------------------------------

class _DreamyDropdown extends StatefulWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final bool initiallyExpanded;
  final String? subtitle;

  const _DreamyDropdown({
    required this.title,
    required this.icon,
    required this.child,
    this.initiallyExpanded = false,
    this.subtitle,
  });

  @override
  State<_DreamyDropdown> createState() => _DreamyDropdownState();
}

class _DreamyDropdownState extends State<_DreamyDropdown> {
  late bool _open = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: cardDecoration(),
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
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: AppGradients.header,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      boxShadow: glow(AppColors.primary,
                          alpha: 0.22,
                          blurRadius: 12,
                          offset: const Offset(0, 5)),
                    ),
                    child: Icon(widget.icon, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: GoogleFonts.inter(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
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
                    child: const Icon(
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
  }
}

class _PlannerActions extends StatelessWidget {
  const _PlannerActions();

  static final _compactButtonStyle = ButtonStyle(
    padding: const WidgetStatePropertyAll(
      EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    ),
    visualDensity: VisualDensity.compact,
  );

  static Future<(String, DateTime)?> promptCalendarItem(
    BuildContext context, {
    required String title,
    required String hint,
    String initialTitle = '',
    required DateTime initialWhen,
  }) async {
    final ctrl = TextEditingController(text: initialTitle);
    var when = initialWhen;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ctrl,
                decoration: InputDecoration(hintText: hint),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: ctx,
                    initialDate: when,
                    firstDate: DateTime.now().subtract(const Duration(days: 1)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date == null) return;
                  if (!ctx.mounted) return;
                  final time = await showTimePicker(
                    context: ctx,
                    initialTime: TimeOfDay.fromDateTime(when),
                  );
                  if (time == null) return;
                  setLocal(() {
                    when = DateTime(
                      date.year,
                      date.month,
                      date.day,
                      time.hour,
                      time.minute,
                    );
                  });
                },
                icon: const Icon(Icons.event_outlined),
                label: Text(
                  '${when.day}/${when.month}/${when.year} · ${TimeOfDay.fromDateTime(when).format(ctx)}',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return null;
    final text = ctrl.text.trim();
    return (text, when);
  }

  static Future<(String, String)?> promptStudyEntry(
    BuildContext context, {
    required String title,
    required String hint,
    String initialTitle = '',
    String initialNext = '',
  }) async {
    final titleCtrl = TextEditingController(text: initialTitle);
    final nextCtrl = TextEditingController(text: initialNext);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: InputDecoration(hintText: hint),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: nextCtrl,
              decoration: const InputDecoration(
                hintText: 'When (e.g. Mon 4:00 PM)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (ok != true) return null;
    final name = titleCtrl.text.trim();
    final next = nextCtrl.text.trim();
    if (name.isEmpty) return null;
    return (name, next.isEmpty ? 'TBA' : next);
  }

  Future<void> _prompt(BuildContext context, {
    required String title,
    required String hint,
    required Future<bool> Function(String text, DateTime when) onSubmit,
  }) async {
    final saved = await promptCalendarItem(
      context,
      title: title,
      hint: hint,
      initialWhen: DateTime.now().add(const Duration(days: 3)),
    );
    if (saved == null || !context.mounted) return;
    final ok = await onSubmit(saved.$1, saved.$2);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Saved to your planner.' : 'Could not save item.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: _compactButtonStyle,
                onPressed: () => _prompt(
                  context,
                  title: 'Add deadline',
                  hint: 'e.g. Project proposal',
                  onSubmit: (text, when) =>
                      context.read<AppState>().addCalendarDeadline(
                            title: text.isEmpty ? 'Deadline' : text,
                            dueAt: when,
                          ),
                ),
                icon: const Icon(Icons.flag_outlined, size: 18),
                label: const Text('Deadline'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: OutlinedButton.icon(
                style: _compactButtonStyle,
                onPressed: () => _prompt(
                  context,
                  title: 'Add course block',
                  hint: 'e.g. CS401 lecture',
                  onSubmit: (text, when) =>
                      context.read<AppState>().addCalendarCourse(
                            title: text.isEmpty ? 'Course block' : text,
                            startsAt: when,
                          ),
                ),
                icon: const Icon(Icons.menu_book_outlined, size: 18),
                label: const Text('Course'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          style: _compactButtonStyle,
          onPressed: () async {
            final ctrl = TextEditingController();
            final course = await showDialog<String>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Study plan'),
                content: TextField(
                  controller: ctrl,
                  decoration: const InputDecoration(
                    hintText: 'Focus course (e.g. Data Structures)',
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
                    child: const Text('Create'),
                  ),
                ],
              ),
            );
            if (course == null || course.isEmpty || !context.mounted) return;
            final ok = await context
                .read<AppState>()
                .generateStudyPlan(focusCourse: course);
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  ok
                      ? 'Study plan generated — check My Courses & Schedule.'
                      : 'Could not generate study plan.',
                ),
              ),
            );
          },
          icon: const Icon(Icons.auto_graph_outlined, size: 18),
          label: const Text('Study plan'),
        ),
      ],
    );
  }
}

class _GpaCard extends StatelessWidget {
  final bool useBackend;
  const _GpaCard({this.useBackend = false});

  @override
  Widget build(BuildContext context) {
    if (useBackend) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: cardDecoration(),
        child: Row(
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceMuted,
              ),
              alignment: Alignment.center,
              child: Icon(Icons.school_outlined,
                  size: 36, color: AppColors.textMuted),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Current GPA',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          )),
                  const SizedBox(height: 6),
                  Text('Not synced yet',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          )),
                  const SizedBox(height: 6),
                  Text(
                    'AAURA will show your official GPA once the registrar feed is connected. Use the planner below to stay on track meanwhile.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.35,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: cardDecoration(),
      child: Row(
        children: [
          const GlowRing(
            progress: 0.85,
            size: 92,
            strokeWidth: 9,
            centerLabel: '3.42',
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Current GPA',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            )),
                    const Spacer(),
                    Text('Spring 2026',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: AppColors.textMuted,
                            )),
                  ],
                ),
                const SizedBox(height: 6),
                Text('3.42',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        )),
                const SizedBox(height: 6),
                Text('Goal: 3.7 by end of semester',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
