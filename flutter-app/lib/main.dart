import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/app_config.dart';
import 'core/network/api_client.dart';
import 'data/repositories/profiling_repository.dart';
import 'screens/auth/auth_form_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/onboarding/onboarding_chat_screen.dart';
import 'screens/shell/main_shell.dart';
import 'services/shams_backend_bot.dart';
import 'services/shams_bot.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';
import 'widgets/mobile_viewport.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
  } catch (error) {
    debugPrint('Supabase init failed (mock fallback): $error');
  }

  runApp(const AauraApp());
}

class AauraApp extends StatelessWidget {
  const AauraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()..load()),
        Provider<OnboardingBot>(
          create: (_) {
            if (AppConfig.backendEnabled) {
              return ShamsBackendBot(ProfilingRepository(ApiClient()));
            }
            return ShamsScriptedBot();
          },
        ),
      ],
      child: MaterialApp(
        title: 'AAURA',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        themeMode: ThemeMode.light,
        builder: (context, child) {
          return MobileViewport(child: child ?? const SizedBox.shrink());
        },
        home: const _Bootstrap(),
      ),
    );
  }
}

class _Bootstrap extends StatelessWidget {
  const _Bootstrap();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (!state.loaded) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }
    if (!state.authenticated) {
      final mode = state.pendingAuthForm;
      if (mode != null) {
        return AuthFormScreen(
          mode: mode,
          initialEmail: state.authFormInitialEmail,
        );
      }
      return const LoginScreen();
    }
    if (state.needsOnboarding) {
      return const OnboardingChatScreen();
    }
    return const MainShell();
  }
}
