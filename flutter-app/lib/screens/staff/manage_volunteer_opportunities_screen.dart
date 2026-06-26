import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/volunteer_requirements.dart';
import '../../models/volunteer_opportunity.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glow_widgets.dart';
import '../../widgets/join_link_qr_card.dart';
import '../../widgets/stat_chip.dart';

/// Student Affairs: publish and manage campus volunteer opportunities.
class ManageVolunteerOpportunitiesScreen extends StatefulWidget {
  const ManageVolunteerOpportunitiesScreen({super.key});

  @override
  State<ManageVolunteerOpportunitiesScreen> createState() =>
      _ManageVolunteerOpportunitiesScreenState();
}

class _ManageVolunteerOpportunitiesScreenState
    extends State<ManageVolunteerOpportunitiesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppState>().refreshVolunteerOpportunities();
    });
  }

  Future<void> _showForm({VolunteerOpportunity? existing}) async {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final deptCtrl =
        TextEditingController(text: existing?.department ?? 'Student Affairs');
    final hoursCtrl = TextEditingController(
      text: (existing?.estimatedHours ?? 2).toStringAsFixed(
        (existing?.estimatedHours ?? 2).truncateToDouble() ==
                (existing?.estimatedHours ?? 2)
            ? 0
            : 1,
      ),
    );
    final slotsCtrl =
        TextEditingController(text: '${existing?.slots ?? 10}');

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Announce opportunity' : 'Edit opportunity'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: deptCtrl,
                decoration: const InputDecoration(labelText: 'Department'),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: hoursCtrl,
                decoration: const InputDecoration(
                  labelText: 'Estimated hours per student',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: slotsCtrl,
                decoration: const InputDecoration(labelText: 'Open slots'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(existing == null ? 'Publish' : 'Save'),
          ),
        ],
      ),
    );

    if (saved != true || !mounted) return;

    final title = titleCtrl.text.trim();
    if (title.length < 3) {
      _snack('Title must be at least 3 characters.');
      return;
    }
    final hours = double.tryParse(hoursCtrl.text.trim());
    final slots = int.tryParse(slotsCtrl.text.trim());
    if (hours == null || hours < 0) {
      _snack('Enter valid estimated hours.');
      return;
    }
    if (slots == null || slots < 1) {
      _snack('Enter at least 1 slot.');
      return;
    }

    final state = context.read<AppState>();
    final ok = existing == null
        ? await state.createVolunteerOpportunity(
            title: title,
            description: descCtrl.text.trim(),
            department: deptCtrl.text.trim(),
            estimatedHours: hours,
            slots: slots,
          ) !=
            null
        : await state.updateVolunteerOpportunity(
            existing.id,
            title: title,
            description: descCtrl.text.trim(),
            department: deptCtrl.text.trim(),
            estimatedHours: hours,
            slots: slots,
          );

    if (!mounted) return;
    _snack(ok
        ? (existing == null
            ? 'Opportunity published — share the join link with students.'
            : 'Opportunity updated.')
        : 'Could not save. Check your connection and try again.');
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final opportunities = state.managedVolunteerOpportunities;
    final openCount = opportunities.where((o) => o.isOpen).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppGradients.campusPage),
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: () => context.read<AppState>().refreshVolunteerOpportunities(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
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
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    gradient: AppGradients.header,
                    borderRadius: BorderRadius.circular(AppRadii.xl),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Volunteer opportunities',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          StatChip(
                            icon: Icons.campaign_outlined,
                            label: '$openCount open',
                          ),
                          StatChip(
                            icon: Icons.list_alt_outlined,
                            label: '${opportunities.length} total',
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Publish service roles for students. Share the join link or '
                        'QR token so they can apply; Student Affairs approves hours.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                              height: 1.35,
                            ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 350.ms),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Your announcements',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    GlowIconButton(
                      icon: Icons.add_rounded,
                      tooltip: 'Announce opportunity',
                      onTap: () => _showForm(),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                if (opportunities.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: cardDecoration(),
                    child: Text(
                      'No opportunities yet. Tap + to announce one for students.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  )
                else
                  for (var i = 0; i < opportunities.length; i++) ...[
                    _OpportunityCard(
                      opportunity: opportunities[i],
                      onEdit: () => _showForm(existing: opportunities[i]),
                      onToggleStatus: () async {
                        final opp = opportunities[i];
                        final ok = opp.isOpen
                            ? await state.closeVolunteerOpportunity(opp.id)
                            : await state.reopenVolunteerOpportunity(opp.id);
                        if (!mounted) return;
                        _snack(ok
                            ? (opp.isOpen ? 'Opportunity closed.' : 'Opportunity reopened.')
                            : 'Update failed.');
                      },
                    )
                        .animate()
                        .fadeIn(delay: (40 * i).ms, duration: 280.ms)
                        .slideY(begin: 0.05, end: 0),
                    if (i != opportunities.length - 1)
                      const SizedBox(height: AppSpacing.md),
                  ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OpportunityCard extends StatelessWidget {
  final VolunteerOpportunity opportunity;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;

  const _OpportunityCard({
    required this.opportunity,
    required this.onEdit,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  opportunity.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: opportunity.isOpen
                      ? AppColors.success.withValues(alpha: 0.15)
                      : AppColors.textMuted.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: Text(
                  opportunity.isOpen ? 'Open' : 'Closed',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: opportunity.isOpen
                            ? AppColors.success
                            : AppColors.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${opportunity.department} · ${opportunity.estimatedHours}h · ${opportunity.slots} slots',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          if (opportunity.description.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              opportunity.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          if (opportunity.joinToken != null &&
              opportunity.joinToken!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            JoinLinkQrCard(
              title: 'Student join link',
              subtitle:
                  'Students scan this QR or open the link to apply for this opportunity.',
              link: VolunteerRequirements.joinLink(opportunity.joinToken!),
              copyLabel: 'Copy join link',
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onEdit,
                  child: const Text('Edit'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ElevatedButton(
                  onPressed: onToggleStatus,
                  style: opportunity.isOpen
                      ? ElevatedButton.styleFrom(backgroundColor: AppColors.danger)
                      : null,
                  child: Text(opportunity.isOpen ? 'Close' : 'Reopen'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
