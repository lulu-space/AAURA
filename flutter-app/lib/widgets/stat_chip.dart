import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Glassy stat chip used inside hero cards (points, hours, streak).
class StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;
  final bool dense;

  const StatChip({
    super.key,
    required this.icon,
    required this.label,
    this.background = const Color(0x33FFFFFF),
    this.foreground = Colors.white,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: EdgeInsets.symmetric(
          horizontal: dense ? 10 : 12, vertical: dense ? 4 : 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: foreground, size: dense ? 14 : 16),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
