import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/dean_faculties.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Mock notification preferences (prototype-only, not persisted).
  bool _eventReminders = true;
  bool _clubUpdates = true;
  bool _pointsAndBadges = true;
  bool _weeklyDigest = false;

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
    final state = context.watch<AppState>();
    final profile = state.profile;
    final isStaffOrAffairs = state.isStaffOrAffairs;
    final isDean = state.isDeanOfFaculty;
    final idLabel = isDean
        ? 'Faculty ID'
        : isStaffOrAffairs
            ? 'Staff ID'
            : 'Student ID';
    final idValue = isDean
        ? (state.assignedFaculty ?? 'Not set')
        : (profile?.studentId ?? '-');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Settings')),
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppGradients.campusPage),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            _SectionTitle('Account'),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: cardDecoration(),
              child: Column(
                children: [
                  _InfoRow(label: 'Name', value: profile?.name ?? '-'),
                  _InfoRow(label: idLabel, value: idValue),
                  if (isDean)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Change faculty',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        state.assignedFaculty ?? 'Tap to choose your faculty',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                      trailing:
                          Icon(Icons.chevron_right, color: AppColors.textMuted),
                      onTap: () => _pickFaculty(context),
                    ),
                  _InfoRow(label: 'Email', value: profile?.email ?? '-'),
                  _InfoRow(
                      label: 'Role', value: profile?.role.label ?? 'Student'),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _SectionTitle('Notifications'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              decoration: cardDecoration(),
              child: Column(
                children: state.isStudentAffairs
                    ? _affairsNotificationToggles()
                    : isDean
                        ? _deanNotificationToggles()
                        : _studentNotificationToggles(),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _SectionTitle('Help & About'),
            Container(
              decoration: cardDecoration(),
              child: Column(
                children: [
                  _LinkRow(
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                    onTap: () => _snack('Support is not available in the prototype.'),
                  ),
                  const Divider(height: 1),
                  _LinkRow(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    onTap: () => _snack('Privacy policy is a placeholder.'),
                  ),
                  const Divider(height: 1),
                  _LinkRow(
                    icon: Icons.info_outline,
                    title: 'About AAURA',
                    subtitle: 'Version 1.0.0 (prototype)',
                    onTap: () => _snack('AAURA - campus life, reimagined.'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: _logout,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
              ),
              icon: const Icon(Icons.logout),
              label: const Text('Log out'),
            ),
          ],
        ),
      ),
    );
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
      _snack(error);
    } else {
      _snack('Faculty updated to $selected.');
    }
  }

  List<Widget> _deanNotificationToggles() => [
        _ToggleRow(
          title: 'Faculty announcements',
          subtitle: 'When you send updates to your students',
          value: _eventReminders,
          onChanged: (v) => setState(() => _eventReminders = v),
        ),
        _ToggleRow(
          title: 'Faculty event activity',
          subtitle: 'New events and check-ins in your faculty',
          value: _clubUpdates,
          onChanged: (v) => setState(() => _clubUpdates = v),
        ),
        _ToggleRow(
          title: 'Weekly digest',
          subtitle: 'Faculty engagement summary',
          value: _weeklyDigest,
          onChanged: (v) => setState(() => _weeklyDigest = v),
        ),
      ];

  List<Widget> _studentNotificationToggles() => [
        _ToggleRow(
          title: 'Event reminders',
          subtitle: 'Before events you joined',
          value: _eventReminders,
          onChanged: (v) => setState(() => _eventReminders = v),
        ),
        _ToggleRow(
          title: 'Club updates',
          subtitle: 'News from clubs you follow',
          value: _clubUpdates,
          onChanged: (v) => setState(() => _clubUpdates = v),
        ),
        _ToggleRow(
          title: 'Points & badges',
          subtitle: 'When you earn rewards',
          value: _pointsAndBadges,
          onChanged: (v) => setState(() => _pointsAndBadges = v),
        ),
        _ToggleRow(
          title: 'Weekly digest',
          subtitle: 'A Sunday summary of your week',
          value: _weeklyDigest,
          onChanged: (v) => setState(() => _weeklyDigest = v),
        ),
      ];

  List<Widget> _affairsNotificationToggles() => [
        _ToggleRow(
          title: 'Volunteer submissions',
          subtitle: 'When students submit hours for review',
          value: _eventReminders,
          onChanged: (v) => setState(() => _eventReminders = v),
        ),
        _ToggleRow(
          title: 'Club founding requests',
          subtitle: 'When students propose a new club',
          value: _clubUpdates,
          onChanged: (v) => setState(() => _clubUpdates = v),
        ),
        _ToggleRow(
          title: 'Student event submissions',
          subtitle: 'When club organizers submit events for review',
          value: _pointsAndBadges,
          onChanged: (v) => setState(() => _pointsAndBadges = v),
        ),
        _ToggleRow(
          title: 'Weekly digest',
          subtitle: 'Campus activity summary for Student Affairs',
          value: _weeklyDigest,
          onChanged: (v) => setState(() => _weeklyDigest = v),
        ),
      ];
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm, left: 4),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    )),
          ),
          Expanded(
            child: Text(value,
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

class _ToggleRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      title: Text(title,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: AppColors.textSecondary)),
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppColors.primary,
    );
  }
}

class _LinkRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _LinkRow({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(fontWeight: FontWeight.w600)),
      subtitle: subtitle == null
          ? null
          : Text(subtitle!,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary)),
      trailing: Icon(Icons.chevron_right, color: AppColors.textMuted),
      onTap: onTap,
    );
  }
}
