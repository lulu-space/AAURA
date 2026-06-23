import 'package:flutter/material.dart';

import '../models/event.dart';
import '../theme/app_theme.dart';

class EventCard extends StatefulWidget {
  final Event event;
  final VoidCallback? onView;
  final bool joined;
  final bool dense;
  final bool favorite;
  final VoidCallback? onFavorite;

  const EventCard({
    super.key,
    required this.event,
    this.onView,
    this.joined = false,
    this.dense = false,
    this.favorite = false,
    this.onFavorite,
  });

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  bool _down = false;

  Color get _accent {
    switch (widget.event.category) {
      case EventCategory.learn:
        return AppColors.primary;
      case EventCategory.serve:
        return AppColors.success;
      case EventCategory.connect:
        return AppColors.magenta;
      case EventCategory.explore:
        return AppColors.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dense = widget.dense;
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onView,
      child: AnimatedScale(
        scale: _down ? 0.98 : 1,
        duration: const Duration(milliseconds: 120),
        child: Container(
          decoration: cardDecoration(),
          child: Row(
            children: [
              Container(
                width: 6,
                height: dense ? 84 : 100,
                decoration: BoxDecoration(
                  color: _accent,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppRadii.lg),
                    bottomLeft: Radius.circular(AppRadii.lg),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Container(
                  width: dense ? 56 : 64,
                  height: dense ? 56 : 64,
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  child: Icon(widget.event.category.icon,
                      color: _accent, size: dense ? 26 : 30),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _accent.withValues(alpha: 0.12),
                              borderRadius:
                                  BorderRadius.circular(AppRadii.pill),
                            ),
                            child: Text(
                              widget.event.category.label,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: _accent,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                          if (widget.event.category == EventCategory.serve &&
                              widget.event.volunteerHours > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.12),
                                borderRadius:
                                    BorderRadius.circular(AppRadii.pill),
                              ),
                              child: Text(
                                '+${widget.event.volunteerHours % 1 == 0 ? widget.event.volunteerHours.toInt() : widget.event.volunteerHours.toStringAsFixed(1)} volunteer h',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                          ],
                          const SizedBox(width: 6),
                          Text(
                            '+${widget.event.points} pts',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.event.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.event.organizer} · ${widget.event.date}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.sm, AppSpacing.md, AppSpacing.md, AppSpacing.md),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.onFavorite != null)
                      InkWell(
                        borderRadius:
                            BorderRadius.circular(AppRadii.pill),
                        onTap: widget.onFavorite,
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            widget.favorite
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: widget.favorite
                                ? AppColors.warning
                                : AppColors.textMuted,
                            size: 20,
                          ),
                        ),
                      ),
                    const SizedBox(height: 4),
                    ElevatedButton(
                      onPressed: widget.onView,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        backgroundColor:
                            widget.joined ? AppColors.accent : AppColors.primary,
                        textStyle: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      child: Text(widget.joined ? 'Joined' : 'View'),
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
