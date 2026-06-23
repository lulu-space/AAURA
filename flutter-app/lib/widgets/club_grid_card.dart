import 'package:flutter/material.dart';

import '../models/club.dart';
import '../theme/app_theme.dart';
import 'bird_avatar.dart';

// Varied mascot poses across the 3x6 sticker sheet so each card shows a
// slightly different Shams.
const List<List<int>> _mascotPoses = [
  [0, 0],
  [0, 1],
  [1, 0],
  [2, 2],
  [3, 0],
  [4, 1],
  [5, 0],
  [1, 2],
];

List<int> _poseFor(int seed) => _mascotPoses[seed % _mascotPoses.length];

/// Compact gradient tile for the clubs grid, with the Shams mascot peeking from
/// the top-right and a soft category chip.
class ClubGridCard extends StatelessWidget {
  final Club club;
  final bool joined;
  final VoidCallback? onTap;
  final int seed;

  const ClubGridCard({
    super.key,
    required this.club,
    this.joined = false,
    this.onTap,
    this.seed = 0,
  });

  @override
  Widget build(BuildContext context) {
    final accent = ClubCategoryStyle.accent(club.category);
    final pose = _poseFor(seed);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: AppGradients.clubCategory(club.category),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          boxShadow: glow(accent,
              alpha: 0.28, blurRadius: 18, offset: const Offset(0, 10)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          child: Stack(
            children: [
              Positioned(
                left: -18,
                bottom: -22,
                child: _Blob(size: 92, alpha: 0.10),
              ),
              Positioned(
                right: -8,
                top: -6,
                child: BirdSticker(size: 66, row: pose[0], col: pose[1]),
              ),
              Positioned(
                left: 8,
                top: 8,
                child: _GlassChip(
                  icon: club.category.icon,
                  label: club.category.label,
                ),
              ),
              if (joined)
                const Positioned(
                  right: 8,
                  bottom: 8,
                  child: _JoinedBadge(),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, 44, AppSpacing.md, AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Spacer(),
                    Text(
                      club.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: playfulDisplay(
                        size: 16,
                        weight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.groups_outlined,
                            size: 13,
                            color: Colors.white.withValues(alpha: 0.9)),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '${club.members} - ${club.activityLevel.label}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _GlassChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _JoinedBadge extends StatelessWidget {
  const _JoinedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 13, color: Colors.white),
          SizedBox(width: 4),
          Text(
            'Joined',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  final double size;
  final double alpha;
  const _Blob({required this.size, required this.alpha});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: alpha),
      ),
    );
  }
}
