import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../models/volunteer_request.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bird_avatar.dart';
import '../../widgets/dawn_scene.dart';
import '../../widgets/glow_widgets.dart';
import '../../widgets/stat_chip.dart';

/// Staff-only queue for reviewing student volunteer hour submissions.
class ApprovalsScreen extends StatefulWidget {
  const ApprovalsScreen({super.key});

  @override
  State<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends State<ApprovalsScreen> {
  VolunteerRequestStatus _filter = VolunteerRequestStatus.pending;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppState>().refreshVolunteerRecords();
    });
  }

  Future<void> _reviewVolunteer(
    VolunteerRequest request, {
    required bool approve,
  }) async {
    final noteCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(approve ? 'Approve hours?' : 'Reject hours?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${request.studentName} · ${request.hours} h · ${request.eventTitle}',
              style: Theme.of(ctx).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: noteCtrl,
              decoration: InputDecoration(
                labelText: approve
                    ? 'Note to student (optional)'
                    : 'Reason for rejection (optional)',
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
            child: Text(approve ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final state = context.read<AppState>();
    final note = noteCtrl.text.trim();
    final ok = approve
        ? await state.approveVolunteerRequest(request.id, note: note)
        : await state.rejectVolunteerRequest(request.id, note: note);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok
          ? (approve
              ? 'Volunteer hours approved for ${request.studentName}.'
              : 'Volunteer hours rejected for ${request.studentName}.')
          : 'Could not update volunteer hours. Check your connection and try again.'),
    ));
  }

  Future<void> _withdrawDecision(VolunteerRequest request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Withdraw decision?'),
        content: Text(
          'Send ${request.studentName}\'s submission for "${request.eventTitle}" '
          'back to pending review?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final ok =
        await context.read<AppState>().withdrawVolunteerDecision(request.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok
          ? 'Decision withdrawn — request is pending again.'
          : 'Could not withdraw decision. Try again.'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final all = state.volunteerRequests;
    final filtered = all.where((r) => r.status == _filter).toList();
    final name = (state.profile?.name ?? 'Staff').split(' ').first;
    final pendingCount =
        all.where((r) => r.status == VolunteerRequestStatus.pending).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppGradients.campusPage),
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: () =>
                context.read<AppState>().refreshVolunteerRecords(),
            child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxl),
            children: [
              if (Navigator.canPop(context)) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: GlowIconButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: 'Back',
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              _Hero(
                name: name,
                pending: pendingCount,
                hours: state.volunteerHours,
              )
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.05, end: 0),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Review submitted volunteer hours. Add an optional note so the '
                'student knows why hours were approved or declined.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _FilterToggle(
                current: _filter,
                counts: {
                  for (final s in VolunteerRequestStatus.values)
                    s: all.where((r) => r.status == s).length,
                },
                onChanged: (s) => setState(() => _filter = s),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (filtered.isEmpty)
                _empty(context)
              else
                for (int i = 0; i < filtered.length; i++) ...[
                  _RequestCard(
                    request: filtered[i],
                    onApprove: () =>
                        _reviewVolunteer(filtered[i], approve: true),
                    onReject: () =>
                        _reviewVolunteer(filtered[i], approve: false),
                    onWithdraw: () => _withdrawDecision(filtered[i]),
                  )
                      .animate()
                      .fadeIn(delay: (50 * i).ms, duration: 280.ms)
                      .slideY(begin: 0.06, end: 0),
                  if (i != filtered.length - 1)
                    const SizedBox(height: AppSpacing.md),
                ],
            ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _empty(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: cardDecoration(),
      child: Row(
        children: [
          const BirdSticker(row: 3, col: 0, size: 64),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Nothing here right now. ${_filter.label} volunteer hour requests will show up in this list.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final String name;
  final int pending;
  final int hours;
  const _Hero({
    required this.name,
    required this.pending,
    required this.hours,
  });

  @override
  Widget build(BuildContext context) {
    final scrimColor = AppPalette.dawnLow;
    return SizedBox(
      height: 176,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.xl),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const DawnScene(reveal: 1.0),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    scrimColor.withValues(alpha: 0.0),
                    scrimColor.withValues(alpha: 0.66),
                  ],
                ),
              ),
            ),
            Positioned(
              right: -4,
              bottom: -6,
              child: IgnorePointer(
                child: const BirdSticker(row: 4, col: 0, size: 104)
                    .animate()
                    .fadeIn(delay: 250.ms, duration: 500.ms)
                    .slideX(begin: 0.3, end: 0, curve: Curves.easeOut),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Volunteer Hours',
                    style: playfulDisplay(
                      size: 28,
                      weight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.0,
                    ).copyWith(
                      shadows: [
                        Shadow(
                          color: scrimColor.withValues(alpha: 0.8),
                          blurRadius: 14,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      StatChip(
                        icon: Icons.pending_actions_outlined,
                        label: '$pending pending',
                      ),
                      StatChip(
                        icon: Icons.verified_outlined,
                        label: '$hours h approved',
                      ),
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

class _FilterToggle extends StatelessWidget {
  final VolunteerRequestStatus current;
  final Map<VolunteerRequestStatus, int> counts;
  final ValueChanged<VolunteerRequestStatus> onChanged;

  const _FilterToggle({
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
          for (final s in VolunteerRequestStatus.values)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(s),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: current == s ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                    boxShadow: current == s
                        ? glow(AppColors.primary, alpha: 0.30, blurRadius: 14)
                        : null,
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
  final VolunteerRequest request;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onWithdraw;

  const _RequestCard({
    required this.request,
    required this.onApprove,
    required this.onReject,
    required this.onWithdraw,
  });

  @override
  Widget build(BuildContext context) {
    final pending = request.status == VolunteerRequestStatus.pending;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.accentLight,
                child: Text(
                  _initials(request.studentName),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.studentName,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      request.eventTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              _HoursBadge(hours: request.hours),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (request.approvalNote != null &&
              request.approvalNote!.trim().isNotEmpty) ...[
            Text(
              request.approvalNote!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (pending)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: BorderSide(
                          color: AppColors.danger.withValues(alpha: 0.5)),
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
          else
            Row(
              children: [
                _StatusPill(status: request.status),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: onWithdraw,
                  icon: const Icon(Icons.undo_rounded, size: 18),
                  label: const Text('Withdraw'),
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}

class _HoursBadge extends StatelessWidget {
  final int hours;
  const _HoursBadge({required this.hours});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Column(
        children: [
          Text(
            '$hours',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                ),
          ),
          Text(
            'hours',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textMuted,
                ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final VolunteerRequestStatus status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final approved = status == VolunteerRequestStatus.approved;
    final color = approved ? AppColors.success : AppColors.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(approved ? Icons.check_circle_outline : Icons.cancel_outlined,
              size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
