import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_exception.dart';
import '../../models/event.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/transitions.dart';
import 'attend_success_screen.dart';

class AttendEventScreen extends StatefulWidget {
  const AttendEventScreen({super.key});

  @override
  State<AttendEventScreen> createState() => _AttendEventScreenState();
}

class _AttendEventScreenState extends State<AttendEventScreen> {
  bool _busy = false;

  Future<void> _scanFakeQr() async {
    final state = context.read<AppState>();
    final token = state.nextCheckInQrToken;
    if (token != null) {
      await _checkIn(token);
      return;
    }
    final pool = state.allEvents;
    if (pool.isEmpty) {
      _snack('Reserve an event first, then check in with its QR code.');
      return;
    }
    await _attendMock(pool.first);
  }

  Future<void> _checkIn(String qrToken) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final event = await context.read<AppState>().checkInByQrToken(qrToken);
      if (!mounted) return;
      if (event == null) {
        _snack('Check-in failed. Use a valid reservation QR from your join link.');
        return;
      }
      Navigator.of(context).pushReplacement(
        FadeSlidePageRoute(
          builder: (_) => AttendSuccessScreen(event: event),
        ),
      );
    } on ApiException catch (e) {
      if (mounted) _snack(e.message);
    } catch (_) {
      if (mounted) _snack('Check-in failed.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _attendMock(Event event) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await context
          .read<AppState>()
          .toggleEventJoin(event.id, rewardPoints: event.points);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        FadeSlidePageRoute(
          builder: (_) => AttendSuccessScreen(event: event),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final hasQr = context.watch<AppState>().nextCheckInQrToken != null;
    return Scaffold(
      appBar: AppBar(title: const Text('Attend event')),
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
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                      ),
                      child: Text(
                        'Scan your check-in QR',
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
                onPressed: _busy ? null : _scanFakeQr,
                icon: const Icon(Icons.qr_code_scanner),
                label: Text(hasQr ? 'Simulate scan' : 'Simulate scan (offline)'),
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
                children: [
                  const Icon(Icons.info_outline, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      hasQr
                          ? 'Enroll via the organizer’s join link first, then scan your check-in QR here.'
                          : 'Open the event join link from your dean or Student Affairs, enroll via QR, then return here to check in.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
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
    Widget cornerBox(BorderSide top, BorderSide right, BorderSide bottom,
            BorderSide left) =>
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
