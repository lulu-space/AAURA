import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme/app_theme.dart';

class ClubActivityView extends StatelessWidget {
  const ClubActivityView({super.key});

  IconData _iconFor(String key) {
    switch (key) {
      case 'volunteer':
        return Icons.volunteer_activism_outlined;
      case 'culture':
        return Icons.public_outlined;
      case 'debate':
        return Icons.record_voice_over_outlined;
      case 'code':
      default:
        return Icons.code_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final feed = context.watch<AppState>().clubActivityFeed;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl),
      itemCount: feed.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (_, i) {
        final post = feed[i];
        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.accent, AppColors.primary],
                      ),
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                    child: Icon(_iconFor(post['icon'] ?? ''),
                        color: Colors.white),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(post['club'] ?? '',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w800)),
                        Text(post['when'] ?? '',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(post['title'] ?? '',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(post['body'] ?? '',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      )),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.thumb_up_alt_outlined,
                        size: 16, color: AppColors.primary),
                    label: const Text('Like'),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Liked!')),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  ActionChip(
                    avatar: const Icon(Icons.chat_bubble_outline,
                        size: 16, color: AppColors.primary),
                    label: const Text('Discuss'),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Discussion thread')),
                      );
                    },
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Open ${post['club'] ?? 'club'}'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.arrow_forward, size: 16),
                    label: const Text('Open club'),
                  ),
                ],
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(delay: (60 * i).ms)
            .slideY(begin: 0.1, end: 0);
      },
    );
  }
}
