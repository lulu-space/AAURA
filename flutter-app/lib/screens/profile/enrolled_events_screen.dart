import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../state/app_state.dart';
import '../../theme/app_theme.dart';

/// Events the student enrolled in (reservations), not only check-ins.
class EnrolledEventsScreen extends StatelessWidget {
  const EnrolledEventsScreen({super.key});

  String _monthKey(DateTime d) {
    const m = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${m[d.month - 1]} ${d.year}';
  }

  String _dayLabel(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final enrolled = state.joinedEventsSorted();

    if (enrolled.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Enrolled events')),
        body: DecoratedBox(
          decoration: const BoxDecoration(gradient: AppGradients.campusPage),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.event_busy,
                      color: AppColors.textMuted, size: 48),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    "You haven't enrolled in any events yet.\nOpen a join link from your organizer and scan the QR to enroll.",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final grouped = <String, List<({DateTime at, dynamic event})>>{};
    for (final e in enrolled) {
      final key = _monthKey(e.at);
      grouped.putIfAbsent(key, () => []).add((at: e.at, event: e.event));
    }

    var rowIndex = 0;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Enrolled events')),
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppGradients.campusPage),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
          children: [
            for (final entry in grouped.entries) ...[
              Padding(
                padding: const EdgeInsets.only(
                    top: AppSpacing.md, bottom: AppSpacing.sm),
                child: Text(
                  entry.key,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              for (final row in entry.value) ...[
                _EnrolledRow(
                  day: _dayLabel(row.at),
                  event: row.event,
                  accent: AppAccents.at(rowIndex++),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _EnrolledRow extends StatelessWidget {
  final String day;
  final dynamic event;
  final Color accent;
  const _EnrolledRow(
      {required this.day, required this.event, this.accent = AppColors.primary});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final eventId = event.id as String;
    final pinned = state.isCvPinned(eventId);
    final checkInToken = state.reservationQrTokenForEvent(eventId);
    final checkedIn = state.isEventCheckedIn(eventId);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
          Container(
            width: 50,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Column(
              children: [
                Text(day.split('/').first,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w800,
                        )),
                Text(day.split('/').last,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w600,
                        )),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.title as String,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(
                  '${event.organizer} · ${event.duration}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(AppRadii.pill),
                        ),
                        child: Text(
                          (event.category.label as String),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppRadii.pill),
                        ),
                        child: Text(
                          '+${event.points} pts',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: accent,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () =>
                context.read<AppState>().toggleCvPin(event.id as String),
            icon: Icon(
              pinned ? Icons.push_pin : Icons.push_pin_outlined,
              color: pinned ? accent : AppColors.textMuted,
            ),
            tooltip: pinned ? 'Pinned to CV' : 'Pin to CV',
          ),
            ],
          ),
          if (checkInToken != null && !checkedIn) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'Your check-in QR',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Show this at the venue or scan it from Profile → Scan.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(color: AppColors.divider),
                ),
                child: QrImageView(
                  data: checkInToken,
                  size: 120,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
          ] else if (checkedIn) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Checked in',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
