import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/join_links.dart';
import '../../core/network/api_exception.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/transitions.dart';
import '../../widgets/campus_qr_scan_panel.dart';
import 'attend_success_screen.dart';

class AttendEventScreen extends StatefulWidget {
  const AttendEventScreen({super.key});

  @override
  State<AttendEventScreen> createState() => _AttendEventScreenState();
}

class _AttendEventScreenState extends State<AttendEventScreen> {
  bool _busy = false;

  Future<void> _checkIn(String qrToken) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final event = await context.read<AppState>().checkInByQrToken(qrToken);
      if (!mounted) return;
      if (event == null) {
        _snack('Check-in failed. Use your personal check-in QR from Enrolled events.');
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

  Future<void> _enrollThenPrompt(String raw) async {
    final error = await context.read<AppState>().joinEventByToken(raw);
    if (!mounted) return;
    if (error != null) {
      _snack(error);
      return;
    }
    _snack('Enrolled! Show your check-in QR from Enrolled events at the venue.');
  }

  void _onQrScanned(String raw) async {
    if (_busy) return;

    final checkInToken = JoinLinks.parseCheckInQrToken(raw);
    if (checkInToken != null) {
      await _checkIn(checkInToken);
      return;
    }

    final joinToken = JoinLinks.parseEventToken(raw);
    if (joinToken != null) {
      setState(() => _busy = true);
      try {
        await _enrollThenPrompt(raw);
      } finally {
        if (mounted) setState(() => _busy = false);
      }
      return;
    }

    _snack('Unrecognized QR code. Use an event join QR or your check-in QR.');
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attend event')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            CampusQrScanPanel(
              accent: AppColors.accent,
              hint: 'Scan check-in or join QR',
              onDetect: _busy ? (_) {} : _onQrScanned,
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
                      'Scan your personal check-in QR from Profile → Enrolled events, '
                      'or scan an organizer’s event join QR to enroll first.',
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
}
