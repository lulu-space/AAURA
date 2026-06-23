import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../models/club_request.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/stat_chip.dart';

/// Staff / Student Affairs review queue for club-founding requests.
class ClubRequestReviewsScreen extends StatefulWidget {
  const ClubRequestReviewsScreen({super.key});

  @override
  State<ClubRequestReviewsScreen> createState() =>
      _ClubRequestReviewsScreenState();
}

class _ClubRequestReviewsScreenState extends State<ClubRequestReviewsScreen> {
  ClubRequestStatus _filter = ClubRequestStatus.pending;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppState>().refreshClubRequestQueue();
    });
  }

  Future<void> _review(
    ClubRequest request, {
    required bool approve,
  }) async {
    final noteCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(approve ? 'Approve club?' : 'Decline request?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '"${request.proposedName}" by ${request.requesterName}',
              style: Theme.of(ctx).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: noteCtrl,
              decoration: InputDecoration(
                labelText: approve ? 'Welcome note (optional)' : 'Reason (optional)',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: approve
                ? null
                : ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: Text(approve ? 'Approve' : 'Decline'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final state = context.read<AppState>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = approve
        ? await state.approveClubRequest(request.id, note: noteCtrl.text.trim())
        : await state.rejectClubRequest(request.id, note: noteCtrl.text.trim());

    messenger.showSnackBar(SnackBar(
      content: Text(ok == null
          ? (approve
              ? 'Club approved — ${request.requesterName} is now its organizer.'
              : 'Request declined.')
          : ok),
    ));
  }

  Future<void> _revoke(ClubRequest request) async {
    final noteCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Revoke club access?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'This deactivates "${request.proposedName}" and may demote the '
              'organizer if they have no other active clubs.',
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(labelText: 'Reason (optional)'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final ok = await context.read<AppState>().revokeClubRequest(
          request.id,
          note: noteCtrl.text.trim(),
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok == null ? 'Club access revoked.' : ok),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final all = state.clubRequestQueue;
    final filtered = all.where((r) => r.status == _filter).toList();
    final pending = state.pendingClubRequestCount;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Club Requests')),
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppGradients.campusPage),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: AppGradients.header,
                borderRadius: BorderRadius.circular(AppRadii.xl),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Club founding requests',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      StatChip(
                        icon: Icons.pending_actions_outlined,
                        label: '$pending pending',
                      ),
                      StatChip(
                        icon: Icons.groups_outlined,
                        label: '${all.length} total',
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Approve to create the club, promote the student to organizer, '
                    'and notify them. Every decision is logged.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          height: 1.35,
                        ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 350.ms),
            const SizedBox(height: AppSpacing.lg),
            _FilterBar(
              current: _filter,
              counts: {
                for (final s in ClubRequestStatus.values)
                  s: all.where((r) => r.status == s).length,
              },
              onChanged: (s) => setState(() => _filter = s),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (filtered.isEmpty)
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: cardDecoration(),
                child: Text(
                  'No ${_filter.label.toLowerCase()} club requests.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              )
            else
              for (var i = 0; i < filtered.length; i++) ...[
                _RequestCard(
                  request: filtered[i],
                  onApprove: () => _review(filtered[i], approve: true),
                  onReject: () => _review(filtered[i], approve: false),
                  onRevoke: filtered[i].status == ClubRequestStatus.approved
                      ? () => _revoke(filtered[i])
                      : null,
                )
                    .animate()
                    .fadeIn(delay: (40 * i).ms, duration: 280.ms)
                    .slideY(begin: 0.05, end: 0),
                if (i != filtered.length - 1)
                  const SizedBox(height: AppSpacing.md),
              ],
          ],
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final ClubRequestStatus current;
  final Map<ClubRequestStatus, int> counts;
  final ValueChanged<ClubRequestStatus> onChanged;

  const _FilterBar({
    required this.current,
    required this.counts,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        children: [
          for (final s in ClubRequestStatus.values)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(s),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color:
                        current == s ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                  child: Text(
                    counts[s] != null && counts[s]! > 0
                        ? '${s.label} (${counts[s]})'
                        : s.label,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: current == s
                              ? Colors.white
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final ClubRequest request;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback? onRevoke;

  const _RequestCard({
    required this.request,
    required this.onApprove,
    required this.onReject,
    this.onRevoke,
  });

  @override
  Widget build(BuildContext context) {
    final pending = request.status == ClubRequestStatus.pending;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.proposedName,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${request.requesterName} · ${request.category}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    if (request.submittedWhen.isNotEmpty)
                      Text(
                        request.submittedWhen,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.textMuted,
                            ),
                      ),
                  ],
                ),
              ),
              _StatusChip(status: request.status),
            ],
          ),
          if (request.description.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              request.description,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
            ),
          ],
          if (request.advisorEmail != null &&
              request.advisorEmail!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Advisor: ${request.advisorEmail}',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
          if (request.coFounderNames.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Co-founders: ${request.coFounderNames.join(', ')}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
          if (request.reviewNote != null && request.reviewNote!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Note: ${request.reviewNote}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textMuted,
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          if (pending)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('Decline'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                    ),
                  ),
                ),
              ],
            )
          else if (onRevoke != null)
            OutlinedButton.icon(
              onPressed: onRevoke,
              icon: const Icon(Icons.block_outlined, size: 18),
              label: const Text('Revoke access'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final ClubRequestStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      ClubRequestStatus.pending => AppColors.accent,
      ClubRequestStatus.approved => AppColors.success,
      ClubRequestStatus.rejected => AppColors.danger,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        status.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
