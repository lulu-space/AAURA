import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/volunteer_requirements.dart';
import '../../models/volunteer_opportunity.dart';
import '../../models/volunteer_request.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/transitions.dart';
import 'volunteer_scan_screen.dart';

class VolunteerHoursScreen extends StatefulWidget {
  const VolunteerHoursScreen({super.key});

  @override
  State<VolunteerHoursScreen> createState() => _VolunteerHoursScreenState();
}

class _VolunteerHoursScreenState extends State<VolunteerHoursScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = context.read<AppState>();
      state.refreshVolunteerRecords();
      state.refreshVolunteerOpportunities();
      final launchToken = state.pendingVolunteerJoinToken;
      if (launchToken != null) {
        Navigator.of(context).push(
          FadeSlidePageRoute(
            builder: (_) => VolunteerScanScreen(initialJoinToken: launchToken),
          ),
        );
      }
    });
  }

  Future<void> _apply(VolunteerOpportunity opp) async {
    await Navigator.of(context).push(
      FadeSlidePageRoute(
        builder: (_) => VolunteerScanScreen(initialJoinToken: opp.joinToken),
      ),
    );
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final opportunities = state.volunteeringOpportunities;
    final mine = state.volunteerRequests;
    final approved = state.volunteerHours;
    final remaining = state.volunteerHoursRemaining;
    final goal = VolunteerRequirements.mandatoryHours;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Volunteer Hours')),
      body: RefreshIndicator(
        onRefresh: () => context.read<AppState>().refreshVolunteerRecords(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            _ProgressCard(
              approved: approved,
              remaining: remaining,
              goal: goal,
              progress: state.volunteerProgress,
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  FadeSlidePageRoute(
                    builder: (_) => const VolunteerScanScreen(),
                  ),
                ),
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Scan volunteer QR'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Open the link Student Affairs or your dean sent you, then scan the QR code to apply.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Volunteer opportunities',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Published by Student Affairs or your dean. Use their QR link to apply.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (opportunities.isEmpty)
              Text(
                'No open opportunities right now.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              )
            else
              for (final opp in opportunities) ...[
                _OpportunityCard(
                  opportunity: opp,
                  applied: state.hasAppliedForVolunteerOpportunity(opp.id),
                  onApply: () => _apply(opp),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Your applications',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (mine.isEmpty)
              Text(
                'No applications yet.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              )
            else
              for (final req in mine.take(12)) ...[
                _SubmissionRow(request: req),
                const SizedBox(height: AppSpacing.sm),
              ],
          ],
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final int approved;
  final int remaining;
  final int goal;
  final double progress;

  const _ProgressCard({
    required this.approved,
    required this.remaining,
    required this.goal,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppGradients.header,
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.volunteer_activism_outlined,
                  color: Colors.white, size: 32),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$approved of $goal hours approved',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    Text(
                      remaining > 0
                          ? '$remaining hours left to complete mandatory volunteering'
                          : 'Mandatory volunteering complete',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _OpportunityCard extends StatelessWidget {
  final VolunteerOpportunity opportunity;
  final bool applied;
  final VoidCallback onApply;

  const _OpportunityCard({
    required this.opportunity,
    required this.applied,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  opportunity.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: Text(
                  '${opportunity.estimatedHours % 1 == 0 ? opportunity.estimatedHours.toInt() : opportunity.estimatedHours.toStringAsFixed(1)}h',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ],
          ),
          if (opportunity.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              opportunity.description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            opportunity.eventId != null
                ? 'From campus event · ${opportunity.department}'
                : opportunity.department,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textMuted,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: applied ? null : onApply,
              icon: Icon(
                applied
                    ? Icons.check_circle_outline
                    : Icons.qr_code_scanner_outlined,
              ),
              label: Text(
                applied ? 'Applied — pending review' : 'Scan QR to apply',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmissionRow extends StatelessWidget {
  final VolunteerRequest request;

  const _SubmissionRow({required this.request});

  @override
  Widget build(BuildContext context) {
    final color = switch (request.status) {
      VolunteerRequestStatus.approved => AppColors.success,
      VolunteerRequestStatus.rejected => AppColors.danger,
      VolunteerRequestStatus.pending => AppColors.warning,
    };
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: cardDecoration(),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.eventTitle,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(
                  '${request.hours}h · ${request.submittedAt}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                if (request.approvalNote != null &&
                    request.approvalNote!.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    request.status == VolunteerRequestStatus.approved
                        ? 'Staff note: ${request.approvalNote}'
                        : 'Reason: ${request.approvalNote}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: request.status ==
                                  VolunteerRequestStatus.rejected
                              ? AppColors.danger
                              : AppColors.textMuted,
                        ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadii.pill),
            ),
            child: Text(
              request.status.label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
