import 'package:supabase_flutter/supabase_flutter.dart';

class AuthOutcome {
  const AuthOutcome._({
    required this.success,
    this.error,
    this.needsEmailConfirmation = false,
  });

  const AuthOutcome.ok() : this._(success: true);
  const AuthOutcome.failed(String message)
      : this._(success: false, error: message);
  const AuthOutcome.needsConfirmation()
      : this._(success: false, needsEmailConfirmation: true);

  final bool success;
  final String? error;
  final bool needsEmailConfirmation;
}

/// Supabase Auth wrapper. The backend trusts the Supabase JWT — this service
/// handles sign-in/up/out; [ApiClient] attaches the resulting token.
class AuthService {
  SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  bool get isReady => _client != null;
  Session? get currentSession => _client?.auth.currentSession;
  User? get currentUser => _client?.auth.currentUser;
  bool get isSignedIn => currentSession != null;

  Future<AuthOutcome> signIn({
    required String email,
    required String password,
  }) async {
    final client = _client;
    if (client == null) {
      return const AuthOutcome.failed('Auth is unavailable.');
    }

    Object? lastError;
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final res = await client.auth
            .signInWithPassword(email: email.trim(), password: password);
        if (res.session == null) {
          return const AuthOutcome.failed('Invalid email or password.');
        }
        return const AuthOutcome.ok();
      } on AuthException catch (e) {
        return AuthOutcome.failed(e.message);
      } catch (e) {
        lastError = e;
        if (attempt == 0 && _isTransientNetworkError(e)) {
          await Future<void>.delayed(const Duration(seconds: 2));
          continue;
        }
        return AuthOutcome.failed(_friendlyError(e, action: 'sign in'));
      }
    }

    return AuthOutcome.failed(
      _friendlyError(lastError ?? 'Unknown error', action: 'sign in'),
    );
  }

  Future<AuthOutcome> signUp({
    required String email,
    required String password,
  }) async {
    final client = _client;
    if (client == null) {
      return const AuthOutcome.failed('Auth is unavailable.');
    }
    try {
      final trimmed = email.trim();
      final res = await client.auth.signUp(
        email: trimmed,
        password: password,
      );

      if (_isExistingAccountSignUp(res)) {
        return const AuthOutcome.failed('Account already exists');
      }

      if (res.session != null) {
        return const AuthOutcome.ok();
      }

      // Supabase often omits the session on signUp even when confirm-email is
      // off — try an immediate sign-in before asking the user to check email.
      try {
        final signIn = await client.auth.signInWithPassword(
          email: trimmed,
          password: password,
        );
        if (signIn.session != null) {
          return const AuthOutcome.ok();
        }
      } on AuthException {
        // Fall through to needs-confirmation below.
      }

      if (res.user != null) {
        return const AuthOutcome.needsConfirmation();
      }
      return const AuthOutcome.failed('Sign up failed. Please try again.');
    } on AuthException catch (e) {
      if (_isExistingAccountMessage(e.message)) {
        return const AuthOutcome.failed('Account already exists');
      }
      return AuthOutcome.failed(e.message);
    } catch (e) {
      return AuthOutcome.failed(_friendlyError(e, action: 'sign up'));
    }
  }

  bool _isExistingAccountSignUp(AuthResponse res) {
    final user = res.user;
    if (user == null) return false;
    final identities = user.identities;
    return identities == null || identities.isEmpty;
  }

  bool _isExistingAccountMessage(String message) {
    final lower = message.toLowerCase();
    return lower.contains('already registered') ||
        lower.contains('already exists') ||
        lower.contains('user already registered');
  }

  bool _isTransientNetworkError(Object error) {
    final text = error.toString().toLowerCase();
    return text.contains('failed to fetch') ||
        text.contains('clientexception') ||
        text.contains('socketexception') ||
        text.contains('network') ||
        text.contains('connection') ||
        text.contains('timed out') ||
        text.contains('timeout');
  }

  String _friendlyError(Object error, {required String action}) {
    final text = error.toString();
    if (_isTransientNetworkError(error)) {
      return 'Could not reach the login server. Check your internet, disable '
          'ad blockers or strict tracking protection for this tab, then try '
          '$action again. If it keeps failing, open your Supabase dashboard '
          'and make sure the project is not paused.';
    }
    return 'Could not $action. $text';
  }

  Future<void> signOut() async {
    try {
      await _client?.auth.signOut();
    } catch (_) {}
  }
}
