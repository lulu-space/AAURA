import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Quick celebratory burst used on enroll/purchase/badge unlock.
/// Stateless overlay that auto-dismisses via [showSuccessBurst].
class _BurstWidget extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onDone;
  final Color color;
  const _BurstWidget({
    required this.icon,
    required this.label,
    required this.onDone,
    required this.color,
  });

  @override
  State<_BurstWidget> createState() => _BurstWidgetState();
}

class _BurstWidgetState extends State<_BurstWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  @override
  void initState() {
    super.initState();
    _ctrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onDone();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            final t = _ctrl.value;
            return Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: (1.0 - t).clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: 0.6 + 0.6 * t,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.color.withValues(alpha: 0.18),
                      ),
                    ),
                  ),
                ),
                ...List.generate(8, (i) {
                  final angle = (i / 8) * 2 * pi;
                  final dx = cos(angle) * 80 * t;
                  final dy = sin(angle) * 80 * t;
                  return Transform.translate(
                    offset: Offset(dx, dy),
                    child: Opacity(
                      opacity: (1.0 - t).clamp(0.0, 1.0),
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.color,
                        ),
                      ),
                    ),
                  );
                }),
                Transform.scale(
                  scale: 0.4 + (t < 0.6 ? t * 1.4 : 1 - (t - 0.6) * 0.5),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.color,
                      boxShadow: [
                        BoxShadow(
                          color: widget.color.withValues(alpha: 0.35),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(widget.icon, color: Colors.white, size: 36),
                  ),
                ),
                Positioned(
                  bottom: 120,
                  child: Opacity(
                    opacity: (1.0 - (t - 0.4).clamp(0.0, 1.0)).clamp(0.0, 1.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                      ),
                      child: Text(
                        widget.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

void showSuccessBurst(
  BuildContext context, {
  required String label,
  IconData icon = Icons.check_rounded,
  Color color = AppColors.primary,
}) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _BurstWidget(
      icon: icon,
      label: label,
      color: color,
      onDone: () => entry.remove(),
    ),
  );
  overlay.insert(entry);
}
