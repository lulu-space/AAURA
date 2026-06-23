import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../models/event.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/stat_chip.dart';

enum _EventReviewFilter {
  pending,
  approved,
  rejected;

  String get label {
    switch (this) {
      case _EventReviewFilter.pending:
        return 'Pending';
      case _EventReviewFilter.approved:
        return 'Approved';
      case _EventReviewFilter.rejected:
        return 'Rejected';
    }
  }
}

/// Student Affairs review queue for club-organizer / student events.
class EventReviewsScreen extends StatefulWidget {
  const EventReviewsScreen({super.key});

  @override
  State<EventReviewsScreen> createState() => _EventReviewsScreenState();
}

class _EventReviewsScreenState extends State<EventReviewsScreen> {
  _EventReviewFilter _filter = _EventReviewFilter.pending;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppState>().refreshClubRequestQueue();
    });
  }

  bool _matchesFilter(Event event, _EventReviewFilter filter) {
    switch (filter) {
      case _EventReviewFilter.pending:
        return !event.isApproved && event.status != 'cancelled';
      case _EventReviewFilter.approved:
        return event.isApproved && event.status == 'published';
      case _EventReviewFilter.rejected:
        return event.status == 'cancelled';
    }
  }

  Future<void> _review(Event event, {required bool approve}) async {
    final noteCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(approve ? 'Approve event?' : 'Reject event?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '"${event.title}" by ${event.organizer}',
              style: Theme.of(ctx).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: noteCtrl,
              decoration: InputDecoration(
                labelText:
                    approve ? 'Note to organizer (optional)' : 'Reason (optional)',
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
        ? await state.approveEventReview(event.id, note: note)
        : await state.rejectEventReview(event.id, note: note);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok
          ? (approve
              ? 'Event approved — "${event.title}" is now live.'
              : 'Event rejected.')
          : 'Action failed. Check your role and try again.'),
    ));
  }

  Future<void> _withdraw(Event event) async {
    final noteCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Withdraw approval?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'This removes "${event.title}" from the public events list '
              'until it is approved again.',
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
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final error = await context.read<AppState>().withdrawEventReview(
          event.id,
          note: noteCtrl.text.trim(),
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        error == null ? 'Event approval withdrawn.' : error,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final all = state.eventReviewQueue;
    final filtered = all.where((e) => _matchesFilter(e, _filter)).toList();
    final pending = state.pendingEventReviewCount;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Event Reviews')),
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
                    'Student event submissions',
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
                        icon: Icons.event_outlined,
                        label: '${all.length} total',
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Club organizers submit events for review before they go live. '
                    'Approve, reject, or withdraw with an optional note.',
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
                for (final f in _EventReviewFilter.values)
                  f: all.where((e) => _matchesFilter(e, f)).length,
              },
              onChanged: (f) => setState(() => _filter = f),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (filtered.isEmpty)
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: cardDecoration(),
                child: Text(
                  'No ${_filter.label.toLowerCase()} student events.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              )
            else
              for (var i = 0; i < filtered.length; i++) ...[
                _EventReviewCard(
                  event: filtered[i],
                  onApprove: () => _review(filtered[i], approve: true),
                  onReject: () => _review(filtered[i], approve: false),
                  onWithdraw: filtered[i].isApproved &&
                          filtered[i].status == 'published'
                      ? () => _withdraw(filtered[i])
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
  final _EventReviewFilter current;
  final Map<_EventReviewFilter, int> counts;
  final ValueChanged<_EventReviewFilter> onChanged;

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
          for (final f in _EventReviewFilter.values)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(f),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: current == f ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                  child: Text(
                    counts[f] != null && counts[f]! > 0
                        ? '${f.label} (${counts[f]})'
                        : f.label,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: current == f
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

class _EventReviewCard extends StatelessWidget {
  final Event event;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback? onWithdraw;

  const _EventReviewCard({
    required this.event,
    required this.onApprove,
    required this.onReject,
    this.onWithdraw,
  });

  @override
  Widget build(BuildContext context) {
    final pending = !event.isApproved && event.status != 'cancelled';
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            event.title,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            '${event.organizer} · ${event.date} · ${event.location}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          if (event.about.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              event.about,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          if (event.possibleDuplicate) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: AppColors.accentLight.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Text(
                event.duplicateMatchCount > 1
                    ? 'Possible duplicate — ${event.duplicateMatchCount} similar events on this date'
                    : 'Possible duplicate — similar event on this date from another organizer',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
              ),
            ),
          ],
          if (event.approvalNote != null && event.approvalNote!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Note: ${event.approvalNote}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                  child: OutlinedButton(
                    onPressed: onReject,
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onApprove,
                    child: const Text('Approve'),
                  ),
                ),
              ],
            )
          else if (onWithdraw != null)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onWithdraw,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                ),
                child: const Text('Withdraw approval'),
              ),
            ),
        ],
      ),
    );
  }
}
