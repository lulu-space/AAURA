import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final _recWeight = TextEditingController();
  final _predThreshold = TextEditingController();
  final _checkInPoints = TextEditingController();
  final _volunteerPoints = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await context.read<AppState>().refreshAdminData();
      if (!mounted) return;
      _loadFromState();
    });
  }

  void _loadFromState() {
    final settings = context.read<AppState>().adminSettings;
    final ai = settings?['ai_settings'] as Map<String, dynamic>? ?? const {};
    final points = settings?['points_rules'] as Map<String, dynamic>? ?? const {};
    _recWeight.text = '${ai['recommendation_weight'] ?? 0.65}';
    _predThreshold.text = '${ai['prediction_threshold'] ?? 0.55}';
    _checkInPoints.text = '${points['event_check_in_points'] ?? 10}';
    _volunteerPoints.text = '${points['volunteer_hour_points'] ?? 5}';
  }

  @override
  void dispose() {
    _recWeight.dispose();
    _predThreshold.dispose();
    _checkInPoints.dispose();
    _volunteerPoints.dispose();
    super.dispose();
  }

  Future<void> _saveAi() async {
    final error = await context.read<AppState>().adminUpdateSettings('ai_settings', {
      'recommendation_weight': double.tryParse(_recWeight.text.trim()) ?? 0.65,
      'prediction_threshold': double.tryParse(_predThreshold.text.trim()) ?? 0.55,
      'interest_match_weight': 0.4,
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'AI settings saved.')),
    );
  }

  Future<void> _savePoints() async {
    final error = await context.read<AppState>().adminUpdateSettings('points_rules', {
      'event_check_in_points': int.tryParse(_checkInPoints.text.trim()) ?? 10,
      'volunteer_hour_points': int.tryParse(_volunteerPoints.text.trim()) ?? 5,
      'club_join_points': 3,
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Points rules saved.')),
    );
  }

  Future<void> _logout() async {
    await context.read<AppState>().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final badges = context.watch<AppState>().adminBadges;
    final logs = context.watch<AppState>().adminAuditLogs;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Settings')),
      body: RefreshIndicator(
        onRefresh: () => context.read<AppState>().refreshAdminData(),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text('AI settings', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: AppSpacing.sm),
            TextField(controller: _recWeight, decoration: const InputDecoration(labelText: 'Recommendation weight')),
            TextField(controller: _predThreshold, decoration: const InputDecoration(labelText: 'Prediction threshold')),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(onPressed: _saveAi, child: const Text('Save AI settings')),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Points rules', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: AppSpacing.sm),
            TextField(controller: _checkInPoints, decoration: const InputDecoration(labelText: 'Event check-in points')),
            TextField(controller: _volunteerPoints, decoration: const InputDecoration(labelText: 'Volunteer hour points')),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(onPressed: _savePoints, child: const Text('Save points rules')),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Badges', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: AppSpacing.sm),
            for (final badge in badges)
              ListTile(
                tileColor: AppColors.surface,
                title: Text(badge['name']?.toString() ?? badge['id']?.toString() ?? 'Badge'),
                subtitle: Text(badge['description']?.toString() ?? ''),
              ),
            const SizedBox(height: AppSpacing.lg),
            Text('Audit logs', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: AppSpacing.sm),
            if (logs.isEmpty)
              const Text('No audit logs yet.')
            else
              for (final log in logs.take(20))
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  child: Text(
                    '${log['created_at']} · ${log['action']} · ${log['resource']}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                label: const Text('Log out'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
