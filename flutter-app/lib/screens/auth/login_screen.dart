import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/auth_flow_result.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/dawn_scene.dart';

const Color _skyDeep = AppPalette.nightDeep;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  AuthFormMode? _pendingMode;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _goToForm();
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _select(AuthFormMode mode) {
    if (_controller.isAnimating || _pendingMode != null) return;
    setState(() => _pendingMode = mode);
    _controller.forward();
  }

  void _goToForm() {
    if (_navigated || _pendingMode == null) return;
    _navigated = true;
    context.read<AppState>().showAuthForm(_pendingMode!);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _skyDeep,
        body: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value;
            // Brand + buttons fade out across the back half of the sequence.
            final contentFade = (1.0 -
                    Curves.easeIn.transform(
                      ((t - 0.35) / 0.45).clamp(0.0, 1.0),
                    ))
                .clamp(0.0, 1.0);
            return Stack(
              fit: StackFit.expand,
              children: [
                DawnScene(reveal: t),
                Opacity(
                  opacity: (1.0 - t).clamp(0.0, 1.0),
                  child: const _BottomScrim(),
                ),
                SafeArea(
                  child: Opacity(
                    opacity: contentFade,
                    child: IgnorePointer(
                      ignoring: _pendingMode != null,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                          vertical: AppSpacing.lg,
                        ),
                        child: Column(
                          children: [
                            const Spacer(flex: 6),
                            _BrandBlock(),
                            const Spacer(flex: 2),
                            _AuthButtons(onSelected: _select),
                            const SizedBox(height: AppSpacing.sm),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BottomScrim extends StatelessWidget {
  const _BottomScrim();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.center,
            end: Alignment.bottomCenter,
            colors: [
              Color(0x00160A29),
              Color(0xCC160A29),
              _skyDeep,
            ],
            stops: [0.0, 0.62, 1.0],
          ),
        ),
      ),
    );
  }
}

class _BrandBlock extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'WELCOME TO',
          style: GoogleFonts.inter(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 11,
            fontWeight: FontWeight.w400,
            letterSpacing: 5,
          ),
        ).animate().fadeIn(delay: 200.ms, duration: 600.ms),
        const SizedBox(height: 10),
        Text(
          'AAURA',
          style: GoogleFonts.cinzel(
            color: Colors.white,
            fontSize: 52,
            fontWeight: FontWeight.w700,
            letterSpacing: 10,
            height: 1.0,
            shadows: [
              Shadow(
                color: Colors.white.withValues(alpha: 0.55),
                blurRadius: 22,
              ),
              Shadow(
                color: AppColors.magenta.withValues(alpha: 0.50),
                blurRadius: 48,
              ),
              Shadow(
                color: AppColors.accent.withValues(alpha: 0.30),
                blurRadius: 72,
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(delay: 300.ms, duration: 800.ms)
            .slideY(begin: 0.18, end: 0, curve: Curves.easeOut),
        const SizedBox(height: 14),
        Text(
          'Belong. Engage. Grow.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: Colors.white.withValues(alpha: 0.80),
            fontSize: 14,
            height: 1.5,
            letterSpacing: 2.0,
            fontWeight: FontWeight.w300,
          ),
        ).animate().fadeIn(delay: 520.ms, duration: 700.ms),
      ],
    );
  }
}

class _AuthButtons extends StatelessWidget {
  final ValueChanged<AuthFormMode> onSelected;
  const _AuthButtons({required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PillButton(
          label: 'Sign up',
          alpha: 0.22,
          onTap: () => onSelected(AuthFormMode.signUp),
        )
            .animate()
            .fadeIn(delay: 700.ms, duration: 600.ms)
            .slideY(begin: 0.25, end: 0, curve: Curves.easeOut),
        const SizedBox(height: AppSpacing.sm),
        _PillButton(
          label: 'Log in',
          alpha: 0.12,
          onTap: () => onSelected(AuthFormMode.signIn),
        )
            .animate()
            .fadeIn(delay: 820.ms, duration: 600.ms)
            .slideY(begin: 0.25, end: 0, curve: Curves.easeOut),
      ],
    );
  }
}

/// Single frosted-glass pill button â€” no border, transparent fill, thin font.
class _PillButton extends StatelessWidget {
  final String label;
  final double alpha;
  final VoidCallback onTap;
  const _PillButton({
    required this.label,
    required this.alpha,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: alpha),
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.pill),
        splashColor: Colors.white.withValues(alpha: 0.08),
        highlightColor: Colors.white.withValues(alpha: 0.05),
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 17),
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w300,
              letterSpacing: 3.0,
            ),
          ),
        ),
      ),
    );
  }
}
