import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/stat_chip.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppState>().refreshAdminData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final analytics = context.watch<AppState>().adminAnalytics;
    final engagement = analytics?['engagement'] as Map<String, dynamic>? ?? const {};
    final volunteering = analytics?['volunteering'] as Map<String, dynamic>? ?? const {};
    final gamification = analytics?['gamification'] as Map<String, dynamic>? ?? const {};
    final usersByRole = analytics?['users_by_role'] as Map<String, dynamic>? ?? const {};
    final volunteerRows = context.watch<AppState>().adminVolunteeringRecords;

    Widget chip(String label, IconData icon, Color color) => StatChip(
          icon: icon,
          label: label,
          background: color.withValues(alpha: 0.14),
          foreground: color,
        );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('System analytics')),
      body: RefreshIndicator(
        onRefresh: () => context.read<AppState>().refreshAdminData(),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(
              'Engagement',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                chip('${engagement['event_enrollments'] ?? 0} enrollments', Icons.event_available, AppColors.primary),
                chip('${engagement['event_check_ins'] ?? 0} check-ins', Icons.qr_code_scanner, AppColors.accent),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Volunteering (view only — approvals handled by Student Affairs)',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                chip('${volunteering['approved_hours'] ?? 0}h approved', Icons.volunteer_activism_outlined, AppColors.success),
                chip('${volunteering['approved_records'] ?? 0} records', Icons.list_alt, AppColors.primary),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Gamification',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                chip('${gamification['total_points_awarded'] ?? 0} total points', Icons.stars, AppColors.warning),
                chip('${gamification['profiles'] ?? 0} profiles', Icons.person_outline, AppColors.primary),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Users by role',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final entry in usersByRole.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('${entry.key}: ${entry.value}'),
              ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Recent volunteering records',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (volunteerRows.isEmpty)
              Text('No records.', style: Theme.of(context).textTheme.bodySmall)
            else
              for (final row in volunteerRows.take(12))
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  child: Text(
                    '${row['title']} · ${row['hours']}h · ${row['status']}',
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
