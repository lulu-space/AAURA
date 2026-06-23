import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glow_widgets.dart';
import '../../widgets/section_header.dart';

class CareerReadinessScreen extends StatelessWidget {
  const CareerReadinessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final profile = state.profile;
    final attended = state.attendedEventsSorted();
    final pinned = attended
        .where((a) => state.isCvPinned(a.event.id))
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Career Readiness')),
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppGradients.campusPage),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.accent],
                ),
                borderRadius: BorderRadius.circular(AppRadii.lg),
                boxShadow: glow(AppColors.primary,
                    alpha: 0.25, blurRadius: 22, offset: const Offset(0, 12)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white,
                    child: Text(
                      (profile?.name.isNotEmpty == true
                          ? profile!.name[0]
                          : '?'),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 26,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(profile?.name ?? 'Student',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                )),
                        Text(
                          '${profile?.major ?? ''} · ${profile?.year ?? ''}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                        ),
                        Text(
                          profile?.email ?? '',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.85),
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _MetricsRow(
              attendedCount: attended.length,
              volunteerHours: state.volunteerHours,
              badgesCount: state.earnedBadgeIds.length,
            ),
            const SizedBox(height: AppSpacing.md),
            const SectionHeader(
                title: 'My CV / Resume', padding: EdgeInsets.zero),
            const _CvCard(),
            const SizedBox(height: AppSpacing.md),
            const SectionHeader(title: 'Skills', padding: EdgeInsets.zero),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: cardDecoration(),
              child: Column(
                children: [
                  for (var i = 0; i < state.skillProgress.length; i++) ...[
                    Row(
                      children: [
                        GlowRing(
                          progress:
                              (state.skillProgress[i]['progress'] as num).toDouble(),
                          size: 52,
                          strokeWidth: 6,
                          color: AppAccents.at(i),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(state.skillProgress[i]['name'] as String,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    if (i != state.skillProgress.length - 1)
                      const SizedBox(height: AppSpacing.md),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const SectionHeader(title: 'Experience', padding: EdgeInsets.zero),
            if (pinned.isEmpty)
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: cardDecoration(),
                child: Text(
                  'Pin attended events from your event history to feature them here.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: cardDecoration(),
                child: Column(
                  children: [
                    for (var i = 0; i < pinned.length; i++) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Icon(Icons.bookmark_rounded,
                                color: AppAccents.at(i), size: 18),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(pinned[i].event.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                            fontWeight: FontWeight.w800)),
                                Text(
                                    '${pinned[i].event.organizer} · ${pinned[i].event.duration}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                            color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                          Text('${pinned[i].event.points} pts',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    color: AppAccents.at(i),
                                    fontWeight: FontWeight.w800,
                                  )),
                        ],
                      ),
                      if (i != pinned.length - 1)
                        const Divider(height: AppSpacing.lg),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            const SectionHeader(title: 'Interests', padding: EdgeInsets.zero),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: cardDecoration(),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0;
                      i < (profile?.interests ?? const []).length;
                      i++)
                    _InterestPill(
                      label: profile!.interests[i],
                      accent: AppAccents.at(i),
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

class _CvCard extends StatefulWidget {
  const _CvCard();

  @override
  State<_CvCard> createState() => _CvCardState();
}

class _CvCardState extends State<_CvCard> {
  Future<void> _pickAndUpload() async {
    final state = context.read<AppState>();
    final messenger = ScaffoldMessenger.of(context);
    if (!state.useBackendData) {
      messenger.showSnackBar(const SnackBar(
        content: Text('Sign in to upload your CV.'),
      ));
      return;
    }
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null) {
      messenger.showSnackBar(const SnackBar(
        content: Text('Could not read that file. Try another PDF.'),
      ));
      return;
    }
    final ok = await state.uploadCv(bytes, file.name);
    messenger.showSnackBar(SnackBar(
      content: Text(ok
          ? 'CV uploaded successfully.'
          : 'Upload failed. Make sure the cvs storage bucket exists (migration 0013).'),
    ));
  }

  Future<void> _openCv(String url) async {
    final messenger = ScaffoldMessenger.of(context);
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      messenger.showSnackBar(const SnackBar(
        content: Text('Could not open the CV link.'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final hasCv = state.hasCv;
    final uploading = state.cvUploading;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.accentLight,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: const Icon(Icons.description_outlined,
                    color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasCv ? (state.cvFileName ?? 'cv.pdf') : 'No CV uploaded',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      hasCv
                          ? 'Tap View to open your uploaded PDF.'
                          : 'Upload a PDF CV to attach to your profile.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              if (hasCv)
                const Icon(Icons.check_circle, color: AppColors.success),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: uploading ? null : _pickAndUpload,
                  icon: uploading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.upload_file_outlined),
                  label: Text(hasCv ? 'Replace' : 'Upload CV'),
                ),
              ),
              if (hasCv) ...[
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openCv(state.cvUrl!),
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('View'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _InterestPill extends StatelessWidget {
  final String label;
  final Color accent;
  const _InterestPill({required this.label, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: accent.withValues(alpha: 0.30)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: accent,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _MetricsRow extends StatelessWidget {
  final int attendedCount;
  final int volunteerHours;
  final int badgesCount;
  const _MetricsRow({
    required this.attendedCount,
    required this.volunteerHours,
    required this.badgesCount,
  });

  @override
  Widget build(BuildContext context) {
    Widget metric(IconData icon, String value, String label, Color color) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: cardDecoration(),
          child: Column(
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 6),
              Text(value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: color,
                      )),
              Text(label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                      )),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        metric(Icons.event_available, '$attendedCount', 'Events',
            AppAccents.at(0)),
        metric(Icons.volunteer_activism_outlined, '${volunteerHours}h',
            'Service', AppAccents.at(2)),
        metric(Icons.workspace_premium_outlined, '$badgesCount', 'Badges',
            AppAccents.at(1)),
      ],
    );
  }
}
