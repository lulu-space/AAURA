import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../models/event.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/transitions.dart';
import '../../widgets/event_visual_cards.dart';
import '../../widgets/glow_widgets.dart';
import 'create_event_screen.dart';
import 'enroll_event_scan_screen.dart';
import 'event_details_screen.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  EventCategory _selected = EventCategory.learn;
  int _tab = 0; // 0 = Discover, 1 = Starred
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final launchToken = context.read<AppState>().pendingEventJoinToken;
      if (launchToken != null) {
        Navigator.of(context).push(
          FadeSlidePageRoute(
            builder: (_) => EnrollEventScanScreen(initialJoinToken: launchToken),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _matchesQuery(Event e) {
    if (_query.trim().isEmpty) return true;
    final q = _query.toLowerCase();
    return e.title.toLowerCase().contains(q) ||
        e.organizer.toLowerCase().contains(q) ||
        e.location.toLowerCase().contains(q) ||
        e.category.label.toLowerCase().contains(q) ||
        e.tags.any((t) => t.toLowerCase().contains(q));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    final discover = state.allEvents
        .where((e) => e.category == _selected && _matchesQuery(e))
        .toList();
    final starred = state.allEvents
        .where((e) => state.isEventFavorite(e.id) && _matchesQuery(e))
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppGradients.campusPage),
        child: SafeArea(
          bottom: false,
          child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxl),
          children: [
            if (state.isStudentAffairs) ...[
              const _Header(),
              const SizedBox(height: AppSpacing.lg),
            ],
            GlowSearchBar(
              controller: _searchCtrl,
              hintText: 'Search for events...',
              onChanged: (v) => setState(() => _query = v),
              onClear: () {
                _searchCtrl.clear();
                setState(() => _query = '');
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            _SegmentToggle(
              index: _tab,
              starredCount: state.allEvents
                  .where((e) => state.isEventFavorite(e.id))
                  .length,
              onChanged: (i) => setState(() => _tab = i),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_tab == 0)
              ..._discoverBody(state, discover)
            else
              ..._starredBody(state, starred),
          ],
        ),
        ),
      ),
    );
  }

  List<Widget> _discoverBody(AppState state, List<Event> events) {
    final counts = <EventCategory, int>{
      for (final c in EventCategory.values)
        c: state.allEvents.where((e) => e.category == c).length,
    };

    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final cat in EventCategory.values)
            _CategoryGlowPill(
              category: cat,
              count: counts[cat] ?? 0,
              selected: _selected == cat,
              onTap: () => setState(() => _selected = cat),
            ),
        ],
      ),
      const SizedBox(height: AppSpacing.lg),
      if (events.isEmpty)
        _empty(
          _query.isNotEmpty
              ? 'No events match "$_query" in ${_selected.label}.'
              : 'No events yet in ${_selected.label}.\nCheck other categories!',
        )
      else
        for (int i = 0; i < events.length; i++) ...[
          EventFeatureCard(
            event: events[i],
            seed: i,
            joined: state.isEventJoined(events[i].id),
            favorite: state.isEventFavorite(events[i].id),
            onFavorite: state.isStaffOrAffairs
                ? null
                : () =>
                    context.read<AppState>().toggleFavoriteEvent(events[i].id),
            onView: () => _openEvent(events[i]),
          )
              .animate()
              .fadeIn(delay: (70 * i).ms, duration: 320.ms)
              .slideY(begin: 0.06, end: 0),
          if (i != events.length - 1) const SizedBox(height: AppSpacing.lg),
        ],
    ];
  }

  List<Widget> _starredBody(AppState state, List<Event> events) {
    if (events.isEmpty) {
      return [
        _empty(
          _query.isNotEmpty
              ? 'No starred events match "$_query".'
              : 'No starred events yet.\nTap the star on any event to keep it here.',
        ),
      ];
    }
    return [
      for (int i = 0; i < events.length; i++) ...[
        StarredEventTile(
          event: events[i],
          index: i,
          onView: () => _openEvent(events[i]),
          onUnstar: () =>
              context.read<AppState>().toggleFavoriteEvent(events[i].id),
        )
            .animate()
            .fadeIn(delay: (50 * i).ms, duration: 280.ms)
            .slideX(begin: i.isOdd ? 0.06 : -0.06, end: 0),
        if (i != events.length - 1) const SizedBox(height: AppSpacing.md),
      ],
    ];
  }

  void _openEvent(Event e) {
    Navigator.of(context).push(
      FadeSlidePageRoute(builder: (_) => EventDetailsScreen(event: e)),
    );
  }

  Widget _empty(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        GlowIconButton(
          icon: Icons.add_rounded,
          tooltip: 'Create event',
          onTap: () => Navigator.of(context).push(
            FadeSlidePageRoute(builder: (_) => const CreateEventScreen()),
          ),
        ),
      ],
    );
  }
}

/// Discover | Starred segmented toggle with a star + count on the right tab.
class _SegmentToggle extends StatelessWidget {
  final int index;
  final int starredCount;
  final ValueChanged<int> onChanged;
  const _SegmentToggle({
    required this.index,
    required this.starredCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        children: [
          _segment(context, 0, Icons.explore_outlined, 'Discover'),
          _segment(
            context,
            1,
            Icons.star_rounded,
            starredCount > 0 ? 'Starred ($starredCount)' : 'Starred',
          ),
        ],
      ),
    );
  }

  Widget _segment(
      BuildContext context, int i, IconData icon, String label) {
    final selected = index == i;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(i),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            boxShadow: selected
                ? glow(AppColors.primary, alpha: 0.30, blurRadius: 14)
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16,
                  color: selected ? Colors.white : AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color:
                          selected ? Colors.white : AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Category selector: a glowing rounded-square icon, label and count — the
/// lit-up pill cluster from the inspo.
class _CategoryGlowPill extends StatelessWidget {
  final EventCategory category;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryGlowPill({
    required this.category,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = AppCategoryStyle.accent(category);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                gradient: selected ? AppGradients.category(category) : null,
                color: selected ? null : AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadii.lg),
                border: Border.all(
                  color: selected
                      ? Colors.transparent
                      : AppColors.divider,
                ),
                boxShadow:
                    selected ? glow(accent, alpha: 0.45, blurRadius: 18) : null,
              ),
              child: Icon(
                category.icon,
                size: 24,
                color: selected ? Colors.white : accent,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              category.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: selected ? accent : AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            Text(
              '$count',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
