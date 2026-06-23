import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../data/campus_form_options.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bird_avatar.dart';
import '../../widgets/dawn_scene.dart';

const Color _dawnLow = Color(0xFF854F6C);
const Color _ink = Color(0xFF3D2350);

/// A small, dreamy Shams chat that lets a student refresh their interests.
/// Mirrors the onboarding chat look (DawnScene + glass bubbles) but is
/// focused on a single task and writes straight back to the profile.
class ShamsUpdateChatScreen extends StatefulWidget {
  const ShamsUpdateChatScreen({super.key});

  @override
  State<ShamsUpdateChatScreen> createState() => _ShamsUpdateChatScreenState();
}

class _ShamsUpdateChatScreenState extends State<ShamsUpdateChatScreen> {
  late final Set<String> _selected;
  final _otherInterests = TextEditingController();
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    final current = context.read<AppState>().profile?.interests ?? const [];
    _selected = {...current};
  }

  @override
  void dispose() {
    _otherInterests.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final state = context.read<AppState>();
    final profile = state.profile;
    if (profile == null) return;
    final extras = _otherInterests.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty);
    await state.updateInterests([..._selected, ...extras]);
    if (!mounted) return;
    setState(() => _saved = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Interests updated!')),
    );
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final firstName =
        (context.watch<AppState>().profile?.name ?? 'there').split(' ').first;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DawnScene(reveal: 1.0),
          SafeArea(
            child: Column(
              children: [
                _Header(onClose: () => Navigator.of(context).pop()),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg,
                        AppSpacing.lg, AppSpacing.lg, AppSpacing.md),
                    children: [
                      _Bubble(
                        text:
                            "Hi $firstName! Want to refresh what you're into? "
                            "I'll use it to suggest better events and clubs.",
                      ),
                      const _Bubble(
                        text:
                            'Tap the chips below to add or remove interests, then hit Save.',
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _InterestPicker(
                        selected: _selected,
                        onToggle: (v) => setState(() {
                          if (!_selected.add(v)) _selected.remove(v);
                        }),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: _otherInterests,
                        decoration: const InputDecoration(
                          labelText: 'Other interests',
                          hintText: 'Comma-separated, e.g. Robotics, Debate',
                        ),
                      ),
                      if (_saved)
                        const _Bubble(
                          text: "Lovely - your interests are updated. ✨",
                        ),
                    ],
                  ),
                ),
                _SaveBar(
                  count: _selected.length +
                      _otherInterests.text
                          .split(',')
                          .where((s) => s.trim().isNotEmpty)
                          .length,
                  onSave: (_selected.isEmpty &&
                          _otherInterests.text.trim().isEmpty)
                      ? null
                      : _save,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onClose;
  const _Header({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
      child: Row(
        children: [
          const BirdAvatar(size: 44)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(begin: 1, end: 1.06, duration: 1600.ms),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Shams',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: _ink,
                        )),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('Update your interests',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: _ink.withValues(alpha: 0.7))),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            style: IconButton.styleFrom(foregroundColor: _ink),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final String text;
  const _Bubble({required this.text});

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.only(
      topLeft: Radius.circular(AppRadii.lg),
      topRight: Radius.circular(AppRadii.lg),
      bottomLeft: Radius.circular(4),
      bottomRight: Radius.circular(AppRadii.lg),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Padding(
            padding: EdgeInsets.only(right: 8),
            child: BirdAvatar(size: 28),
          ),
          Flexible(
            child: ClipRRect(
              borderRadius: radius,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 320),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.34),
                    borderRadius: radius,
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.55)),
                    boxShadow: [
                      BoxShadow(
                        color: _dawnLow.withValues(alpha: 0.18),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Text(
                    text,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: _ink,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
              ),
            ),
          ),
        ],
      )
          .animate()
          .fadeIn(duration: 220.ms)
          .slideY(begin: 0.2, end: 0, duration: 240.ms, curve: Curves.easeOut),
    );
  }
}

class _InterestPicker extends StatelessWidget {
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  const _InterestPicker({required this.selected, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.30),
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final o in CampusFormOptions.interestOptions)
                FilterChip(
                  label: Text(o),
                  selected: selected.contains(o),
                  onSelected: (_) => onToggle(o),
                  selectedColor: _ink,
                  elevation: 0,
                  pressElevation: 0,
                  surfaceTintColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  showCheckmark: false,
                  labelStyle: TextStyle(
                    color: selected.contains(o) ? Colors.white : _ink,
                    fontWeight: FontWeight.w600,
                  ),
                  backgroundColor:
                      const Color(0xFFFBE4D8).withValues(alpha: 0.55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                    side: BorderSide(
                      color: selected.contains(o)
                          ? _ink
                          : _dawnLow.withValues(alpha: 0.45),
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

class _SaveBar extends StatelessWidget {
  final int count;
  final VoidCallback? onSave;
  const _SaveBar({required this.count, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.28),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.45)),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
              child: SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _ink,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.check_rounded),
                  label: Text('Save $count interest${count == 1 ? '' : 's'}'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
