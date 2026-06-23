import 'package:flutter/material.dart';

import '../models/event.dart';
import '../theme/app_theme.dart';
import 'bird_avatar.dart';

/// Mascot poses (row, col) on the 3x6 sticker sheet, cycled so each card shows
/// a slightly different Shams. Mirrors the home screen's `_trendPoses`.
const List<List<int>> _mascotPoses = [
  [0, 2],
  [2, 2],
  [4, 0],
  [1, 2],
  [3, 0],
  [2, 1],
  [5, 1],
  [4, 2],
];

List<int> _poseFor(int seed) => _mascotPoses[seed % _mascotPoses.length];

/// A soft glassy pill used for points / meta chips on the gradient cards.
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

/// A small frosted circular star toggle for the gradient cards.
class _FavoriteBubble extends StatelessWidget {
  final bool favorite;
  final VoidCallback? onTap;
  const _FavoriteBubble({required this.favorite, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.pill),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
          ),
          child: Icon(
            favorite ? Icons.star_rounded : Icons.star_border_rounded,
            size: 18,
            color: favorite ? AppColors.warning : Colors.white,
          ),
        ),
      ),
    );
  }
}

/// Large, dreamy feature card (the inspo "Cappadocia" hot-air-balloon card,
/// but with our mascot peeking from the top-right corner).
class EventFeatureCard extends StatelessWidget {
  final Event event;
  final bool joined;
  final bool favorite;
  final VoidCallback? onView;
  final VoidCallback? onFavorite;
  final int seed;

  const EventFeatureCard({
    super.key,
    required this.event,
    this.joined = false,
    this.favorite = false,
    this.onView,
    this.onFavorite,
    this.seed = 0,
  });

  @override
  Widget build(BuildContext context) {
    final pose = _poseFor(seed);
    return GestureDetector(
      onTap: onView,
      child: Container(
        height: 232,
        decoration: BoxDecoration(
          gradient: AppGradients.category(event.category),
          borderRadius: BorderRadius.circular(AppRadii.xl),
          boxShadow: glow(
            AppCategoryStyle.accent(event.category),
            alpha: 0.35,
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.xl),
          child: Stack(
            children: [
              Positioned(
                right: -26,
                top: -22,
                child: _Blob(size: 150, alpha: 0.14),
              ),
              Positioned(
                left: -30,
                bottom: -40,
                child: _Blob(size: 130, alpha: 0.10),
              ),
              // Mascot peeking from the top-right.
              Positioned(
                right: 6,
                top: 2,
                child: BirdSticker(size: 104, row: pose[0], col: pose[1]),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _GlassChip(
                          icon: Icons.auto_awesome,
                          label: '+${event.points} pts',
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _GlassChip(
                          icon: event.category.icon,
                          label: event.category.label,
                        ),
                        const Spacer(),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: playfulDisplay(
                        size: 24,
                        weight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      event.about,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: ElevatedButton.icon(
                              onPressed: onView,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor:
                                    AppCategoryStyle.accent(event.category),
                                elevation: 0,
                                padding: EdgeInsets.zero,
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              icon: Icon(
                                joined
                                    ? Icons.check_circle
                                    : Icons.arrow_forward_rounded,
                                size: 18,
                              ),
                              label: Text(joined ? 'Joined' : 'View Details'),
                            ),
                          ),
                        ),
                        if (onFavorite != null) ...[
                          const SizedBox(width: AppSpacing.sm),
                          _FavoriteBubble(favorite: favorite, onTap: onFavorite),
                        ],
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

/// Compact gradient tile used in the 2-column Discover grid.
class EventGlowCard extends StatelessWidget {
  final Event event;
  final bool joined;
  final bool favorite;
  final VoidCallback? onView;
  final VoidCallback? onFavorite;
  final int seed;

  const EventGlowCard({
    super.key,
    required this.event,
    this.joined = false,
    this.favorite = false,
    this.onView,
    this.onFavorite,
    this.seed = 0,
  });

  @override
  Widget build(BuildContext context) {
    final pose = _poseFor(seed);
    return GestureDetector(
      onTap: onView,
      child: Container(
        decoration: BoxDecoration(
          gradient: AppGradients.category(event.category),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          boxShadow: glow(
            AppCategoryStyle.accent(event.category),
            alpha: 0.28,
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          child: Stack(
            children: [
              Positioned(
                right: -18,
                bottom: -22,
                child: _Blob(size: 96, alpha: 0.12),
              ),
              Positioned(
                right: -8,
                top: -6,
                child: BirdSticker(size: 64, row: pose[0], col: pose[1]),
              ),
              Positioned(
                left: 8,
                top: 8,
                child: _GlassChip(
                  icon: event.category.icon,
                  label: event.category.label,
                ),
              ),
              if (onFavorite != null)
                Positioned(
                  right: 6,
                  bottom: 6,
                  child: _FavoriteBubble(
                    favorite: favorite,
                    onTap: onFavorite,
                  ),
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
                      event.title,
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
                        Icon(
                          joined
                              ? Icons.check_circle
                              : Icons.auto_awesome,
                          size: 13,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            joined ? 'Joined' : '+${event.points} pts',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w700,
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

/// Soft, airy rounded tile for the Starred tab (the gentle screenshot-3 list).
/// Alternates the badge side by [index] for a cooler rhythm.
class StarredEventTile extends StatelessWidget {
  final Event event;
  final int index;
  final VoidCallback? onView;
  final VoidCallback? onUnstar;

  const StarredEventTile({
    super.key,
    required this.event,
    this.index = 0,
    this.onView,
    this.onUnstar,
  });

  @override
  Widget build(BuildContext context) {
    final accent = AppCategoryStyle.accent(event.category);
    final badge = _Badge(
      label: '+${event.points}',
      sub: 'pts',
      accent: accent,
    );
    final body = Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            event.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: playfulDisplay(
              size: 16,
              weight: FontWeight.w700,
              color: AppCategoryStyle.accent(event.category),
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${event.category.label} · ${event.date}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );

    final badgeLeft = index.isOdd;
    return GestureDetector(
      onTap: onView,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppCategoryStyle.softTint(event.category),
          borderRadius: BorderRadius.circular(AppRadii.xl),
          border: Border.all(color: accent.withValues(alpha: 0.18)),
          boxShadow: glow(accent, alpha: 0.12, blurRadius: 16),
        ),
        child: Row(
          children: [
            if (badgeLeft) ...[badge, const SizedBox(width: AppSpacing.md)],
            body,
            const SizedBox(width: AppSpacing.md),
            if (!badgeLeft) badge,
            const SizedBox(width: AppSpacing.sm),
            InkWell(
              borderRadius: BorderRadius.circular(AppRadii.pill),
              onTap: onUnstar,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.star_rounded,
                    color: AppColors.warning, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final String sub;
  final Color accent;
  const _Badge({required this.label, required this.sub, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        boxShadow: glow(accent, alpha: 0.30, blurRadius: 14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
              height: 1.0,
            ),
          ),
          Text(
            sub,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

/// Soft translucent decorative blob behind the gradient cards.
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
