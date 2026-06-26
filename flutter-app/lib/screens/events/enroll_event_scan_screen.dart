import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/campus_qr_scan_panel.dart';
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

  Future<void> _enroll(String input) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final error = await context.read<AppState>().joinEventByToken(input);
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

  void _onQrScanned(String raw) {
    _enroll(raw);
  }

  Future<void> _confirmPending() async {
    final token = context.read<AppState>().pendingEventJoinToken;
    if (token == null || token.isEmpty) {
      _snack('Scan the event join QR code from your organizer.');
      return;
    }
    await _enroll(token);
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
            CampusQrScanPanel(
              accent: AppColors.accent,
              hint: 'Scan event join QR',
              onDetect: _busy ? (_) {} : _onQrScanned,
            ),
            if (hasPending) ...[
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : _confirmPending,
                  icon: const Icon(Icons.link_outlined),
                  label: const Text('Confirm join link on this device'),
                ),
              ),
            ],
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
                      'Point your camera at the organizer’s QR code, or open their join link on this device and tap Confirm.',
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
