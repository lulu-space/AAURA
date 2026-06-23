import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/success_burst.dart';

/// Scan an event QR code or open a join link from the organizer.
class EnrollEventScanScreen extends StatefulWidget {
  final String? initialJoinToken;

  const EnrollEventScanScreen({super.key, this.initialJoinToken});

  @override
  State<EnrollEventScanScreen> createState() => _EnrollEventScanScreenState();
}

class _EnrollEventScanScreenState extends State<EnrollEventScanScreen> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final token = widget.initialJoinToken?.trim();
    if (token != null && token.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<AppState>().setPendingEventJoinToken(token);
      });
    }
  }

  Future<void> _enroll(String token) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final error = await context.read<AppState>().joinEventByToken(token);
      if (!mounted) return;
      if (error != null) {
        _snack(error);
        return;
      }
      showSuccessBurst(context, label: 'Enrolled in event!');
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _simulateScan() async {
    final state = context.read<AppState>();
    final token = state.pendingEventJoinToken;
    if (token != null && token.isNotEmpty) {
      await _enroll(token);
      return;
    }
    _snack(
      'Open the join link your dean or Student Affairs sent you, then scan the QR code here.',
    );
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final hasPending = context.watch<AppState>().pendingEventJoinToken != null;
    return Scaffold(
      appBar: AppBar(title: const Text('Event QR')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Container(
              height: 280,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(AppRadii.lg),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ..._buildScanFrame(),
                  Container(
                    width: 200,
                    height: 4,
                    color: AppColors.accent,
                  )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .moveY(begin: -90, end: 90, duration: 1800.ms),
                  Positioned(
                    bottom: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                      ),
                      child: Text(
                        'Scan event join QR',
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _busy ? null : _simulateScan,
                icon: const Icon(Icons.qr_code_scanner),
                label: Text(hasPending ? 'Scan join link' : 'Scan QR code'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      hasPending
                          ? 'An event join link is ready. Tap Scan to enroll.'
                          : 'Organizers share a link and QR when they publish an event. Open the link on this device, then scan here to enroll.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.35,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildScanFrame() {
    const corner = SizedBox(width: 28, height: 28);
    const padding = 36.0;
    Widget cornerBox(
      BorderSide top,
      BorderSide right,
      BorderSide bottom,
      BorderSide left,
    ) =>
        Container(
          decoration: BoxDecoration(
            border: Border(top: top, right: right, bottom: bottom, left: left),
          ),
          child: corner,
        );
    final side =
        BorderSide(color: AppColors.accent.withValues(alpha: 0.9), width: 3);
    return [
      Positioned(
        top: padding,
        left: padding,
        child: cornerBox(side, BorderSide.none, BorderSide.none, side),
      ),
      Positioned(
        top: padding,
        right: padding,
        child: cornerBox(side, side, BorderSide.none, BorderSide.none),
      ),
      Positioned(
        bottom: padding,
        left: padding,
        child: cornerBox(BorderSide.none, BorderSide.none, side, side),
      ),
      Positioned(
        bottom: padding,
        right: padding,
        child: cornerBox(BorderSide.none, side, side, BorderSide.none),
      ),
    ];
  }
}
