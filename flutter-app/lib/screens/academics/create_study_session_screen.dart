import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/study_session.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/success_burst.dart';

class CreateStudySessionScreen extends StatefulWidget {
  final StudySession? existing;
  const CreateStudySessionScreen({super.key, this.existing});

  @override
  State<CreateStudySessionScreen> createState() =>
      _CreateStudySessionScreenState();
}

class _CreateStudySessionScreenState extends State<CreateStudySessionScreen> {
  late final TextEditingController _course;
  late final TextEditingController _details;
  late StudySessionType _type;
  late bool _limitSeats;
  late int _seats;
  late DateTime _startsAt;
  late DateTime _endsAt;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _course = TextEditingController(text: existing?.course ?? '');
    _details = TextEditingController(text: existing?.details ?? '');
    _type = existing?.type ?? StudySessionType.publicTogether;
    _limitSeats = existing?.seatsLeft != null;
    _seats = existing?.seatsLeft ?? 4;
    _startsAt = existing?.startsAt ??
        DateTime.now().add(const Duration(days: 1)).copyWith(
              hour: 18,
              minute: 0,
              second: 0,
              millisecond: 0,
              microsecond: 0,
            );
    _endsAt = existing?.endsAt ?? _startsAt.add(const Duration(hours: 2));
  }

  @override
  void dispose() {
    _course.dispose();
    _details.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime({required bool end}) async {
    final initial = end ? _endsAt : _startsAt;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;
    final picked = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (end) {
        _endsAt = picked;
      } else {
        _startsAt = picked;
        if (!_endsAt.isAfter(_startsAt)) {
          _endsAt = _startsAt.add(const Duration(hours: 2));
        }
      }
    });
  }

  String _formatWhen(DateTime dt) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final day = weekdays[dt.weekday - 1];
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final suffix = dt.hour >= 12 ? 'PM' : 'AM';
    return '$day ${dt.day}/${dt.month} · $hour:$minute $suffix';
  }

  Future<void> _publish() async {
    final state = context.read<AppState>();
    final course = _course.text.trim().isEmpty ? 'Untitled' : _course.text.trim();
    final details = _details.text.trim();

    if (_isEditing) {
      final ok = await state.updateStudySession(
        widget.existing!,
        startsAt: _startsAt,
        endsAt: _endsAt,
        title: course,
        details: details,
        capacity: _limitSeats ? _seats : null,
        applyCapacity: true,
      );
      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update session.')),
        );
        return;
      }
      showSuccessBurst(context, label: 'Session updated!');
    } else {
      final session = StudySession(
        id: 'ss-custom-${DateTime.now().millisecondsSinceEpoch}',
        course: course,
        type: _type,
        details: details,
        when: _formatWhen(_startsAt),
        seatsLeft: _limitSeats ? _seats : null,
        host: state.profile?.name ?? 'You',
        startsAt: _startsAt,
        endsAt: _endsAt,
        hostId: state.userId,
      );
      await state.publishStudySession(session);
      if (!mounted) return;
      showSuccessBurst(context, label: 'Session published!');
    }

    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Study Session' : 'Create Study Session'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text('Course',
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          TextField(controller: _course),
          const SizedBox(height: AppSpacing.md),
          Text('Type',
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          DropdownButtonFormField<StudySessionType>(
            initialValue: _type,
            items: StudySessionType.values
                .map((t) =>
                    DropdownMenuItem(value: t, child: Text(t.label)))
                .toList(),
            onChanged: (v) => setState(() => _type = v ?? _type),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Starts',
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          OutlinedButton.icon(
            onPressed: () => _pickDateTime(end: false),
            icon: const Icon(Icons.event_outlined),
            label: Text(_formatWhen(_startsAt)),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('Ends',
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          OutlinedButton.icon(
            onPressed: () => _pickDateTime(end: true),
            icon: const Icon(Icons.schedule_outlined),
            label: Text(_formatWhen(_endsAt)),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Seats (optional)',
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Limit seats'),
            subtitle: const Text('Leave off for an open session'),
            value: _limitSeats,
            onChanged: (v) => setState(() => _limitSeats = v),
          ),
          if (_limitSeats)
            Row(
              children: [
                IconButton(
                  onPressed: () => setState(() {
                    if (_seats > 1) _seats -= 1;
                  }),
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text('$_seats',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        )),
                IconButton(
                  onPressed: () => setState(() {
                    if (_seats < 30) _seats += 1;
                  }),
                  icon: const Icon(Icons.add_circle_outline),
                ),
                const Spacer(),
                Text('seats available',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        )),
              ],
            ),
          const SizedBox(height: AppSpacing.md),
          Text('Details',
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          TextField(controller: _details, maxLines: 3),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _publish,
              icon: Icon(_isEditing ? Icons.save_outlined : Icons.arrow_forward),
              label: Text(_isEditing ? 'SAVE CHANGES' : 'PUBLISH AND START'),
            ),
          ),
        ],
      ),
    );
  }
}
