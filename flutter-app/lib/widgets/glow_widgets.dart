import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A dreamy circular progress ring with a soft coloured glow halo and a
/// centered percentage — the "milestone" look from the Daily Journal inspo.
class GlowRing extends StatelessWidget {
  final double progress;
  final double size;
  final double strokeWidth;
  final Color color;
  final String? centerLabel;

  const GlowRing({
    super.key,
    required this.progress,
    this.size = 72,
    this.strokeWidth = 7,
    this.color = AppColors.primary,
    this.centerLabel,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (progress.clamp(0.0, 1.0) * 100).round();
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Soft outer glow halo.
          Container(
            width: size * 0.84,
            height: size * 0.84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: glow(color,
                  alpha: 0.45, blurRadius: size * 0.32, spreadRadius: 1),
            ),
          ),
          CustomPaint(
            size: Size.square(size),
            painter: _GlowRingPainter(
              progress: progress.clamp(0.0, 1.0),
              strokeWidth: strokeWidth,
              color: color,
            ),
          ),
          Text(
            centerLabel ?? '$pct%',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: size * 0.24,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowRingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color color;

  _GlowRingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = AppColors.surfaceMuted;
    canvas.drawCircle(center, radius, track);

    final sweep = 2 * math.pi * progress;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: -math.pi / 2 + 2 * math.pi,
        colors: [
          Color.lerp(color, Colors.white, 0.45)!,
          color,
          Color.lerp(color, AppColors.magenta, 0.4)!,
        ],
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(rect);
    canvas.drawArc(rect, -math.pi / 2, sweep, false, arc);
  }

  @override
  bool shouldRepaint(covariant _GlowRingPainter old) =>
      old.progress != progress ||
      old.strokeWidth != strokeWidth ||
      old.color != color;
}

/// Small circular icon with a soft brand-coloured halo (the inspo glow).
class GlowIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const GlowIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          onTap: onTap,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
              border:
                  Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
              boxShadow: glow(AppColors.primary,
                  alpha: 0.22, blurRadius: 16, offset: const Offset(0, 6)),
            ),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}

/// Rounded pill search field with a glowing circular search button.
class GlowSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final String hintText;

  const GlowSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
    this.hintText = 'Search...',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 6, 6, 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: AppColors.divider),
        boxShadow: glow(AppColors.primary,
            alpha: 0.10, blurRadius: 16, offset: const Offset(0, 6)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              style: Theme.of(context).textTheme.bodyMedium,
              decoration: InputDecoration(
                isDense: true,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintText: hintText,
                hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            InkWell(
              borderRadius: BorderRadius.circular(AppRadii.pill),
              onTap: onClear,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(Icons.close_rounded,
                    size: 18, color: AppColors.textMuted),
              ),
            ),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppGradients.header,
              boxShadow: glow(AppColors.primary,
                  alpha: 0.35, blurRadius: 16, offset: const Offset(0, 6)),
            ),
            child:
                const Icon(Icons.search_rounded, color: Colors.white, size: 22),
          ),
        ],
      ),
    );
  }
}
