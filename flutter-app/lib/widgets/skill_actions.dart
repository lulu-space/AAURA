import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';

Future<void> showSkillActionsSheet(
  BuildContext context,
  int index,
  Map<String, dynamic> skill,
) async {
  final name = skill['name'] as String? ?? 'Skill';
  final action = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              name,
              style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit skill'),
              onTap: () => Navigator.of(ctx).pop('edit'),
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: AppColors.danger),
              title: Text('Delete skill',
                  style: TextStyle(color: AppColors.danger)),
              onTap: () => Navigator.of(ctx).pop('delete'),
            ),
          ],
        ),
      ),
    ),
  );
  if (!context.mounted || action == null) return;

  final state = context.read<AppState>();
  final messenger = ScaffoldMessenger.of(context);

  if (action == 'delete') {
    final ok = await state.deleteSkillAt(index);
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(content: Text(ok ? 'Skill removed.' : 'Could not delete skill.')),
    );
    return;
  }

  final ctrl = TextEditingController(text: name);
  final newName = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Edit skill'),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'Skill name'),
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
  if (newName == null || newName.isEmpty || !context.mounted) return;
  final ok = await state.updateSkillAt(index, name: newName);
  if (!context.mounted) return;
  messenger.showSnackBar(
    SnackBar(content: Text(ok ? 'Skill updated.' : 'Could not update skill.')),
  );
}
