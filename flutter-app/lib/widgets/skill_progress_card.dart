import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'glow_widgets.dart';

/// A dreamy snapshot of the top skills as glowing rings, with a link to the
/// full skill breakdown. Used on the Profile page (below About).
class SkillProgressCard extends StatelessWidget {
  final VoidCallback onMore;
  final void Function(int index, Map<String, dynamic> skill)? onSkillTap;
  const SkillProgressCard({
    super.key,
    required this.onMore,
    this.onSkillTap,
  });

  static const _ringColors = [
    AppColors.primary,
    AppColors.accent,
    AppColors.magenta,
  ];

  @override
  Widget build(BuildContext context) {
    final top = context.watch<AppState>().skillProgress.take(3).toList();
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (top.isEmpty)
            Text(
              'No skills yet. Tap + to add one, or chat with Shams.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < top.length; i++)
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      onTap: onSkillTap == null
                          ? null
                          : () => onSkillTap!(i, top[i]),
                      child: Column(
                        children: [
                          GlowRing(
                            progress: (top[i]['progress'] as num).toDouble(),
                            size: 78,
                            color: _ringColors[i % _ringColors.length],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            top[i]['name'] as String,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
                onPressed: onMore, child: const Text('See all skills')),
          ),
        ],
      ),
    );
  }
}
