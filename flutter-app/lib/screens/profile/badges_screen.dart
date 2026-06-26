import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme/app_theme.dart';

class BadgesScreen extends StatelessWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final badges = state.allBadges;
    final earnedCount = badges.where((b) => !b.locked).length;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('All Badges')),
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppGradients.campusPage),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: AppGradients.header,
                borderRadius: BorderRadius.circular(AppRadii.xl),
                boxShadow: glow(AppColors.primary,
                    alpha: 0.25, blurRadius: 22, offset: const Offset(0, 12)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.workspace_premium,
                      color: Colors.white, size: 36),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Your badge collection',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                )),
                        const SizedBox(height: 2),
                        Text('$earnedCount of ${badges.length} unlocked',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Earn badges by attending events, volunteering, hosting study sessions, '
              'leading clubs, reaching 90% on a skill, and collecting 2,000+ points.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            for (var i = 0; i < badges.length; i++) ...[
              _BadgeRow(
                name: badges[i].name,
                description: badges[i].description,
                icon: badges[i].icon,
                accent: AppAccents.at(i),
                locked: badges[i].locked,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ),
      ),
    );
  }
}

class _BadgeRow extends StatelessWidget {
  final String name;
  final String description;
  final IconData icon;
  final bool locked;
  final Color accent;

  const _BadgeRow({
    required this.name,
    required this.description,
    required this.icon,
    required this.locked,
    this.accent = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    final color = locked ? AppColors.textMuted : accent;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color:
                  locked ? AppColors.surfaceMuted : accent.withValues(alpha: 0.16),
              shape: BoxShape.circle,
              boxShadow: locked
                  ? null
                  : glow(accent,
                      alpha: 0.20, blurRadius: 12, offset: const Offset(0, 5)),
            ),
            child: Icon(locked ? Icons.lock_outline : icon,
                color: color, size: 26),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(name,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700)),
                    ),
                    if (!locked)
                      const Icon(Icons.check_circle,
                          color: AppColors.success, size: 18),
                  ],
                ),
                const SizedBox(height: 2),
                Text(description,
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
