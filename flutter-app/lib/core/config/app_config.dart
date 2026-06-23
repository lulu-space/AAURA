/// Centralized runtime configuration for the AAURA app.
///
/// Every value can be overridden at build/run time with `--dart-define`, e.g.:
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:4000/api/v1
///
/// The defaults point at a locally running backend + the project's Supabase
/// instance, so a plain `flutter run` works for web/desktop out of the box.
class AppConfig {
  const AppConfig._();

  /// Supabase project URL (safe to ship; this is public).
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://njmsxkatexarayrvzcsq.supabase.co',
  );

  /// Supabase anon/public key (safe for clients; never the service-role key).
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5qbXN4a2F0ZXhhcmF5cnZ6Y3NxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc3MDQ3MzcsImV4cCI6MjA5MzI4MDczN30.3Kia6tjb-NkQfYB30QZx7_yAGgkr-OhP0Kg7HdkHBr4',
  );

  /// Base URL of the Express backend, including the `/api/v1` prefix.
  ///
  /// Run targets:
  ///   web / windows / desktop  -> http://localhost:4000/api/v1
  ///   android emulator         -> http://10.0.2.2:4000/api/v1
  ///   physical device          -> http://<your-LAN-ip>:4000/api/v1
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:4000/api/v1',
  );

  /// Master switch for backend calls. When false, the app behaves exactly like
  /// the original mock-only prototype. Repositories also fall back to mock data
  /// automatically whenever a backend call fails, so the UI never hard-breaks.
  static const bool backendEnabled = bool.fromEnvironment(
    'BACKEND_ENABLED',
    defaultValue: true,
  );

  /// Network timeout for a single API request before falling back to mock data.
  static const Duration requestTimeout = Duration(seconds: 8);

  /// Shams profiling can be slow on the first message while NLP resources load.
  static const Duration profilingRequestTimeout = Duration(seconds: 45);

  /// Public web URL used in volunteer/event join links (no trailing slash).
  static const String appJoinBaseUrl = String.fromEnvironment(
    'APP_JOIN_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );
}
