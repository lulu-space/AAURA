import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_exception.dart';
import '../../data/campus_form_options.dart';
import '../../models/event.dart';
import '../../models/event_prediction.dart';
import '../../services/event_prediction_service.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';

class CreateEventScreen extends StatefulWidget {
  /// When set, the event is published on behalf of this club (leader flow).
  final String? clubId;
  /// When set, saves changes to an existing event instead of creating one.
  final Event? editEvent;

  const CreateEventScreen({super.key, this.clubId, this.editEvent});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _location = TextEditingController();
  final _date = TextEditingController();
  final _duration = TextEditingController();
  final _about = TextEditingController();
  final _whatToExpect = TextEditingController();
  final _tags = TextEditingController();
  final _capacity = TextEditingController(text: '60');
  final _points = TextEditingController(text: '10');
  final _volunteerHours = TextEditingController(text: '2');

  EventCategory _category = EventCategory.learn;
  int _promotionLevel = 3;
  DateTime _startsAt = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
    16,
  ).add(const Duration(days: 7));
  int _durationHours = 2;
  final Set<String> _targetMajors = {};
  final Set<String> _targetYears = {};
  final Set<String> _targetInterests = {};
  final Set<String> _targetSkills = {};

  EventPrediction? _draftPrediction;
  bool _draftLoading = false;
  Timer? _draftDebounce;

  bool get _isEditing => widget.editEvent != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.editEvent;
    if (existing == null) {
      return;
    }
    _title.text = existing.title;
    _location.text = existing.location;
    _date.text = existing.date;
    _duration.text = existing.duration;
    if (existing.startsAt != null) {
      _startsAt = existing.startsAt!;
      if (existing.endsAt != null) {
        final hrs = existing.endsAt!.difference(existing.startsAt!).inHours;
        if (hrs > 0) _durationHours = hrs;
      }
    }
    _about.text = existing.about;
    _whatToExpect.text = existing.whatToExpect;
    _tags.text = existing.tags.join(', ');
    _capacity.text = '${existing.capacity}';
    _points.text = '${existing.points}';
    _category = existing.category;
    _promotionLevel = existing.promotionLevel;
    if (existing.volunteerHours > 0) {
      _volunteerHours.text = existing.volunteerHours.toStringAsFixed(
        existing.volunteerHours.truncateToDouble() == existing.volunteerHours
            ? 0
            : 1,
      );
    }
    _targetMajors
      ..clear()
      ..addAll(existing.targetMajors);
    _targetYears
      ..clear()
      ..addAll(existing.targetYears);
    _targetInterests
      ..clear()
      ..addAll(existing.targetInterests);
    _scheduleDraftPrediction(immediate: true);
  }

  @override
  void dispose() {
    _draftDebounce?.cancel();
    _title.dispose();
    _location.dispose();
    _date.dispose();
    _duration.dispose();
    _about.dispose();
    _whatToExpect.dispose();
    _tags.dispose();
    _capacity.dispose();
    _points.dispose();
    _volunteerHours.dispose();
    super.dispose();
  }

  Event get _draftEvent {
    final organizer = context.read<AppState>().profile?.name ?? 'AAURA Organizer';
    final base = widget.editEvent;
    return Event(
      id: base?.id ?? 'evt-${DateTime.now().millisecondsSinceEpoch}',
      title: _safeText(_title, 'Untitled Event'),
      organizer: base?.organizer ?? organizer,
      organizerRole: base?.organizerRole ??
          (widget.clubId != null ? 'Club Leader' : 'Student Affairs'),
      organizerId: base?.organizerId,
      about: _safeText(_about, 'Draft event preview.'),
      whatToExpect: _whatToExpect.text.trim(),
      location: _safeText(_location, 'Campus'),
      date: _formatSchedule(_startsAt),
      duration: '$_durationHours ${_durationHours == 1 ? 'hour' : 'hours'}',
      startsAt: _startsAt,
      endsAt: _startsAt.add(Duration(hours: _durationHours)),
      participants: _targetMajors.isEmpty
          ? 'Open to all students'
          : _targetMajors.join(', '),
      format: 'On-site',
      category: _category,
      points: int.tryParse(_points.text.trim()) ?? 10,
      tags: _tags.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList(),
      capacity: int.tryParse(_capacity.text.trim()) ?? 60,
      targetMajors: _targetMajors.toList(),
      targetYears: _targetYears.toList(),
      targetInterests: _targetInterests.toList(),
      clubId: widget.clubId,
      promotionLevel: _promotionLevel,
      volunteerHours: _category == EventCategory.serve
          ? (double.tryParse(_volunteerHours.text.trim()) ?? 0)
          : 0,
      rewards: [
        EventReward(
          label: '+${int.tryParse(_points.text.trim()) ?? 10} Points',
          detail: 'Displayed on Profile',
          icon: Icons.stars_outlined,
        ),
      ],
    );
  }

  String _safeText(TextEditingController controller, String fallback) {
    final value = controller.text.trim();
    return value.isEmpty ? fallback : value;
  }

  void _refreshPreview() {
    setState(() {});
    _scheduleDraftPrediction();
  }

  Future<void> _scheduleDraftPrediction({bool immediate = false}) async {
    _draftDebounce?.cancel();
    if (immediate) {
      await _runDraftPrediction();
      return;
    }
    _draftDebounce = Timer(const Duration(milliseconds: 450), () {
      _runDraftPrediction();
    });
  }

  Future<void> _runDraftPrediction() async {
    if (!mounted) return;
    final title = _title.text.trim();
    if (title.length < 3) {
      setState(() {
        _draftLoading = false;
        _draftPrediction = null;
      });
      return;
    }
    setState(() => _draftLoading = true);
    final draft = _draftEvent;
    final live = await const EventPredictionService().predictDraft(
      event: draft,
      targetSkills: _targetSkills.toList(),
    );
    if (!mounted) return;
    setState(() {
      _draftLoading = false;
      _draftPrediction = live ?? const EventPredictionService().predict(draft);
    });
  }

  Future<void> _publish() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final event = _draftEvent;
    try {
      final saved = _isEditing
          ? await context.read<AppState>().updateEvent(event)
          : await context.read<AppState>().publishEvent(event);
      if (!mounted) return;
      if (saved == null) {
        messenger.showSnackBar(const SnackBar(
          content: Text('Could not save event. Check your connection and try again.'),
        ));
        return;
      }
      final aiNote = saved.aiSuccessScore != null
          ? ' · AI success ${saved.aiSuccessScore!.round()}%'
          : '';
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Updated "${event.title}"$aiNote'
                : _publishSavedMessage(saved, event.title, aiNote),
          ),
        ),
      );
      navigator.pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  String _publishSavedMessage(Event saved, String title, String aiNote) {
    final state = context.read<AppState>();
    if (state.isDeanOfFaculty || state.isAdmin) {
      return 'Published "$title" for your faculty$aiNote';
    }
    if (saved.isApproved && saved.status == 'published') {
      return 'Published "$title"$aiNote';
    }
    return 'Submitted "$title" for Student Affairs review$aiNote';
  }

  @override
  Widget build(BuildContext context) {
    final prediction = _draftPrediction;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Event' : 'Create Event Preview'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          onChanged: _refreshPreview,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.xxl,
            ),
            children: [
              Text(
                'Draft an event',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Fill in the details and preview likely attendance, then publish it to the Events page.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _SectionCard(
                title: 'Basics',
                children: [
                  _textField(_title, 'Title'),
                  _textField(_about, 'About', maxLines: 3),
                  _textField(
                    _whatToExpect,
                    'What to expect',
                    maxLines: 3,
                    hint: 'Agenda, what to bring, dress code…',
                  ),
                  DropdownButtonFormField<EventCategory>(
                    initialValue: _category,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: [
                      for (final category in EventCategory.values)
                        DropdownMenuItem(
                          value: category,
                          child: Text(category.label),
                        ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _category = value);
                      _refreshPreview();
                    },
                  ),
                  if (_category == EventCategory.serve) ...[
                    const SizedBox(height: AppSpacing.md),
                    _textField(
                      _volunteerHours,
                      'Volunteer hours awarded',
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      helperText:
                          'Hours students earn after Student Affairs approves their application.',
                    ),
                  ],
                  _textField(_location, 'Location'),
                  _scheduleTile(),
                  _durationField(),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _SectionCard(
                title: 'Rewards and reach',
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _textField(
                          _capacity,
                          'Capacity',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _textField(
                          _points,
                          'Points',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  _textField(_tags, 'Tags, comma separated'),
                  Text(
                    'Promotion level: $_promotionLevel',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Slider(
                    value: _promotionLevel.toDouble(),
                    min: 1,
                    max: 5,
                    divisions: 4,
                    label: '$_promotionLevel',
                    onChanged: (value) {
                      setState(() => _promotionLevel = value.round());
                      _scheduleDraftPrediction();
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _SectionCard(
                title: 'Target audience',
                children: [
                  _chipSelector('Majors', CampusFormOptions.majors, _targetMajors),
                  _chipSelector('Years', CampusFormOptions.years, _targetYears),
                  _chipSelector(
                    'Interests',
                    CampusFormOptions.interestOptions,
                    _targetInterests,
                  ),
                  _chipSelector(
                    'Skills',
                    CampusFormOptions.skillOptions,
                    _targetSkills,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              if (prediction != null || _draftLoading)
                _DraftPredictionCard(
                  prediction: prediction,
                  loading: _draftLoading,
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: cardDecoration(color: AppColors.surfaceMuted),
                  child: Text(
                    'Enter an event title (3+ characters) to preview AI success estimates. '
                    'Adjust targets and promotion to see the percentage change.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                  ),
                ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _publish,
                  icon: Icon(_isEditing ? Icons.save_outlined : Icons.publish_outlined),
                  label: Text(_isEditing ? 'Save changes' : 'Publish event'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  String _formatSchedule(DateTime dt) {
    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final ampm = dt.hour < 12 ? 'AM' : 'PM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${_weekdays[dt.weekday - 1]} ${dt.day} ${_months[dt.month - 1]}'
        ' · $hour12:$minute $ampm';
  }

  Future<void> _pickSchedule() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _startsAt.isBefore(now) ? now : _startsAt,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startsAt),
    );
    if (!mounted) return;
    setState(() {
      _startsAt = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? _startsAt.hour,
        time?.minute ?? _startsAt.minute,
      );
    });
    _scheduleDraftPrediction();
  }

  Widget _scheduleTile() {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: _pickSchedule,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Date & time',
            suffixIcon: Icon(Icons.event_outlined),
          ),
          child: Text(_formatSchedule(_startsAt)),
        ),
      ),
    );
  }

  Widget _durationField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: DropdownButtonFormField<int>(
        initialValue: _durationHours,
        decoration: const InputDecoration(labelText: 'Duration'),
        items: [
          for (final h in const [1, 2, 3, 4, 6, 8])
            DropdownMenuItem(
              value: h,
              child: Text('$h ${h == 1 ? 'hour' : 'hours'}'),
            ),
        ],
        onChanged: (value) {
          if (value == null) return;
          setState(() => _durationHours = value);
          _scheduleDraftPrediction();
        },
      ),
    );
  }

  Widget _textField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    TextInputType? keyboardType,
    String? hint,
    String? helperText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          helperText: helperText,
        ),
        maxLines: maxLines,
        keyboardType: keyboardType,
      ),
    );
  }

  Widget _chipSelector(
    String label,
    List<String> options,
    Set<String> selected,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in options)
                FilterChip(
                  label: Text(option),
                  selected: selected.contains(option),
                  onSelected: (value) {
                    setState(() {
                      if (value) {
                        selected.add(option);
                      } else {
                        selected.remove(option);
                      }
                    });
                    _scheduleDraftPrediction();
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ...children,
        ],
      ),
    );
  }
}

