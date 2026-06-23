import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../widgets/skill_actions.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glow_widgets.dart';

class SkillProgressScreen extends StatelessWidget {
  const SkillProgressScreen({super.key});

  // Soft palette cycled across the rings so each skill reads a little different.
  static const _ringColors = [
    AppColors.primary,
    AppColors.accent,
    AppColors.magenta,
    AppColors.success,
    AppColors.warning,
  ];

  @override
  Widget build(BuildContext context) {
    final skills = context.watch<AppState>().skillProgress;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Skill Progress')),
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppGradients.campusPage),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text('Skill Overview',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: AppSpacing.md),
            for (var i = 0; i < 2 && i < skills.length; i++)
              _SkillRow(
                index: i,
                s: skills[i],
                color: _ringColors[i % _ringColors.length],
              ),
            const SizedBox(height: AppSpacing.lg),
            Text('Additional',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: AppSpacing.md),
            for (var i = 2; i < skills.length; i++)
              _SkillRow(
                index: i,
                s: skills[i],
                color: _ringColors[i % _ringColors.length],
              ),
            const SizedBox(height: AppSpacing.xl),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(
                'Progress starts from your Shams profile (based on how much Shams understood you), '
                'then grows when you join events, study sessions, complete goals, and earn '
                'volunteer hours. Rings cap at 90% — campus skills are always growing.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkillRow extends StatelessWidget {
  final int index;
  final Map<String, dynamic> s;
  final Color color;
  const _SkillRow({
    required this.index,
    required this.s,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (s['progress'] as num).toDouble();
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.lg),
      onTap: () => showSkillActionsSheet(context, index, s),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: cardDecoration(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GlowRing(
              progress: progress,
              size: 68,
              strokeWidth: 7,
              color: color,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s['name'] as String,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(s['note'] as String,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          )),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.trending_up,
                          color: AppColors.success, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(s['change'] as String,
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(color: AppColors.success)),
                      ),
                      Icon(Icons.edit_outlined,
                          size: 16, color: AppColors.textMuted),
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
