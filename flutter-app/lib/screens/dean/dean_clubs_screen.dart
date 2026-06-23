import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/club_card.dart';
import '../../widgets/stat_chip.dart';

class DeanClubsScreen extends StatefulWidget {
  const DeanClubsScreen({super.key});

  @override
  State<DeanClubsScreen> createState() => _DeanClubsScreenState();
}

class _DeanClubsScreenState extends State<DeanClubsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppState>().refreshDeanData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final clubs = state.deanFacultyClubs;
    final active = clubs.where((c) => c.isActive).length;
    final inactive = clubs.length - active;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Faculty Clubs')),
      body: RefreshIndicator(
        onRefresh: () => context.read<AppState>().refreshDeanData(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            if (!state.deanHasFaculty)
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: const Text(
                  'Select your faculty on the Dashboard tab to load faculty clubs.',
                ),
              )
            else ...[
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  StatChip(
                    icon: Icons.groups,
                    label: '${clubs.length} clubs',
                    background: AppColors.primary.withValues(alpha: 0.14),
                    foreground: AppColors.primary,
                  ),
                  StatChip(
                    icon: Icons.check_circle_outline,
                    label: '$active active',
                    background: AppColors.success.withValues(alpha: 0.14),
                    foreground: AppColors.success,
                  ),
                  StatChip(
                    icon: Icons.pause_circle_outline,
                    label: '$inactive inactive',
                    background: AppColors.warning.withValues(alpha: 0.14),
                    foreground: AppColors.warning,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              if (clubs.isEmpty)
                Text(
                  'No faculty clubs yet.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                )
              else
                for (final club in clubs)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: ClubCard(
                      club: club,
                      joined: false,
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}
