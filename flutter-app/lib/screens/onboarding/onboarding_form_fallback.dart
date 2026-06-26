import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../data/campus_form_options.dart';
import '../../models/user_profile.dart';
import '../../models/user_role.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/transitions.dart';
import '../../widgets/bird_avatar.dart';
import '../../widgets/dawn_scene.dart';
import '../shell/main_shell.dart';

// Dawn palette — matches the auth/chat dreamy sunrise.
const Color _dawnLow = Color(0xFF854F6C);
const Color _ink = Color(0xFF3D2350);

class OnboardingFormFallback extends StatefulWidget {
  final bool isProfileUpdate;
  const OnboardingFormFallback({super.key, this.isProfileUpdate = false});

  @override
  State<OnboardingFormFallback> createState() => _OnboardingFormFallbackState();
}

class _OnboardingFormFallbackState extends State<OnboardingFormFallback> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _id = TextEditingController();
  final _careerGoal = TextEditingController();
  final _skills = TextEditingController();
  final _otherInterests = TextEditingController();
  final _bio = TextEditingController();
  String _major = CampusFormOptions.majors.first;
  String _year = CampusFormOptions.years.first;
  String? _gender;
  String? _campus;
  String? _gradYear = CampusFormOptions.graduationYears.first;
  DateTime? _dob;
  final Set<String> _selectedInterests = {};
  bool _prefilled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_prefilled || !widget.isProfileUpdate) return;
    final profile = context.read<AppState>().profile;
    if (profile == null) return;
    _prefilled = true;
    _name.text = profile.name;
    _id.text = profile.studentId;
    if (CampusFormOptions.majors.contains(profile.major)) {
      _major = profile.major;
    }
    if (CampusFormOptions.years.contains(profile.year)) {
      _year = profile.year;
    }
    _selectedInterests.addAll(profile.interests);
    if (profile.bio != null) _bio.text = profile.bio!;
    if (profile.skills.isNotEmpty) _skills.text = profile.skills.join(', ');
    if (profile.careerGoal != null) _careerGoal.text = profile.careerGoal!;
    _gender = profile.gender;
    _campus = profile.campus;
    _gradYear = profile.expectedGraduation;
    if (profile.dateOfBirth != null) {
      _dob = DateTime.tryParse(profile.dateOfBirth!);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _id.dispose();
    _careerGoal.dispose();
    _skills.dispose();
    _otherInterests.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedInterests.isEmpty && _otherInterests.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pick at least one interest or add your own below'),
        ),
      );
      return;
    }

    final extraInterests = _splitList(_otherInterests.text);
    final skills = _splitList(_skills.text);

    final profile = UserProfile(
      name: _name.text.trim(),
      studentId: _id.text.trim(),
      major: _major,
      year: _year,
      interests: [..._selectedInterests, ...extraInterests],
      quickTitle: widget.isProfileUpdate
          ? (context.read<AppState>().profile?.quickTitle ?? 'Student')
          : 'New Student',
      email: widget.isProfileUpdate
          ? (context.read<AppState>().profile?.email ??
              '${_id.text.trim()}@student.aaup.edu')
          : '${_id.text.trim()}@student.aaup.edu',
      role: context.read<AppState>().profile?.role ?? UserRole.student,
      gender: _gender,
      dateOfBirth: _dob == null ? null : _formatDate(_dob!),
      campus: _campus,
      expectedGraduation: _gradYear,
      careerGoal:
          _careerGoal.text.trim().isEmpty ? null : _careerGoal.text.trim(),
      skills: skills,
      bio: _bio.text.trim().isEmpty ? null : _bio.text.trim(),
    );

    if (widget.isProfileUpdate) {
      await context.read<AppState>().saveManualProfileUpdate(profile);
      if (!mounted) return;
      Navigator.of(context).pop(true);
      return;
    }

    await context.read<AppState>().completeOnboarding(profile);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      FadeSlidePageRoute(builder: (_) => const MainShell()),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  List<String> _splitList(String raw) =>
      raw
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final earliest = DateTime(1998, 1, 1);
    final latest = DateTime(now.year - 16, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(2006, 6, 15),
      firstDate: earliest,
      lastDate: latest,
      initialDatePickerMode: DatePickerMode.year,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _ink,
              onPrimary: Colors.white,
              surface: Color(0xFFFBE4D8),
              onSurface: _ink,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _dob = picked);
  }

  InputDecoration _fieldDecoration({String? hint, Widget? suffixIcon}) {
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(color: color, width: width),
        );
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.45),
      hintStyle: TextStyle(color: _ink.withValues(alpha: 0.4)),
      suffixIcon: suffixIcon,
      enabledBorder: border(_dawnLow.withValues(alpha: 0.35), 1.2),
      border: border(_dawnLow.withValues(alpha: 0.35), 1.2),
      focusedBorder: border(_ink, 1.6),
      errorBorder: border(AppColors.danger, 1.4),
      focusedErrorBorder: border(AppColors.danger, 1.6),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: _ink,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            color: _ink,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            const DawnScene(reveal: 1.0),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        widget.isProfileUpdate ? 'Update manually' : 'Set up manually',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: _ink,
                        ),
                      ).animate().fadeIn(duration: 400.ms),
                      const SizedBox(height: 6),
                      Text(
                        widget.isProfileUpdate
                            ? 'Edit your details directly — same form as onboarding.'
                            : "Prefer the fast lane? Fill these out and you're in.",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: _ink.withValues(alpha: 0.7),
                        ),
                      ).animate().fadeIn(delay: 80.ms, duration: 400.ms),
                      const SizedBox(height: AppSpacing.lg),
                      _GlassCard(child: _buildForm(theme)),
                      const SizedBox(height: AppSpacing.xxl),
                    ],
                  ),
                ),
              ),
            ),
            // Mascot peeking up from the bottom-left corner.
            Positioned(
              left: -22,
              bottom: -14,
              child: IgnorePointer(
                child: const BirdSticker(size: 138)
                    .animate()
                    .fadeIn(delay: 250.ms, duration: 600.ms)
                    .slideX(begin: -0.4, end: 0, curve: Curves.easeOut),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(ThemeData theme) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _label('Name'),
          TextFormField(
            controller: _name,
            style: const TextStyle(color: _ink),
            decoration: _fieldDecoration(hint: 'Full name'),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: AppSpacing.md),
          _label('Student ID'),
          TextFormField(
            controller: _id,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: _ink),
            decoration: _fieldDecoration(hint: 'e.g. 202113465'),
            validator: (v) =>
                (v == null || v.trim().length < 6) ? 'Enter a valid ID' : null,
          ),
          const SizedBox(height: AppSpacing.md),
          _label('Major'),
          _dropdown(
            value: _major,
            items: CampusFormOptions.majors,
            onChanged: (v) => setState(() => _major = v ?? _major),
          ),
          const SizedBox(height: AppSpacing.md),
          _label('Year'),
          _dropdown(
            value: _year,
            items: CampusFormOptions.years,
            onChanged: (v) => setState(() => _year = v ?? _year),
          ),
          const SizedBox(height: AppSpacing.lg),
          _label('Interests'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final interest in CampusFormOptions.interestOptions)
                _interestChip(interest),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _label('Other interests'),
          TextFormField(
            controller: _otherInterests,
            style: const TextStyle(color: _ink),
            decoration: _fieldDecoration(
              hint: 'Comma-separated, e.g. Robotics, Debate',
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _SectionDivider(),
          const SizedBox(height: AppSpacing.md),
          Text(
            'A bit more about you',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: _ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Optional — but it helps Shams tailor things to you.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: _ink.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _label('Gender'),
          _dropdown(
            value: _gender,
            hint: 'Select',
            items: CampusFormOptions.genderOptions,
            onChanged: (v) => setState(() => _gender = v),
          ),
          const SizedBox(height: AppSpacing.md),
          _label('Date of birth'),
          InkWell(
            onTap: _pickDob,
            borderRadius: BorderRadius.circular(AppRadii.md),
            child: InputDecorator(
              decoration: _fieldDecoration(
                suffixIcon: Icon(
                  Icons.calendar_today_outlined,
                  size: 18,
                  color: _ink.withValues(alpha: 0.6),
                ),
              ),
              child: Text(
                _dob == null ? 'Select your birth date' : _formatDate(_dob!),
                style: TextStyle(
                  color: _dob == null ? _ink.withValues(alpha: 0.4) : _ink,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _label('Campus'),
          _dropdown(
            value: _campus,
            hint: 'Select',
            items: CampusFormOptions.campuses,
            onChanged: (v) => setState(() => _campus = v),
          ),
          const SizedBox(height: AppSpacing.md),
          _label('Expected graduation'),
          _dropdown(
            value: _gradYear,
            hint: 'Select',
            items: CampusFormOptions.graduationYears,
            onChanged: (v) => setState(() => _gradYear = v),
          ),
          const SizedBox(height: AppSpacing.md),
          _label('Career goal'),
          TextFormField(
            controller: _careerGoal,
            style: const TextStyle(color: _ink),
            decoration: _fieldDecoration(hint: 'e.g. Backend engineer'),
          ),
          const SizedBox(height: AppSpacing.md),
          _label('Skills'),
          TextFormField(
            controller: _skills,
            style: const TextStyle(color: _ink),
            decoration: _fieldDecoration(
              hint: 'Comma-separated, e.g. Python, Web development, Design',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _label('Short bio'),
          TextFormField(
            controller: _bio,
            minLines: 2,
            maxLines: 4,
            style: const TextStyle(color: _ink),
            decoration: _fieldDecoration(hint: 'Tell us a little about you...'),
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _ink,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('CONTINUE'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdown({
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String? hint,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      dropdownColor: const Color(0xFFFBE4D8),
      style: const TextStyle(color: _ink, fontSize: 15),
      iconEnabledColor: _ink,
      hint: hint == null
          ? null
          : Text(hint, style: TextStyle(color: _ink.withValues(alpha: 0.4))),
      decoration: _fieldDecoration(),
      items: [
        for (final item in items)
          DropdownMenuItem(value: item, child: Text(item)),
      ],
      onChanged: onChanged,
    );
  }

  Widget _interestChip(String interest) {
    final selected = _selectedInterests.contains(interest);
    return FilterChip(
      label: Text(interest),
      selected: selected,
      onSelected: (sel) {
        setState(() {
          if (sel) {
            _selectedInterests.add(interest);
          } else {
            _selectedInterests.remove(interest);
          }
        });
      },
      selectedColor: _ink,
      checkmarkColor: Colors.white,
      elevation: 0,
      pressElevation: 0,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      labelStyle: TextStyle(
        color: selected ? Colors.white : _ink,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: const Color(0xFFFBE4D8).withValues(alpha: 0.55),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.pill),
        side: BorderSide(
          color: selected ? _ink : _dawnLow.withValues(alpha: 0.45),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: _ink.withValues(alpha: 0.8),
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

/// Frosted-glass card matching the auth screen's form container.
class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.xl),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.30),
            borderRadius: BorderRadius.circular(AppRadii.xl),
            border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
            boxShadow: [
              BoxShadow(
                color: _dawnLow.withValues(alpha: 0.20),
                blurRadius: 30,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      color: _ink.withValues(alpha: 0.15),
      thickness: 1,
      height: 1,
    );
  }
}
