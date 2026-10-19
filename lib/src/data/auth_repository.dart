import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/errors.dart';

/// Email/password authentication against Supabase Auth.
///
/// Accounts are provisioned by an administrator (public sign-up is disabled),
/// so there is intentionally no sign-up method here.
class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  bool get isSignedIn => _client.auth.currentSession != null;
  String? get userId => _client.auth.currentUser?.id;
  String? get email => _client.auth.currentUser?.email;

  Stream<AuthState> get authChanges => _client.auth.onAuthStateChange;

  Future<void> signIn({required String email, required String password}) =>
      guarded(() => _client.auth.signInWithPassword(email: email.trim(), password: password));

  Future<void> signOut() => guarded(() => _client.auth.signOut());

  /// Emails a link that returns the user to [redirectTo] ready to choose a new password.
  Future<void> sendPasswordReset(String email, {String? redirectTo}) =>
      guarded(() => _client.auth.resetPasswordForEmail(email.trim(), redirectTo: redirectTo));

  Future<void> updatePassword(String newPassword) => guarded(() => _client.auth.updateUser(UserAttributes(password: newPassword)));
}
