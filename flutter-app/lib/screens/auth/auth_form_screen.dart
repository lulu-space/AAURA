import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/auth_flow_result.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/transitions.dart';
import '../../widgets/dawn_scene.dart';
import 'email_confirmation_screen.dart';

// Sunbird palette — bright teal sky with golden accents.
const Color _dawnTop = AppPalette.dawnTop;
const Color _dawnLow = AppPalette.dawnLow;
const Color _ink = AppPalette.ink;

const String _kBirdAsset = 'assets/images/aaura_bird_wave.png';

class AuthFormScreen extends StatefulWidget {
  final AuthFormMode mode;
  final String? initialEmail;

  const AuthFormScreen({
    super.key,
    required this.mode,
    this.initialEmail,
  });

  @override
  State<AuthFormScreen> createState() => _AuthFormScreenState();
}

class _AuthFormScreenState extends State<AuthFormScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _busy = false;
  String? _error;

  bool get _isSignUp => widget.mode == AuthFormMode.signUp;

  @override
  void initState() {
    super.initState();
    final seed = widget.initialEmail;
    if (seed != null && seed.isNotEmpty) {
      _email.text = seed;
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _busy = true);
    final appState = context.read<AppState>();

    if (_isSignUp) {
      final signup = await appState.signUp(
        email: _email.text,
        password: _password.text,
      );
      if (!mounted) return;
      setState(() => _busy = false);

      if (signup.isPendingEmail) {
        Navigator.of(context).push(
          FadeSlidePageRoute(
            builder: (_) => EmailConfirmationScreen(
              email: _email.text.trim(),
            ),
          ),
        );
        return;
      }
      if (!signup.isSuccess) {
        setState(() => _error = signup.message);
        return;
      }
      await appState.finalizeAuth();
      return;
    }

    final result = await appState.signIn(
      email: _email.text,
      password: _password.text,
    );

    if (!mounted) return;
    setState(() => _busy = false);

    if (result != null) {
      setState(() => _error = result);
      return;
    }

    await appState.finalizeAuth();
  }

  InputDecoration _fieldDecoration({
    required String label,
    String? hint,
    Widget? suffixIcon,
  }) {
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(color: color, width: width),
        );
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.45),
      labelStyle: GoogleFonts.inter(color: _ink.withValues(alpha: 0.7)),
      hintStyle: GoogleFonts.inter(color: _ink.withValues(alpha: 0.4)),
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _dawnTop,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: _ink,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            color: _ink,
            onPressed:
                _busy ? null : () => context.read<AppState>().clearAuthForm(),
          ),
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            const DawnScene(reveal: 1.0),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      AppSpacing.sm,
                      AppSpacing.xl,
                      AppSpacing.xl,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Align(
                        alignment: const Alignment(0, -0.35),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              _isSignUp ? 'Create account' : 'Welcome back',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                color: _ink,
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ).animate().fadeIn(duration: 500.ms),
                            const SizedBox(height: 8),
                            Text(
                              _isSignUp
                                  ? 'Sign up with your AAUP campus email.'
                                  : 'Sign in with your AAUP campus email.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                color: _ink.withValues(alpha: 0.7),
                                fontSize: 13.5,
                                height: 1.4,
                                fontWeight: FontWeight.w300,
                                letterSpacing: 0.3,
                              ),
                            ).animate().fadeIn(delay: 100.ms, duration: 500.ms),
                            const SizedBox(height: AppSpacing.md),
                            _BirdAndForm(
                              formKey: _formKey,
                              email: _email,
                              password: _password,
                              obscure: _obscurePassword,
                              busy: _busy,
                              error: _error,
                              isSignUp: _isSignUp,
                              onToggleObscure: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              onSubmit: _busy ? null : _submit,
                              decoration: _fieldDecoration,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The waving bird tucked behind the frosted form card.
class _BirdAndForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController email;
  final TextEditingController password;
  final bool obscure;
  final bool busy;
  final String? error;
  final bool isSignUp;
  final VoidCallback onToggleObscure;
  final VoidCallback? onSubmit;
  final InputDecoration Function({
    required String label,
    String? hint,
    Widget? suffixIcon,
  }) decoration;

  const _BirdAndForm({
    required this.formKey,
    required this.email,
    required this.password,
    required this.obscure,
    required this.busy,
    required this.error,
    required this.isSignUp,
    required this.onToggleObscure,
    required this.onSubmit,
    required this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    const birdSize = 116.0;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Bird peeks out from behind the card's top-right corner (painted
        // first = sits behind the fields).
        Positioned(
          top: -birdSize * 0.42,
          right: -birdSize * 0.06,
          child: const _PeekingBird(size: birdSize),
        ),
        Padding(
          padding: const EdgeInsets.only(top: birdSize * 0.30),
          child: ClipRRect(
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
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.55)),
                  boxShadow: [
                    BoxShadow(
                      color: _dawnLow.withValues(alpha: 0.20),
                      blurRadius: 30,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Form(
                  key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    style: GoogleFonts.inter(color: _ink),
                    decoration: decoration(
                      label: 'Email',
                      hint: 'you@student.aaup.edu',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email is required';
                      }
                      if (!value.contains('@')) {
                        return 'Enter a valid email address';
                      }
                      return null;
                    },
                  )
                      .animate()
                      .fadeIn(delay: 320.ms, duration: 450.ms)
                      .slideY(begin: 0.3, end: 0, curve: Curves.easeOut),
                  const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    controller: password,
                    obscureText: obscure,
                    textInputAction: TextInputAction.done,
                    style: GoogleFonts.inter(color: _ink),
                    onFieldSubmitted: (_) {
                      if (onSubmit != null) onSubmit!();
                    },
                    decoration: decoration(
                      label: 'Password',
                      suffixIcon: IconButton(
                        color: _ink.withValues(alpha: 0.6),
                        icon: Icon(
                          obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: onToggleObscure,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password is required';
                      }
                      return null;
                    },
                  )
                      .animate()
                      .fadeIn(delay: 440.ms, duration: 450.ms)
                      .slideY(begin: 0.3, end: 0, curve: Curves.easeOut),
                  if (error != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      error!,
                      style: GoogleFonts.inter(
                        color: AppColors.danger,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _ink,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: busy
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(isSignUp ? 'Sign up' : 'Log in'),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 560.ms, duration: 450.ms)
                      .slideY(begin: 0.3, end: 0, curve: Curves.easeOut),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Static bird mascot that peeks from behind the card corner.
class _PeekingBird extends StatelessWidget {
  final double size;
  const _PeekingBird({required this.size});

  @override
  Widget build(BuildContext context) {
    final bird = Image.asset(
      _kBirdAsset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => _BirdFallback(size: size),
    )
        .animate()
        .fadeIn(duration: 600.ms)
        .slideX(begin: 0.3, end: 0, duration: 600.ms, curve: Curves.easeOut);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: bird),
          Positioned(
            left: size * 0.05,
            top: size * 0.16,
            child: _Sparkle(size: size * 0.11, period: 1600.ms),
          ),
          Positioned(
            right: size * 0.08,
            top: size * 0.40,
            child: _Sparkle(
                size: size * 0.075, delay: 520.ms, period: 1900.ms),
          ),
          Positioned(
            left: size * 0.24,
            bottom: size * 0.18,
            child: _Sparkle(
                size: size * 0.06, delay: 980.ms, period: 1500.ms),
          ),
        ],
      ),
    );
  }
}

/// A small twinkling sparkle that gently pulses in scale and opacity.
class _Sparkle extends StatelessWidget {
  final double size;
  final Duration delay;
  final Duration period;
  const _Sparkle({
    required this.size,
    this.delay = Duration.zero,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.auto_awesome,
      size: size,
      color: const Color(0xFFFFF3D6),
      shadows: const [
        Shadow(color: Color(0x99FFE6A8), blurRadius: 8),
      ],
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .fadeIn(delay: delay, duration: period, curve: Curves.easeInOut)
        .scaleXY(
          begin: 0.55,
          end: 1.0,
          duration: period,
          curve: Curves.easeInOut,
        );
  }
}

/// Painted stand-in used until the bird PNG is bundled into assets/images/.
class _BirdFallback extends StatelessWidget {
  final double size;
  const _BirdFallback({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _BirdFallbackPainter()),
    );
  }
}

class _BirdFallbackPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final bodyColor = Paint()..color = const Color(0xFF6A2FE0);
    final belly = Paint()..color = const Color(0xFFCBB6EE);
    // Body.
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.62), width: w * 0.62, height: h * 0.66),
      bodyColor,
    );
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.72), width: w * 0.42, height: h * 0.4),
      belly,
    );
    // Head.
    canvas.drawCircle(Offset(w * 0.5, h * 0.34), w * 0.26, bodyColor);
    // Eyes.
    final white = Paint()..color = Colors.white;
    final pupil = Paint()..color = const Color(0xFF231039);
    for (final dx in [-0.09, 0.09]) {
      final c = Offset(w * (0.5 + dx), h * 0.34);
      canvas.drawCircle(c, w * 0.07, white);
      canvas.drawCircle(c, w * 0.04, pupil);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
