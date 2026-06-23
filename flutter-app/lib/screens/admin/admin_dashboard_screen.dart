import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/stat_chip.dart';

class AdminDashboardScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigate;

  const AdminDashboardScreen({super.key, this.onNavigate});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppState>().refreshAdminData();
    });
  }

  Future<void> _announce() async {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    final send = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('System announcement'),
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
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Send')),
        ],
      ),
    );
    if (send != true || !mounted) {
      titleCtrl.dispose();
      bodyCtrl.dispose();
      return;
    }
    final error = await context.read<AppState>().sendAdminAnnouncement(
          title: titleCtrl.text.trim(),
          body: bodyCtrl.text.trim(),
        );
    titleCtrl.dispose();
    bodyCtrl.dispose();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'System announcement sent.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final dash = state.adminDashboard;
    final name = (state.profile?.name ?? 'Admin').split(' ').first;

    Widget chip(String label, IconData icon, Color color) => StatChip(
          icon: icon,
          label: label,
          background: color.withValues(alpha: 0.14),
          foreground: color,
        );

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
            onRefresh: () => context.read<AppState>().refreshAdminData(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
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
                  'System admin dashboard',
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    chip('${dash?['users'] ?? 0} users', Icons.people_outline, AppColors.primary),
                    chip('${dash?['suspended_users'] ?? 0} suspended', Icons.block, AppColors.danger),
                    chip('${dash?['events'] ?? 0} events', Icons.event_outlined, AppColors.primary),
                    chip('${dash?['clubs'] ?? 0} clubs', Icons.groups_outlined, AppColors.success),
                    chip('${dash?['volunteering_records'] ?? 0} volunteer rows', Icons.volunteer_activism_outlined, AppColors.accent),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Pending workflows (Student Affairs)',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Volunteer approvals: ${dash?['pending_volunteer_reviews'] ?? 0} · '
                  'Event reviews: ${dash?['pending_event_reviews'] ?? 0} · '
                  'Club requests: ${dash?['pending_club_requests'] ?? 0}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.lg),
                _ActionTile(
                  icon: Icons.campaign_outlined,
                  title: 'System-wide announcement',
                  subtitle: 'Notify all active users',
                  onTap: _announce,
                ),
                const SizedBox(height: AppSpacing.sm),
                _ActionTile(
                  icon: Icons.people_outline,
                  title: 'Manage users',
                  subtitle: 'Roles, suspend, reactivate',
                  onTap: () => widget.onNavigate?.call(1),
                ),
                const SizedBox(height: AppSpacing.sm),
                _ActionTile(
                  icon: Icons.shield_outlined,
                  title: 'Moderate content',
                  subtitle: 'Events, clubs, posts, messages',
                  onTap: () => widget.onNavigate?.call(2),
                ),
                const SizedBox(height: AppSpacing.sm),
                _ActionTile(
                  icon: Icons.insights_outlined,
                  title: 'System analytics',
                  subtitle: 'Engagement, volunteering, gamification',
                  onTap: () => widget.onNavigate?.call(3),
                ),
                const SizedBox(height: AppSpacing.sm),
                _ActionTile(
                  icon: Icons.settings_outlined,
                  title: 'Settings & audit logs',
                  subtitle: 'AI weights, points rules, badges',
                  onTap: () => widget.onNavigate?.call(4),
                ),
              ],
            ),
          ),
        ),
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
