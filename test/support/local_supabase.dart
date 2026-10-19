import 'dart:io';

import 'package:bessie/src/core/app_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Integration tests run against the local stack (`supabase start`, seeded by
/// `supabase db reset`). They are skipped when it isn't running.
Future<bool> localSupabaseAvailable() async {
  try {
    final socket = await Socket.connect(Uri.parse(AppConfig.supabaseUrl).host, Uri.parse(AppConfig.supabaseUrl).port,
        timeout: const Duration(seconds: 2));
    socket.destroy();
    return true;
  } catch (_) {
    return false;
  }
}

/// A client signed in as one of the seeded demo accounts.
Future<SupabaseClient> signedInClient(String email, {String password = 'password123'}) async {
  final client = SupabaseClient(
    AppConfig.supabaseUrl,
    AppConfig.supabaseAnonKey,
    authOptions: const AuthClientOptions(autoRefreshToken: false),
  );
  await client.auth.signInWithPassword(email: email, password: password);
  return client;
}

const director = 'director@bessie.test';
const admin = 'admin@bessie.test';
const counselor = 'counselor@bessie.test';
