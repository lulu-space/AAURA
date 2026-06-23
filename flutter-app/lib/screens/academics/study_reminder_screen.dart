import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/study_session.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/campus_people_list.dart';
import '../../utils/transitions.dart';
import 'create_study_session_screen.dart';

class StudyReminderScreen extends StatefulWidget {
  final StudySession session;
  const StudyReminderScreen({super.key, required this.session});

  @override
  State<StudyReminderScreen> createState() => _StudyReminderScreenState();
}

class _StudyReminderScreenState extends State<StudyReminderScreen> {
  late Duration _remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remaining = _initialRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_remaining.inSeconds > 0) {
          _remaining = _remaining - const Duration(seconds: 1);
        }
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<AppState>();
      if (state.isSessionJoined(widget.session.id) ||
          state.isSessionHost(widget.session)) {
        state.loadStudySessionMembers(widget.session.id);
      }
    });
  }

  Duration _initialRemaining() {
    final startsAt = widget.session.startsAt;
    if (startsAt == null) {
      return const Duration(hours: 2, minutes: 15);
    }
    final diff = startsAt.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  Future<void> _confirmDelete(AppState state) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel session?'),
        content: const Text(
          'Enrolled students will be notified that this session was cancelled.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Cancel session'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final deleted = await state.deleteStudySession(widget.session);
    if (!mounted) return;
    if (deleted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session cancelled and members notified.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isHost = state.isSessionHost(widget.session);
    final joined = state.isSessionJoined(widget.session.id);
    final members = state.studySessionMembers(widget.session.id);
    final h = _two(_remaining.inHours);
    final m = _two(_remaining.inMinutes.remainder(60));
    final s = _two(_remaining.inSeconds.remainder(60));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Reminder'),
        actions: [
          if (isHost)
            IconButton(
              tooltip: 'Edit date & time',
              onPressed: () {
                Navigator.of(context).push(
                  FadeSlidePageRoute(
                    builder: (_) =>
                        CreateStudySessionScreen(existing: widget.session),
                  ),
                );
              },
              icon: const Icon(Icons.edit_calendar_outlined),
            ),
          if (isHost)
            IconButton(
              tooltip: 'Cancel session',
              onPressed: () => _confirmDelete(state),
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: AppGradients.header,
                borderRadius: BorderRadius.circular(AppRadii.xl),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Up next',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                          )),
                  const SizedBox(height: 4),
                  Text(widget.session.course,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          )),
                  const SizedBox(height: 6),
                  Text(
                    '${widget.session.type.label} · ${widget.session.when}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Center(
                    child: Text('$h : $m : $s',
                        style: Theme.of(context)
                            .textTheme
                            .displaySmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 4,
                            )),
                  ),
                  Center(
                    child: Text('Time until session',
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.85),
                                )),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hosted by',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppColors.textSecondary,
                          )),
                  const SizedBox(height: 4),
                  Text(widget.session.host,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          )),
                  const SizedBox(height: 8),
                  Text(widget.session.details,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          )),
                  const SizedBox(height: 8),
                  Text('${widget.session.seatsLeft} seats left',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          )),
                ],
              ),
            ),
            if (joined || isHost) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Who is attending',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: cardDecoration(),
                  child: SingleChildScrollView(
                    child: CampusPeopleList(
                      people: members,
                      emptyMessage:
                          'No one else has joined yet. Share the session with classmates.',
                    ),
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                'Join this session to see who else is attending.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const Spacer(),
            ],
            if (joined || isHost) const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Snoozed for 10 min')),
                      );
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.snooze_outlined),
                    label: const Text('Snooze'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Great - you're in!"),
                        ),
                      );
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.check),
                    label: const Text("I'm in"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
