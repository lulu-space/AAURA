import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/join_links.dart';
import '../../data/repositories/_repo_support.dart';
import '../../models/event.dart';
import '../../models/event_prediction.dart';
import '../../services/event_prediction_service.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bird_avatar.dart';
import '../../widgets/campus_people_list.dart';
import '../profile/volunteer_scan_screen.dart';
import 'enroll_event_scan_screen.dart';
import '../../utils/transitions.dart';
import '../../widgets/join_link_qr_card.dart';

class EventDetailsScreen extends StatefulWidget {
  final Event event;
  const EventDetailsScreen({super.key, required this.event});

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = context.read<AppState>();
      if (widget.event.category == EventCategory.serve) {
        state.refreshVolunteerOpportunities();
      }
      final launchToken = state.pendingEventJoinToken;
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
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final joined = state.isEventJoined(widget.event.id);
    final accent = AppCategoryStyle.accent(widget.event.category);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _Header(event: widget.event),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
              child: _TabBar(
                tabs: [
                  'Overview',
                  'Details',
                  'Rewards (${widget.event.rewards.length})',
                ],
                index: _tab,
                accent: accent,
                onChanged: (i) => setState(() => _tab = i),
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: _bodyForTab(),
              ),
            ),
            if (state.isStudent)
              SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Builder(
                  builder: (context) {
                    final event =
                        state.eventById(widget.event.id) ?? widget.event;
                    final canEnroll =
                        event.status == 'published' && event.isApproved;
                    if (!canEnroll && !joined) {
                      return Text(
                        event.status != 'published'
                            ? 'This event is not open for enrollment yet.'
                            : 'This event is pending approval and cannot be joined yet.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppColors.textSecondary),
                      );
                    }
                    return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (event.category == EventCategory.serve &&
                        event.volunteerHours > 0) ...[
                      _VolunteerHoursBanner(
                        hours: event.volunteerHours,
                        eventId: event.id,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    if (joined) ...[
                      _EventFeedbackSection(eventId: widget.event.id),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: joined
                          ? ElevatedButton(
                              onPressed: () async {
                                final error = await context
                                    .read<AppState>()
                                    .toggleEventJoinResult(widget.event.id);
                                if (!context.mounted) return;
                                if (error != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(error)),
                                  );
                                  return;
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Removed from your events'),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    accent.withValues(alpha: 0.45),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text('Cancel Enrollment'),
                            )
                          : ElevatedButton.icon(
                              onPressed: () {
                                final event = state.eventById(widget.event.id) ??
                                    widget.event;
                                Navigator.of(context).push(
                                  FadeSlidePageRoute(
                                    builder: (_) => EnrollEventScanScreen(
                                      initialJoinToken: event.joinToken,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.qr_code_scanner_outlined),
                              label: const Text('Scan QR to join'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accent,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                    ),
                    if (!joined) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Open the join link from your dean or Student Affairs, then scan the QR code to enroll.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ],
                );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bodyForTab() {
    final accent = AppCategoryStyle.accent(widget.event.category);
    switch (_tab) {
      case 0:
        return _Overview(key: const ValueKey('o'), event: widget.event);
      case 1:
        return _Details(
            key: const ValueKey('d'), event: widget.event, accent: accent);
      default:
        return _Rewards(
            key: const ValueKey('r'), event: widget.event, accent: accent);
    }
  }
}

class _EventFeedbackSection extends StatelessWidget {
  final String eventId;
  const _EventFeedbackSection({required this.eventId});

  Future<void> _showFeedbackDialog(BuildContext context) async {
    var rating = 5;
    final commentCtrl = TextEditingController();
    final submitted = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Rate this event'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How was your experience?',
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 1; i <= 5; i++)
                    IconButton(
                      onPressed: () => setLocal(() => rating = i),
                      icon: Icon(
                        i <= rating ? Icons.star_rounded : Icons.star_border_rounded,
                        color: AppColors.warning,
                        size: 32,
                      ),
                    ),
                ],
              ),
              TextField(
                controller: commentCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Comment (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
    if (submitted != true || !context.mounted) {
      commentCtrl.dispose();
      return;
    }
    final ok = await context.read<AppState>().submitEventFeedback(
          eventId: eventId,
          rating: rating,
          comment: commentCtrl.text,
        );
    commentCtrl.dispose();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Thanks for your feedback!' : 'Could not submit feedback'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final existing = state.eventFeedbackFor(eventId);
    if (existing != null) {
      final rating = (existing['rating'] as num?)?.toInt() ?? 0;
      final comment = existing['comment']?.toString();
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: cardDecoration(color: AppColors.surfaceMuted),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your rating',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                for (var i = 1; i <= 5; i++)
                  Icon(
                    i <= rating ? Icons.star_rounded : Icons.star_border_rounded,
                    color: AppColors.warning,
                    size: 20,
                  ),
              ],
            ),
            if (comment != null && comment.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                comment,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ],
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: () => _showFeedbackDialog(context),
      icon: const Icon(Icons.rate_review_outlined),
      label: const Text('Rate this event'),
    );
  }
}

class _Header extends StatelessWidget {
  final Event event;
  const _Header({required this.event});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final fav = state.isEventFavorite(event.id);
    final pose = _poseFor(event.id.hashCode);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppGradients.category(event.category),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(AppRadii.xl),
          bottomRight: Radius.circular(AppRadii.xl),
        ),
        boxShadow: glow(
          AppCategoryStyle.accent(event.category),
          alpha: 0.30,
          blurRadius: 26,
          offset: const Offset(0, 12),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(AppRadii.xl),
          bottomRight: Radius.circular(AppRadii.xl),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              top: -20,
              child: _headerBlob(150, 0.14),
            ),
            Positioned(
              left: -36,
              bottom: -44,
              child: _headerBlob(140, 0.10),
            ),
            // Mascot peeking from the top-right (replaces the hot-air balloon).
            Positioned(
              right: 8,
              top: 30,
              child: BirdSticker(size: 116, row: pose[0], col: pose[1]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _circleButton(
                        icon: Icons.arrow_back_rounded,
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                      const Spacer(),
                      _circleButton(
                        icon: fav
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        iconColor: fav ? AppColors.warning : Colors.white,
                        onTap: () => context
                            .read<AppState>()
                            .toggleFavoriteEvent(event.id),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      _headerChip(Icons.auto_awesome, '+${event.points} pts'),
                      const SizedBox(width: AppSpacing.sm),
                      _headerChip(event.category.icon, event.category.label),
                      if (event.category == EventCategory.serve &&
                          event.volunteerHours > 0) ...[
                        const SizedBox(width: AppSpacing.sm),
                        _headerChip(
                          Icons.access_time,
                          '${event.volunteerHours % 1 == 0 ? event.volunteerHours.toInt() : event.volunteerHours.toStringAsFixed(1)} volunteer h',
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Padding(
                    padding: const EdgeInsets.only(right: 96),
                    child: Text(
                      event.title,
                      style: playfulDisplay(
                        size: 28,
                        weight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.05,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.30)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.white.withValues(alpha: 0.4),
                          child: const Icon(Icons.person, color: Colors.white),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                event.organizer,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              Text(
                                event.organizerRole,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Colors.white
                                          .withValues(alpha: 0.85),
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static List<int> _poseFor(int seed) {
    const poses = [
      [0, 2],
      [2, 2],
      [4, 0],
      [1, 2],
      [3, 0],
      [2, 1],
    ];
    return poses[seed.abs() % poses.length];
  }

  Widget _headerBlob(double size, double alpha) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: alpha),
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required VoidCallback onTap,
    Color iconColor = Colors.white,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.pill),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
      ),
    );
  }

  Widget _headerChip(IconData icon, String label) {
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

class _TabBar extends StatelessWidget {
  final List<String> tabs;
  final int index;
  final Color accent;
  final ValueChanged<int> onChanged;
  const _TabBar({
    required this.tabs,
    required this.index,
    required this.accent,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          for (int i = 0; i < tabs.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: index == i ? accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                    boxShadow: index == i
                        ? glow(accent, alpha: 0.28, blurRadius: 12)
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    tabs[i],
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: index == i
                              ? Colors.white
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Overview extends StatefulWidget {
  final Event event;
  const _Overview({super.key, required this.event});

  @override
  State<_Overview> createState() => _OverviewState();
}

class _OverviewState extends State<_Overview> {
  EventPrediction? _prediction;
  bool _loading = false;
  bool _fromBackend = false;
  String? _error;

  Event _currentEvent(AppState state) =>
      state.eventById(widget.event.id) ?? widget.event;

  bool _canSeePrediction(AppState state) =>
      state.isStudentAffairs ||
      state.isDeanOfFaculty ||
      state.isEventOrganizer(widget.event.id) ||
      (widget.event.clubId != null &&
          state.isClubLeader(widget.event.clubId!));

  bool _canRefreshPrediction(AppState state) =>
      state.useBackendData &&
      isBackendId(widget.event.id) &&
      (state.isEventOrganizer(widget.event.id) ||
          state.isStudentAffairs ||
          state.isDeanOfFaculty);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPrediction());
  }

  Future<void> _loadPrediction({bool forceRefresh = false}) async {
    final state = context.read<AppState>();
    if (!_canSeePrediction(state)) return;

    final event = _currentEvent(state);

    if (state.useBackendData && isBackendId(widget.event.id)) {
      if (!forceRefresh && event.aiSuccessScore != null && !_canRefreshPrediction(state)) {
        setState(() {
          _fromBackend = true;
          _prediction = _fromStoredScore(event);
          _error = null;
        });
        return;
      }

      if (!forceRefresh &&
          event.aiSuccessScore != null &&
          _canRefreshPrediction(state)) {
        setState(() {
          _fromBackend = true;
          _prediction = _fromStoredScore(event);
          _error = null;
        });
        return;
      }

      if (!_canRefreshPrediction(state)) {
        setState(() {
          _prediction = event.aiSuccessScore != null ? _fromStoredScore(event) : null;
          _fromBackend = event.aiSuccessScore != null;
          _error = event.aiSuccessScore == null
              ? 'Only the event organizer can run a live prediction.'
              : null;
        });
        return;
      }

      setState(() {
        _loading = true;
        _error = null;
      });
      final prediction =
          await context.read<AppState>().refreshEventPrediction(widget.event.id);
      if (!mounted) return;
      final refreshed = _currentEvent(context.read<AppState>());
      setState(() {
        _loading = false;
        _fromBackend = prediction != null;
        _prediction = prediction ??
            (refreshed.aiSuccessScore != null
                ? _fromStoredScore(refreshed)
                : null);
        _error = prediction == null
            ? 'Live prediction failed. Start the AI service (npm run dev:ai), train the model (npm run train:ai), and use an organizer account.'
            : null;
      });
      return;
    }

    setState(() {
      _fromBackend = false;
      _error = null;
      _prediction = const EventPredictionService().predict(event);
    });
  }

  EventPrediction _fromStoredScore(Event event) {
    final rate = (event.aiSuccessScore ?? 0) / 100;
    final predicted = (event.capacity * rate).round();
    return EventPrediction(
      predictedAttendance: predicted,
      attendanceRate: rate,
      successScore: rate,
      confidence: (event.aiSuccessScore ?? 0) >= 75 ? 'High' : 'Medium',
      reasons: [
        'Saved ML score on this event: ${event.aiSuccessScore!.round()}%',
        'Tap Refresh after students enroll to re-run with live Shams profiles.',
      ],
      recommendations: const [
        'Enroll students who completed Shams, then refresh the prediction.',
      ],
      matchedStudentSegments: const [],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final event = _currentEvent(state);
    final canRefresh = _canRefreshPrediction(state);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
      children: [
        Text('About',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: AppSpacing.sm),
        Text(
          event.about,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppColors.textSecondary, height: 1.4),
        ),
        if ((state.isEventOrganizer(event.id) ||
                state.isStudentAffairs ||
                state.isDeanOfFaculty) &&
            event.status == 'published' &&
            event.joinToken != null &&
            event.joinToken!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          _EventJoinLinkCard(joinToken: event.joinToken!),
        ],
        if (event.whatToExpect.trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(
            'What to expect',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: cardDecoration(color: AppColors.surfaceMuted),
            child: Text(
              event.whatToExpect,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
            ),
          ),
        ],
        if (event.category == EventCategory.serve && event.volunteerHours > 0) ...[
          const SizedBox(height: AppSpacing.lg),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: cardDecoration(color: AppColors.success.withValues(alpha: 0.08)),
            child: Row(
              children: [
                Icon(Icons.volunteer_activism_outlined,
                    color: AppColors.success, size: 28),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Completing this service event can earn '
                    '${event.volunteerHours % 1 == 0 ? event.volunteerHours.toInt() : event.volunteerHours.toStringAsFixed(1)} '
                    'approved volunteer hours toward your 120h requirement.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.35,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_error != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: cardDecoration(color: AppColors.surfaceMuted),
            child: Text(
              _error!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
            ),
          )
        else if (_prediction != null) ...[
          _PredictionCard(
            prediction: _prediction!,
            fromBackend: _fromBackend,
            onRefresh: canRefresh
                ? () => _loadPrediction(forceRefresh: true)
                : null,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (event.tags.isNotEmpty) ...[
          Text('Tags',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in event.tags.where((tag) =>
                  _canSeePrediction(state) || !tag.endsWith('% AI success')))
                Chip(label: Text(t), backgroundColor: AppColors.surfaceMuted),
            ],
          ),
        ],
        if (state.isEventOrganizer(event.id)) ...[
          const SizedBox(height: AppSpacing.lg),
          _OrganizerAnalyticsSection(eventId: event.id),
        ],
      ],
    );
  }
}

class _OrganizerAnalyticsSection extends StatefulWidget {
  final String eventId;
  const _OrganizerAnalyticsSection({required this.eventId});

  @override
  State<_OrganizerAnalyticsSection> createState() =>
      _OrganizerAnalyticsSectionState();
}

class _OrganizerAnalyticsSectionState extends State<_OrganizerAnalyticsSection> {
  Map<String, dynamic>? _analytics;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final data =
        await context.read<AppState>().loadEventAnalytics(widget.eventId);
    if (!mounted) return;
    setState(() {
      _analytics = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_analytics == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: cardDecoration(color: AppColors.surfaceMuted),
        child: Text(
          'Analytics unavailable for this event.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      );
    }

    final attendance = _analytics!['attendance'];
    final feedback = _analytics!['feedback'];
    final fillRate = attendance is Map
        ? (attendance['fill_rate'] as num?)?.toDouble()
        : null;
    final checkInRate = attendance is Map
        ? (attendance['check_in_rate'] as num?)?.toDouble()
        : null;
    final avgRating =
        feedback is Map ? (feedback['average_rating'] as num?)?.toDouble() : null;
    final feedbackCount =
        feedback is Map ? (feedback['count'] as num?)?.toInt() ?? 0 : 0;
    final comments = feedback is Map ? feedback['comments'] : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: cardDecoration(color: AppColors.surface),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Organizer analytics',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.md),
          if (fillRate != null)
            Text(
              'Fill rate: ${(fillRate * 100).round()}%',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          if (checkInRate != null)
            Text(
              'Check-in rate: ${(checkInRate * 100).round()}%',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          const SizedBox(height: AppSpacing.md),
          Text(
            feedbackCount > 0 && avgRating != null
                ? 'Feedback: ${avgRating.toStringAsFixed(1)} / 5 ($feedbackCount ratings)'
                : 'No feedback yet',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          if (comments is List && comments.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Comments',
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.xs),
            for (final row in comments.take(6)) ...[
              if (row is Map) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${(row['rating'] as num?)?.toInt() ?? 0}★',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.warning,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        row['comment']?.toString() ?? '',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.35,
                            ),
                      ),
                    ),
                  ],
                ),
                if (row != comments.take(6).last)
                  const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ],
        ],
      ),
    );
  }
}

class _PredictionCard extends StatelessWidget {
  final EventPrediction prediction;
  final bool fromBackend;
  final VoidCallback? onRefresh;
  const _PredictionCard({
    required this.prediction,
    this.fromBackend = false,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: cardDecoration(color: AppColors.surface),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.accentLight,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: const Icon(Icons.auto_awesome, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Prediction',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      fromBackend
                          ? 'Live ML model (enrollments + Shams profiles)'
                          : 'Offline demo estimate only',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              if (onRefresh != null)
                IconButton(
                  tooltip: 'Refresh prediction',
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh_rounded),
                )
              else
                Chip(
                  label: Text(prediction.confidence),
                  backgroundColor: AppColors.surfaceMuted,
                ),
            ],
          ),
          if (onRefresh != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: Chip(
                label: Text(prediction.confidence),
                backgroundColor: AppColors.surfaceMuted,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _PredictionMetric(
                  label: 'Attendance',
                  value: '${prediction.predictedAttendance}',
                  detail: '${prediction.attendancePercent}% of capacity',
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _PredictionMetric(
                  label: 'Success',
                  value: '${prediction.successPercent}%',
                  detail: 'projected outcome',
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _ProgressLine(
            label: 'Attendance rate',
            value: prediction.attendanceRate,
          ),
          const SizedBox(height: AppSpacing.sm),
          _ProgressLine(
            label: 'Success score',
            value: prediction.successScore,
            color: AppColors.success,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (prediction.matchedStudentSegments.isNotEmpty) ...[
            Text(
              'Likely audience',
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final segment in prediction.matchedStudentSegments)
                  Chip(label: Text(segment)),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          _InsightList(title: 'Why', items: prediction.reasons),
          const SizedBox(height: AppSpacing.md),
          _InsightList(
            title: 'Recommendations',
            items: prediction.recommendations,
            icon: Icons.tips_and_updates_outlined,
          ),
        ],
      ),
    );
  }
}

class _PredictionMetric extends StatelessWidget {
  final String label;
  final String value;
  final String detail;
  final Color color;

  const _PredictionMetric({
    required this.label,
    required this.value,
    required this.detail,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                ),
          ),
          Text(
            detail,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

class _ProgressLine extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _ProgressLine({
    required this.label,
    required this.value,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            Text(
              '${(value * 100).round()}%',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 8,
            backgroundColor: AppColors.surfaceMuted,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _InsightList extends StatelessWidget {
  final String title;
  final List<String> items;
  final IconData icon;

  const _InsightList({
    required this.title,
    required this.items,
    this.icon = Icons.analytics_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .labelLarge
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final item in items) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  item,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                ),
              ),
            ],
          ),
          if (item != items.last) const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _Details extends StatefulWidget {
  final Event event;
  final Color accent;
  const _Details({super.key, required this.event, required this.accent});

  @override
  State<_Details> createState() => _DetailsState();
}

class _DetailsState extends State<_Details> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<AppState>();
      if (state.isEventJoined(widget.event.id)) {
        state.loadEventAttendees(widget.event.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final joined = state.isEventJoined(widget.event.id);
    final attendees = state.eventAttendees(widget.event.id);
    final event = widget.event;
    final accent = widget.accent;
    final items = [
      ('Location', event.location, Icons.location_on_outlined),
      ('Date', event.date, Icons.calendar_today_outlined),
      ('Duration', event.duration, Icons.schedule_outlined),
      ('Participants', event.participants, Icons.groups_outlined),
      ('Format', event.format, Icons.assignment_outlined),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
      children: [
        Text('Details',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: AppSpacing.md),
        for (final i in items) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: cardDecoration(),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  child: Icon(i.$3, color: accent),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        i.$1,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: AppColors.textMuted,
                            ),
                      ),
                      Text(
                        i.$2,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (joined) ...[
          Text(
            'Who is attending',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: cardDecoration(),
            child: CampusPeopleList(
              people: attendees,
              accent: accent,
              emptyMessage: 'No other enrollments yet. You may be the first!',
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ] else ...[
          Text(
            'Enroll to see who else is attending this event.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ],
    );
  }
}

class _VolunteerHoursBanner extends StatelessWidget {
  final double hours;
  final String eventId;

  const _VolunteerHoursBanner({
    required this.hours,
    required this.eventId,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final opp = state.volunteerOpportunityForEvent(eventId);
    final applied =
        opp != null && state.hasAppliedForVolunteerOpportunity(opp.id);
    final hoursLabel =
        hours % 1 == 0 ? '${hours.toInt()}' : hours.toStringAsFixed(1);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration:
          cardDecoration(color: AppColors.success.withValues(alpha: 0.08)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.volunteer_activism_outlined,
                  color: AppColors.success, size: 22),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  '$hoursLabel volunteer hours available',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.success,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Scan the volunteer QR from Student Affairs or your dean to apply.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
          ),
          if (opp != null) ...[
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: applied
                    ? null
                    : () {
                        final token = opp.joinToken;
                        Navigator.of(context).push(
                          FadeSlidePageRoute(
                            builder: (_) => VolunteerScanScreen(
                              initialJoinToken: token,
                            ),
                          ),
                        );
                      },
                icon: Icon(
                  applied
                      ? Icons.check_circle_outline
                      : Icons.qr_code_scanner_outlined,
                ),
                label: Text(
                  applied
                      ? 'Volunteer application pending'
                      : 'Scan QR to volunteer',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Rewards extends StatelessWidget {
  final Event event;
  final Color accent;
  const _Rewards({super.key, required this.event, required this.accent});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
      children: [
        Text('Rewards',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: AppSpacing.md),
        for (final r in event.rewards) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: cardDecoration(),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  child: Icon(r.icon, color: accent),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.label,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        r.detail,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _EventJoinLinkCard extends StatelessWidget {
  final String joinToken;

  const _EventJoinLinkCard({required this.joinToken});

  @override
  Widget build(BuildContext context) {
    return JoinLinkQrCard(
      title: 'Student join link',
      subtitle:
          'Students scan this QR or open the link to enroll in the event.',
      link: JoinLinks.eventJoinLink(joinToken),
      copyLabel: 'Copy join link',
    );
  }
}
