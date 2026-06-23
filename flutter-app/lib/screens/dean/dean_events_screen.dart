import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/event.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/transitions.dart';
import '../../widgets/event_card.dart';
import '../../widgets/stat_chip.dart';
import '../events/create_event_screen.dart';
import '../events/event_details_screen.dart';

class DeanEventsScreen extends StatefulWidget {
  const DeanEventsScreen({super.key});

  @override
  State<DeanEventsScreen> createState() => _DeanEventsScreenState();
}

class _DeanEventsScreenState extends State<DeanEventsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppState>().refreshDeanData();
    });
  }

  void _createEvent() {
    Navigator.of(context).push(
      FadeSlidePageRoute(builder: (_) => const CreateEventScreen()),
    );
  }

  void _editEvent(Event event) {
    Navigator.of(context).push(
      FadeSlidePageRoute(
        builder: (_) => CreateEventScreen(editEvent: event),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final events = state.deanFacultyEvents;
    final pending = events
        .where((e) => !e.isApproved && e.status != 'cancelled')
        .length;
    final published = events.where((e) => e.status == 'published').length;
    final canPop = Navigator.canPop(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Faculty Events'),
        leading: canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : null,
        actions: const [],
      ),
      floatingActionButton: state.deanHasFaculty
          ? FloatingActionButton.extended(
              onPressed: _createEvent,
              icon: const Icon(Icons.add),
              label: const Text('Create event'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () => context.read<AppState>().refreshDeanData(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            96,
          ),
          children: [
            if (!state.deanHasFaculty)
              const _InfoBanner(
                message:
                    'Select your faculty on the Dashboard tab to load and create faculty events.',
              )
            else ...[
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  StatChip(
                    icon: Icons.event,
                    label: '$published published',
                    background: AppColors.primary.withValues(alpha: 0.14),
                    foreground: AppColors.primary,
                  ),
                  StatChip(
                    icon: Icons.pending_actions,
                    label: '$pending pending review',
                    background: AppColors.warning.withValues(alpha: 0.14),
                    foreground: AppColors.warning,
                  ),
                  StatChip(
                    icon: Icons.event_available,
                    label: '${events.length} total',
                    background: AppColors.accent.withValues(alpha: 0.14),
                    foreground: AppColors.accent,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              if (events.isEmpty)
                Text(
                  'No faculty events yet. Tap Create event to add one for your faculty.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                )
              else
                for (final event in events)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: EventCard(
                            event: event,
                            joined: false,
                            onView: () => Navigator.of(context).push(
                              FadeSlidePageRoute(
                                builder: (_) => EventDetailsScreen(event: event),
                              ),
                            ),
                          ),
                        ),
                        if (state.isEventOrganizer(event.id))
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert),
                            onSelected: (value) {
                              if (value == 'edit') _editEvent(event);
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'edit',
                                child: Text('Edit event'),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final String message;
  const _InfoBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}
