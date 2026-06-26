import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../theme/app_theme.dart';

/// Live camera QR scanner with a campus-style overlay frame.
class CampusQrScanPanel extends StatefulWidget {
  const CampusQrScanPanel({
    super.key,
    required this.onDetect,
    this.hint = 'Point your camera at the QR code',
    this.accent = AppColors.accent,
    this.height = 280,
  });

  final ValueChanged<String> onDetect;
  final String hint;
  final Color accent;
  final double height;

  @override
  State<CampusQrScanPanel> createState() => _CampusQrScanPanelState();
}

class _CampusQrScanPanelState extends State<CampusQrScanPanel> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );

  String? _error;
  bool _cooldown = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDetect(BarcodeCapture capture) {
    if (_cooldown) return;
    String? raw;
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue?.trim();
      if (value != null && value.isNotEmpty) {
        raw = value;
        break;
      }
    }
    if (raw == null) return;

    _cooldown = true;
    widget.onDetect(raw);
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _cooldown = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: SizedBox(
        height: widget.height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_error != null)
              ColoredBox(
                color: Colors.black,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.white70),
                    ),
                  ),
                ),
              )
            else
              MobileScanner(
                controller: _controller,
                onDetect: _handleDetect,
                errorBuilder: (context, error) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    setState(() {
                      _error = kIsWeb
                          ? 'Allow camera access in your browser to scan QR codes.'
                          : 'Camera unavailable. Check permissions and try again.';
                    });
                  });
                  return const SizedBox.shrink();
                },
              ),
            ..._cornerOverlay(widget.accent),
            Positioned(
              bottom: 14,
              left: 16,
              right: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: Text(
                  widget.hint,
                  textAlign: TextAlign.center,
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
    );
  }

  List<Widget> _cornerOverlay(Color accent) {
    const padding = 36.0;
    const corner = SizedBox(width: 28, height: 28);
    final side = BorderSide(color: accent.withValues(alpha: 0.9), width: 3);

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
