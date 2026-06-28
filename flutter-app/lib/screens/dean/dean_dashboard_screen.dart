import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../data/dean_faculties.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/transitions.dart';
import '../../widgets/stat_chip.dart';
import 'dean_events_screen.dart';
import 'dean_reports_screen.dart';

class DeanDashboardScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigate;

  const DeanDashboardScreen({super.key, this.onNavigate});

  @override
  State<DeanDashboardScreen> createState() => _DeanDashboardScreenState();
}

class _DeanDashboardScreenState extends State<DeanDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppState>().refreshDeanData();
    });
  }

  Future<void> _pickFaculty(BuildContext context) async {
    final state = context.read<AppState>();
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                'Select your faculty',
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            for (final faculty in DeanFaculties.options)
              ListTile(
                title: Text(faculty),
                trailing: state.assignedFaculty == faculty
                    ? const Icon(Icons.check_circle, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.pop(ctx, faculty),
              ),
          ],
        ),
      ),
    );
    if (selected == null || !mounted) return;
    final error = await context.read<AppState>().setAssignedFaculty(selected);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }

  void _openTabOrPush(int tabIndex, Widget screen) {
    if (widget.onNavigate != null) {
      widget.onNavigate!.call(tabIndex);
    } else {
      Navigator.of(context).push(FadeSlidePageRoute(builder: (_) => screen));
    }
  }

  Future<void> _announce(BuildContext context) async {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    final sent = await showDialog<bool>(
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
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Send'),
          ),
        ],
      ),
    );
    if (sent != true || !mounted) {
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
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'Announcement sent to your faculty students.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final dashboard = state.deanDashboard;
    final insights = state.deanInsights;
    final name = (state.profile?.name ?? 'Dean').split(' ').first;
    final faculty = state.assignedFaculty ?? dashboard?['faculty']?.toString();

    final canPop = Navigator.canPop(context);

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
          child: RefreshIndicator(
            onRefresh: () => context.read<AppState>().refreshDeanData(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              children: [
                if (canPop) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      tooltip: 'Back',
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                ],
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
                  faculty != null && faculty.isNotEmpty
                      ? '$faculty · Dean dashboard'
                      : 'Dean dashboard',
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (!state.deanHasFaculty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _PromptCard(
                    icon: Icons.school_outlined,
                    title: 'Choose your faculty',
                    subtitle:
                        'Your dashboard, events, clubs, and reports are scoped to one faculty.',
                    actionLabel: 'Select faculty',
                    onAction: () => _pickFaculty(context),
                  ),
                ] else ...[
                  if (state.deanLastError != null &&
                      state.deanLastError!.trim().isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        border: Border.all(
                          color: AppColors.danger.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        state.deanLastError!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.danger,
                            ),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      StatChip(
                        icon: Icons.people_outline,
                        label: '${dashboard?['student_count'] ?? 0} students',
                        background: AppColors.primary.withValues(alpha: 0.14),
                        foreground: AppColors.primary,
                      ),
                      StatChip(
                        icon: Icons.event_outlined,
                        label:
                            '${dashboard?['events']?['total'] ?? 0} faculty events',
                        background: AppColors.primary.withValues(alpha: 0.14),
                        foreground: AppColors.primary,
                      ),
                      StatChip(
                        icon: Icons.groups_outlined,
                        label: '${dashboard?['clubs']?['total'] ?? 0} clubs',
                        background: AppColors.primary.withValues(alpha: 0.14),
                        foreground: AppColors.primary,
                      ),
                      StatChip(
                        icon: Icons.volunteer_activism_outlined,
                        label:
                            '${dashboard?['volunteering']?['approved_hours'] ?? 0}h volunteer',
                        background: AppColors.accent.withValues(alpha: 0.14),
                        foreground: AppColors.accent,
                      ),
                      StatChip(
                        icon: Icons.insights_outlined,
                        label:
                            '${dashboard?['engagement']?['event_check_ins'] ?? 0} check-ins',
                        background: AppColors.success.withValues(alpha: 0.14),
                        foreground: AppColors.success,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'AI insights',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _InsightSection(
                    title: 'Event engagement prediction',
                    emptyMessage: 'No predicted events yet.',
                    items: (insights?['engagement_predictions'] as List?)
                            ?.cast<Map<String, dynamic>>() ??
                        const [],
                    itemBuilder: (row) =>
                        '${row['title']} · ${row['predicted_success']?.toString() ?? '—'}% success',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _InsightSection(
                    title: 'Inactive clubs',
                    emptyMessage: 'No inactive clubs in your faculty.',
                    items: (insights?['inactive_clubs'] as List?)
                            ?.cast<Map<String, dynamic>>() ??
                        const [],
                    itemBuilder: (row) => row['name']?.toString() ?? 'Club',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _InsightSection(
                    title: 'Top student interests',
                    emptyMessage: 'No interest data yet.',
                    items: (insights?['top_student_interests'] as List?)
                            ?.cast<Map<String, dynamic>>() ??
                        const [],
                    itemBuilder: (row) =>
                        '${row['interest']} (${row['count']})',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Quick actions',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _ActionTile(
                    icon: Icons.campaign_outlined,
                    title: 'Send announcement',
                    subtitle: 'Notify students in your faculty',
                    onTap: () => _announce(context),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _ActionTile(
                    icon: Icons.event_outlined,
                    title: 'Faculty events',
                    subtitle: 'Browse and review faculty events',
                    onTap: () =>
                        _openTabOrPush(1, const DeanEventsScreen()),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _ActionTile(
                    icon: Icons.assessment_outlined,
                    title: 'Generate reports',
                    subtitle: 'Events, clubs, volunteering, engagement',
                    onTap: () =>
                        _openTabOrPush(3, const DeanReportsScreen()),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Your announcements',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (state.deanAnnouncements.isEmpty)
                    Text(
                      'No announcements sent yet.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    )
                  else
                    for (final row in state.deanAnnouncements.take(8))
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _AnnouncementCard(row: row),
                      ),
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton.icon(
                    onPressed: () => _pickFaculty(context),
                    icon: const Icon(Icons.swap_horiz),
                    label: Text('Change faculty (${faculty ?? 'none'})'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PromptCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  const _PromptCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.surfaceMuted),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 28),
          const SizedBox(height: AppSpacing.sm),
          Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.md),
          FilledButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}

class _InsightSection extends StatelessWidget {
  final String title;
  final String emptyMessage;
  final List<Map<String, dynamic>> items;
  final String Function(Map<String, dynamic> row) itemBuilder;

  const _InsightSection({
    required this.title,
    required this.emptyMessage,
    required this.items,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.surfaceMuted),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.sm),
          if (items.isEmpty)
            Text(emptyMessage, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary))
          else
            for (final row in items.take(5))
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('• ${itemBuilder(row)}'),
              ),
        ],
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  final Map<String, dynamic> row;

  const _AnnouncementCard({required this.row});

  @override
  Widget build(BuildContext context) {
    final title = row['title']?.toString() ?? 'Announcement';
    final body = row['body']?.toString() ?? '';
    final sentAt = row['created_at']?.toString() ?? '';
    final recipients = row['recipient_count'];

    return Container(
      width: double.infinity,
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
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          if (body.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              body,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            [
              if (sentAt.isNotEmpty) sentAt,
              if (recipients is num) '${recipients.toInt()} students notified',
            ].join(' · '),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textMuted,
                ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: AppColors.surfaceMuted),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                    Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                  ],
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
