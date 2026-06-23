import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Reusable rounded gradient panel with a soft accent blob.
/// Used as the hero card on Home, Profile, Shop, Academics etc.
class GradientHero extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Gradient? gradient;
  final bool showBlob;

  const GradientHero({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.radius = AppRadii.xl,
    this.gradient,
    this.showBlob = true,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: gradient ?? AppGradients.header,
                ),
              ),
            ),
            if (showBlob)
              Positioned(
                right: -40,
                top: -30,
                child: _Blob(
                    size: 160,
                    color: Colors.white.withValues(alpha: 0.10)),
              ),
            if (showBlob)
              Positioned(
                left: -30,
                bottom: -50,
                child: _Blob(
                    size: 130,
                    color: Colors.white.withValues(alpha: 0.07)),
              ),
            Padding(
              padding: padding,
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  final double size;
  final Color color;
  const _Blob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
