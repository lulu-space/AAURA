import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/club.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';

/// Student-facing form to request founding a new club. Submits to Student Affairs
/// for review. Guardrails (eligibility, cooldown, duplicate names) are enforced
/// by the backend.
class ClubRequestFormScreen extends StatefulWidget {
  const ClubRequestFormScreen({super.key});

  @override
  State<ClubRequestFormScreen> createState() => _ClubRequestFormScreenState();
}

class _ClubRequestFormScreenState extends State<ClubRequestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _advisorEmail = TextEditingController();
  final _coFounder1 = TextEditingController();
  final _coFounder2 = TextEditingController();
  ClubCategory _category = ClubCategory.academic;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppState>().refreshClubRequestEligibility();
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _advisorEmail.dispose();
    _coFounder1.dispose();
    _coFounder2.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final state = context.read<AppState>();
    if (!state.canSubmitClubRequest) {
      _snack(state.clubRequestEligibility?.primaryReason ??
          'You cannot submit a club request right now.');
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _submitting = true);
    final error = await state.submitClubRequest(
      proposedName: _name.text.trim(),
      description: _description.text.trim(),
      category: _category.name,
      advisorEmail: _advisorEmail.text.trim(),
      coFounderNames: [
        if (_coFounder1.text.trim().length >= 2) _coFounder1.text.trim(),
        if (_coFounder2.text.trim().length >= 2) _coFounder2.text.trim(),
      ],
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (error == null) {
      messenger.showSnackBar(const SnackBar(
        content: Text(
          'Pending approval from Student Affairs. We\'ll notify you when reviewed.',
        ),
      ));
      navigator.pop();
    } else {
      _snack(error);
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final eligibility = state.clubRequestEligibility;
    final blocked = eligibility != null && !eligibility.eligible;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Start a Club')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
            children: [
              Text(
                'Propose a new club',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Available from 2nd year after onboarding. One pending request '
                'at a time. Student Affairs reviews every proposal.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
              ),
              if (blocked) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.accentLight.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(AppRadii.lg),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Not eligible yet',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      for (final reason in eligibility.reasons)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '• $reason',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _name,
                enabled: !blocked,
                decoration: const InputDecoration(labelText: 'Club name'),
                textCapitalization: TextCapitalization.words,
                validator: (v) => (v == null || v.trim().length < 3)
                    ? 'Enter at least 3 characters'
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<ClubCategory>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: [
                  for (final c in ClubCategory.values)
                    DropdownMenuItem(value: c, child: Text(c.label)),
                ],
                onChanged: blocked
                    ? null
                    : (v) {
                        if (v != null) setState(() => _category = v);
                      },
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _description,
                enabled: !blocked,
                decoration: const InputDecoration(
                  labelText: 'Mission and planned activities',
                  alignLabelWithHint: true,
                  helperText: 'At least 50 characters',
                ),
                maxLines: 5,
                validator: (v) => (v == null || v.trim().length < 50)
                    ? 'Describe your club in at least 50 characters'
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _advisorEmail,
                enabled: !blocked,
                decoration: const InputDecoration(
                  labelText: 'Faculty advisor email',
                  helperText:
                      'Must match a dean who has signed up with their @aaup.edu email.',
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  final email = v?.trim() ?? '';
                  if (!email.contains('@') || !email.contains('.')) {
                    return 'Enter a valid advisor email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _coFounder1,
                enabled: !blocked,
                decoration: const InputDecoration(
                  labelText: 'Co-founder 1 (optional)',
                  helperText: 'Full name if you have a co-founder',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _coFounder2,
                enabled: !blocked,
                decoration: const InputDecoration(
                  labelText: 'Co-founder 2 (optional)',
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submitting || blocked ? null : _submit,
                  icon: _submitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_outlined),
                  label: Text(_submitting ? 'Submitting...' : 'Submit request'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
