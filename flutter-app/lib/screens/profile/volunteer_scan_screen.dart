import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/campus_qr_scan_panel.dart';
import '../../widgets/success_burst.dart';

/// Scan a volunteer QR code or open a join link from Student Affairs / dean.
class VolunteerScanScreen extends StatefulWidget {
  final String? initialJoinToken;

  const VolunteerScanScreen({super.key, this.initialJoinToken});

  @override
  State<VolunteerScanScreen> createState() => _VolunteerScanScreenState();
}

class _VolunteerScanScreenState extends State<VolunteerScanScreen> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final token = widget.initialJoinToken?.trim();
    if (token != null && token.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<AppState>().setPendingVolunteerJoinToken(token);
      });
    }
  }

  Future<void> _apply(String input) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final error = await context
          .read<AppState>()
          .applyToVolunteerOpportunityByToken(input);
      if (!mounted) return;
      if (error != null) {
        _snack(error);
        return;
      }
      showSuccessBurst(context, label: 'Application sent for approval!');
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _onQrScanned(String raw) {
    _apply(raw);
  }

  Future<void> _confirmPending() async {
    final token = context.read<AppState>().pendingVolunteerJoinToken;
    if (token == null || token.isEmpty) {
      _snack('Scan the volunteer join QR from Student Affairs or your dean.');
      return;
    }
    await _apply(token);
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final hasPending =
        context.watch<AppState>().pendingVolunteerJoinToken != null;
    return Scaffold(
      appBar: AppBar(title: const Text('Volunteer QR')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            CampusQrScanPanel(
              accent: AppColors.success,
              hint: 'Scan volunteer join QR',
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
                      'Point your camera at the volunteer QR code, or open the join link on this device and tap Confirm.',
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
