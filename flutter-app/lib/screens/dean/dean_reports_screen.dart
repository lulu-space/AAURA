import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme/app_theme.dart';

class DeanReportsScreen extends StatefulWidget {
  const DeanReportsScreen({super.key});

  @override
  State<DeanReportsScreen> createState() => _DeanReportsScreenState();
}

class _DeanReportsScreenState extends State<DeanReportsScreen> {
  String? _selectedType = 'events';
  Map<String, dynamic>? _report;
  bool _loading = false;

  static const _types = [
    ('events', 'Events', Icons.event_outlined),
    ('clubs', 'Clubs', Icons.groups_outlined),
    ('volunteering', 'Volunteering', Icons.volunteer_activism_outlined),
    ('engagement', 'Engagement', Icons.insights_outlined),
  ];

  Future<void> _generate() async {
    if (_selectedType == null) return;
    setState(() {
      _loading = true;
      _report = null;
    });
    final report =
        await context.read<AppState>().generateDeanReport(_selectedType!);
    if (!mounted) return;
    final error = context.read<AppState>().deanLastError;
    setState(() {
      _report = report;
      _loading = false;
    });
    if (report == null && error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final summary = _report?['summary'] as Map<String, dynamic>?;
    final rows = ((_report?['rows'] as List?) ?? const [])
        .cast<Map<String, dynamic>>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Faculty Reports'),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : null,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          if (!state.deanHasFaculty)
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: const Text(
                'Select your faculty on the Dashboard tab before generating reports.',
              ),
            )
          else ...[
            Text(
              'Report type',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final entry in _types)
                  ChoiceChip(
                    label: Text(entry.$2),
                    avatar: Icon(entry.$3, size: 18),
                    selected: _selectedType == entry.$1,
                    onSelected: (selected) {
                      if (!selected) return;
                      setState(() => _selectedType = entry.$1);
                    },
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _loading ? null : _generate,
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.description_outlined),
                label: Text(_loading ? 'Generating…' : 'Generate report'),
              ),
            ),
            if (_report != null) ...[
              const SizedBox(height: AppSpacing.lg),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  gradient: AppGradients.header,
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_report!['faculty']} · ${_labelForType(_report!['type']?.toString())}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Generated ${_report!['generated_at']}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.88),
                          ),
                    ),
                  ],
                ),
              ),
              if (summary != null && summary.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Summary',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final entry in summary.entries)
                      _SummaryChip(
                        label: _prettyKey(entry.key),
                        value: '${entry.value}',
                      ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Details (${rows.length})',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (rows.isEmpty)
                Text(
                  'No rows in this report.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                )
              else
                for (final row in rows.take(20))
                  _ReportRowCard(
                    title: _rowTitle(row),
                    subtitle: _rowSubtitle(row),
                    chips: _rowChips(row),
                  ),
            ],
          ],
        ],
      ),
    );
  }

  String _labelForType(String? type) {
    return switch (type) {
      'events' => 'Events',
      'clubs' => 'Clubs',
      'volunteering' => 'Volunteering',
      'engagement' => 'Engagement',
      _ => type ?? 'Report',
    };
  }

  String _prettyKey(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((part) =>
            part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  String _rowTitle(Map<String, dynamic> row) {
    return (row['title'] ??
            row['name'] ??
            row['proposed_name'] ??
            row['student_name'] ??
            row['interest'] ??
            'Item')
        .toString();
  }

  String _rowSubtitle(Map<String, dynamic> row) {
    final parts = <String>[];
    for (final key in const [
      'status',
      'category',
      'organizer_name',
      'requester_name',
      'hours',
      'check_ins',
      'count',
    ]) {
      final value = row[key];
      if (value == null || '$value'.trim().isEmpty) continue;
      parts.add('${_prettyKey(key)}: $value');
    }
    return parts.take(3).join(' · ');
  }

  List<String> _rowChips(Map<String, dynamic> row) {
    final chips = <String>[];
    final status = row['status']?.toString();
    if (status != null && status.isNotEmpty) chips.add(status);
    final major = row['major']?.toString();
    if (major != null && major.isNotEmpty) chips.add(major);
    final date = row['starts_at'] ?? row['created_at'] ?? row['occurred_at'];
    if (date != null) chips.add(date.toString().split('T').first);
    return chips;
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.surfaceMuted),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textMuted,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _ReportRowCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<String> chips;

  const _ReportRowCard({
    required this.title,
    required this.subtitle,
    required this.chips,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.surfaceMuted),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
            ),
          ],
          if (chips.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final chip in chips)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                    child: Text(
                      chip,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
