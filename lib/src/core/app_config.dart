import 'package:flutter/foundation.dart';

/// Build-time configuration, supplied with `--dart-define`.
///
/// With no flags the app targets the local Supabase stack started by
/// `supabase start`, so `flutter run` works out of the box:
///
///     flutter run --dart-define=SUPABASE_URL=https://<ref>.supabase.co \
///                 --dart-define=SUPABASE_ANON_KEY=<publishable key>
class AppConfig {
  const AppConfig._();

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: 'http://127.0.0.1:54321');

  /// The anon/publishable key is safe to ship in a client: row level security
  /// is what protects the data. The default is the well-known key every local
  /// `supabase start` stack uses; it is useless against a hosted project.
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0',
  );

  /// Error reporting is off unless a DSN is provided.
  static const String sentryDsn = String.fromEnvironment('SENTRY_DSN');
  static const String sentryEnvironment = String.fromEnvironment('SENTRY_ENVIRONMENT', defaultValue: 'production');
  static const String releaseVersion = String.fromEnvironment('RELEASE_VERSION', defaultValue: 'dev');

  static bool get sentryEnabled => sentryDsn.isNotEmpty && kReleaseMode;
  static bool get isLocalBackend => supabaseUrl.contains('127.0.0.1') || supabaseUrl.contains('localhost');
}
