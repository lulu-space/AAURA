import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/auth_flow_result.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/dawn_scene.dart';

/// Shown after sign-up when Supabase requires email confirmation before login.
class EmailConfirmationScreen extends StatelessWidget {
  final String email;

  const EmailConfirmationScreen({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.dawnTop,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DawnScene(reveal: 1.0),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      color: AppPalette.ink,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.mark_email_read_outlined,
                    size: 64,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Confirm your email',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: AppPalette.ink,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'We sent a confirmation link to',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: AppPalette.ink.withValues(alpha: 0.75),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    email,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: AppPalette.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Open the link in your inbox, then log in. '
                    'Your first login will take you to Shams to finish your profile.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: AppPalette.ink.withValues(alpha: 0.7),
                      fontSize: 13.5,
                      height: 1.45,
                    ),
                  ),
                  const Spacer(flex: 2),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                      context.read<AppState>().showAuthForm(
                            AuthFormMode.signIn,
                            initialEmail: email,
                          );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppPalette.ink,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('I confirmed — Log in'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextButton(
                    onPressed: () => Navigator.of(context).popUntil(
                      (route) => route.isFirst,
                    ),
                    child: Text(
                      'Back to welcome',
                      style: GoogleFonts.inter(color: AppPalette.ink),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
