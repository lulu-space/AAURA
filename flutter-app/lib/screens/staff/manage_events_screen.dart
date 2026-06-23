import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../models/event.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/transitions.dart';
import '../../widgets/bird_avatar.dart';
import '../../widgets/dawn_scene.dart';
import '../../widgets/glow_widgets.dart';
import '../../widgets/stat_chip.dart';
import '../events/create_event_screen.dart';
import '../events/event_details_screen.dart';

const List<Color> _eventTints = [
  Color(0xFF5EC4D4),
  Color(0xFFE8920F),
  Color(0xFF9BCB4A),
  Color(0xFF2BB8C8),
];

const List<List<int>> _eventPoses = [
  [0, 2],
  [2, 2],
  [4, 0],
  [1, 2],
  [3, 0],
  [2, 1],
];

class ManageEventsScreen extends StatelessWidget {
  const ManageEventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final events = state.publishedEvents;
    final name = (state.profile?.name ?? 'Student Affairs').split(' ').first;

    final totalExpected = events.fold<int>(0, (sum, event) {
      final score = event.aiSuccessScore;
      if (score != null && score > 0) {
        return sum + (event.capacity * score / 100).round();
      }
      return sum + (event.capacity ~/ 2);
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppGradients.campusPage),
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxl),
            children: [
              if (Navigator.canPop(context)) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: GlowIconButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: 'Back',
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              _Hero(
                name: name,
                published: events.length,
                expected: totalExpected,
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Your Events',
                      style: playfulDisplay(
                        size: 18,
                        weight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  GlowIconButton(
                    icon: Icons.add_rounded,
                    tooltip: 'Create event',
                    onTap: () => Navigator.of(context).push(
                      FadeSlidePageRoute(
                        builder: (_) => const CreateEventScreen(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              if (events.isEmpty)
                _EmptyState()
              else
                _EventStrip(events: events),
            ],
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final String name;
  final int published;
  final int expected;
  const _Hero({
    required this.name,
    required this.published,
    required this.expected,
  });

  @override
  Widget build(BuildContext context) {
    final scrimColor = AppPalette.dawnLow;
    return SizedBox(
      height: 176,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.xl),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const DawnScene(reveal: 1.0),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    scrimColor.withValues(alpha: 0.0),
                    scrimColor.withValues(alpha: 0.66),
                  ],
                ),
              ),
            ),
            Positioned(
              right: -4,
              bottom: -6,
              child: IgnorePointer(
                child: const BirdSticker(row: 2, col: 2, size: 104)
                    .animate()
                    .fadeIn(delay: 250.ms, duration: 500.ms)
                    .slideX(begin: 0.3, end: 0, curve: Curves.easeOut),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hi, $name',
                    style: playfulDisplay(
                      size: 28,
                      weight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.0,
                    ).copyWith(
                      shadows: [
                        Shadow(
                          color: scrimColor.withValues(alpha: 0.8),
                          blurRadius: 14,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      StatChip(
                        icon: Icons.event_available,
                        label: '$published published',
                      ),
                      StatChip(
                        icon: Icons.groups_2_outlined,
                        label: '$expected expected',
                      ),
                    ],
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

class _EventStrip extends StatelessWidget {
  final List<Event> events;
  const _EventStrip({required this.events});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 224,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: events.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (_, i) {
          final e = events[i];
          final tint = _eventTints[i % _eventTints.length];
          final pose = _eventPoses[i % _eventPoses.length];
          return _EventCard(
            event: e,
            tint: tint,
            poseRow: pose[0],
            poseCol: pose[1],
            onTap: () => Navigator.of(context).push(
              FadeSlidePageRoute(
                builder: (_) => EventDetailsScreen(event: e),
              ),
            ),
            onEdit: () => Navigator.of(context).push(
              FadeSlidePageRoute(
                builder: (_) => CreateEventScreen(editEvent: e),
              ),
            ),
            onDelete: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete event?'),
                  content: Text(
                    'Remove "${e.title}"? This cannot be undone.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (confirmed != true || !context.mounted) return;
              final ok = await context.read<AppState>().deleteEvent(e.id);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    ok ? 'Event deleted' : 'Could not delete event',
                  ),
                ),
              );
            },
          )
              .animate()
              .fadeIn(delay: (60 * i).ms, duration: 350.ms)
              .slideX(begin: 0.12, end: 0);
        },
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final Event event;
  final Color tint;
  final int poseRow;
  final int poseCol;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EventCard({
    required this.event,
    required this.tint,
    required this.poseRow,
    required this.poseCol,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: () {
        showModalBottomSheet<void>(
          context: context,
          builder: (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('Edit event'),
                  onTap: () {
                    Navigator.pop(ctx);
                    onEdit();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('Delete event'),
                  onTap: () {
                    Navigator.pop(ctx);
                    onDelete();
                  },
                ),
              ],
            ),
          ),
        );
      },
      child: Container(
        width: 210,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [tint, Color.lerp(tint, AppPalette.ink, 0.18)!],
          ),
          borderRadius: BorderRadius.circular(AppRadii.xl),
          boxShadow: [
            BoxShadow(
              color: AppPalette.ink.withValues(alpha: 0.18),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.xl),
          child: Stack(
            children: [
              Positioned(
                right: -16,
                bottom: -10,
                child: IgnorePointer(
                  child: BirdSticker(row: poseRow, col: poseCol, size: 92),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _GlassChip(
                      icon: event.category.icon,
                      label: event.category.label,
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: 150,
                      child: Text(
                        event.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppPalette.ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 140,
                      child: Text(
                        event.date,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppPalette.ink.withValues(alpha: 0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    _ManageButton(onTap: onEdit),
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
        color: Colors.white.withValues(alpha: 0.30),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppPalette.ink),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: AppPalette.ink,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ManageButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ManageButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppPalette.ink,
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.pill),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.tune_rounded, size: 15, color: AppPalette.cream),
              const SizedBox(width: 6),
              Text(
                'Manage',
                style: TextStyle(
                  color: AppPalette.cream,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: cardDecoration(),
      child: Row(
        children: [
          const BirdSticker(row: 1, col: 1, size: 64),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'No events published yet. Tap the + above to draft and publish your first event.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
