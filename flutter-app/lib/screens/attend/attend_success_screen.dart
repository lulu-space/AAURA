import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../models/event.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';

class AttendSuccessScreen extends StatelessWidget {
  final Event event;
  const AttendSuccessScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final pinned = state.isCvPinned(event.id);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.xl),
              Container(
                width: 120,
                height: 120,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.success, AppColors.accent],
                  ),
                ),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 64),
              )
                  .animate()
                  .scaleXY(
                      begin: 0.4,
                      end: 1.0,
                      curve: Curves.easeOutBack,
                      duration: 500.ms)
                  .fadeIn(),
              const SizedBox(height: AppSpacing.lg),
              Text('Hours Registered!',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800))
                  .animate()
                  .fadeIn(delay: 200.ms),
              const SizedBox(height: 6),
              Text('Your attendance for "${event.title}" has been logged.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ))
                  .animate()
                  .fadeIn(delay: 280.ms),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: cardDecoration(),
                child: Column(
                  children: [
                    _row(
                      context,
                      icon: Icons.stars_rounded,
                      title: 'Points awarded',
                      detail: '+${event.points} pts',
                      tint: AppColors.primary,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _row(
                      context,
                      icon: Icons.access_time,
                      title: 'Service hours',
                      detail: event.duration,
                      tint: AppColors.accent,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _row(
                      context,
                      icon: Icons.assignment_ind_outlined,
                      title: 'CV updated',
                      detail: pinned ? 'Pinned to CV' : 'Not on CV',
                      tint: AppColors.success,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SwitchListTile(
                title: const Text('Show on my CV'),
                subtitle: const Text('Toggle whether this counts on your CV'),
                value: pinned,
                onChanged: (_) =>
                    context.read<AppState>().toggleCvPin(event.id),
                activeThumbColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('Scan another'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).popUntil((r) => r.isFirst);
                      },
                      icon: const Icon(Icons.home_rounded),
                      label: const Text('Done'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(BuildContext context,
      {required IconData icon,
      required String title,
      required String detail,
      required Color tint}) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: tint.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          child: Icon(icon, color: tint),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.textMuted,
                      )),
              Text(detail,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      )),
            ],
          ),
        ),
      ],
    );
  }
}
