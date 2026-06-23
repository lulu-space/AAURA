import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme/app_theme.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  static const _roles = [
    'student',
    'club_organizer',
    'student_affairs',
    'dean_of_faculty',
    'admin',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppState>().refreshAdminData();
    });
  }

  Future<void> _editUser(Map<String, dynamic> user) async {
    var role = user['role']?.toString() ?? 'student';
    var suspended = user['is_suspended'] == true;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: Text(user['email']?.toString() ?? 'User'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _roles.contains(role) ? role : 'student',
                decoration: const InputDecoration(labelText: 'Role'),
                items: [
                  for (final r in _roles)
                    DropdownMenuItem(value: r, child: Text(r)),
                ],
                onChanged: (v) => setLocal(() => role = v ?? role),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Suspended'),
                value: suspended,
                onChanged: (v) => setLocal(() => suspended = v),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
          ],
        ),
      ),
    );

    if (saved != true || !mounted) return;
    final error = await context.read<AppState>().adminUpdateUser(
          user['id']?.toString() ?? '',
          role: role,
          isSuspended: suspended,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'User updated.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final users = context.watch<AppState>().adminUsers;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Users')),
      body: RefreshIndicator(
        onRefresh: () => context.read<AppState>().refreshAdminData(),
        child: users.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('No users loaded.')),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: users.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final user = users[index];
                  final suspended = user['is_suspended'] == true;
                  return ListTile(
                    tileColor: AppColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      side: BorderSide(color: AppColors.surfaceMuted),
                    ),
                    title: Text(user['full_name']?.toString() ?? user['email']?.toString() ?? 'User'),
                    subtitle: Text(
                      '${user['email']} · ${user['role']}${suspended ? ' · suspended' : ''}',
                    ),
                    trailing: const Icon(Icons.edit_outlined),
                    onTap: () => _editUser(user),
                  );
                },
              ),
      ),
    );
  }
}