class _DraftPredictionCard extends StatelessWidget {
  final EventPrediction? prediction;
  final bool loading;

  const _DraftPredictionCard({
    required this.prediction,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (loading && prediction == null) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: cardDecoration(color: AppColors.surface),
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    if (prediction == null) return const SizedBox.shrink();
    final predictionData = prediction!;
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
                      'AI Event Prediction',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      predictionData.isLiveMl
                          ? 'Live XGBoost preview from your draft'
                          : 'Offline estimate — start backend + AI for live ML',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (loading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Chip(label: Text(predictionData.confidence)),
            ],
          ),
          if (predictionData.inputSummary.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'Your inputs',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final line in predictionData.inputSummary)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Text(
                  line,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'Expected',
                  value: '${predictionData.predictedAttendance}',
                  detail: '${predictionData.attendancePercent}% of capacity',
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _MetricTile(
                  label: 'Success',
                  value: '${predictionData.successPercent}%',
                  detail: 'projected',
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Likely audience',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final segment in predictionData.matchedStudentSegments)
                Chip(label: Text(segment)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _Bullets(title: 'Why', items: predictionData.reasons),
          const SizedBox(height: AppSpacing.md),
          _Bullets(title: 'Recommendations', items: predictionData.recommendations),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String detail;
  final Color color;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.detail,
    this.color = AppColors.primary,
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

class _Bullets extends StatelessWidget {
  final String title;
  final List<String> items;

  const _Bullets({
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final item in items) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 18,
                color: AppColors.primary,
              ),
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
