import 'dart:async';

import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/errors.dart';
import '../core/logging.dart';
import '../data/auth_repository.dart';
import '../data/profile_repository.dart';
import '../models/staff_profile.dart';

/// Who is signed in, and what they may do.
class AuthService extends GetxService {
  AuthService(this._auth, this._profiles);

  final AuthRepository _auth;
  final ProfileRepository _profiles;

  /// The signed-in staff member, null when signed out.
  final Rxn<StaffProfile> profile = Rxn<StaffProfile>();

  /// Set when the user arrives from a password-recovery email link.
  final RxBool recoveringPassword = false.obs;

  StreamSubscription<AuthState>? _subscription;

  bool get isSignedIn => _auth.isSignedIn && profile.value != null;
  StaffProfile get currentProfile {
    final current = profile.value;
    if (current == null) throw StateError('Nobody is signed in.');
    return current;
  }

  /// Restores a saved session (if any) and starts listening for auth changes.
  Future<AuthService> init() async {
    _subscription ??= _auth.authChanges.listen(_onAuthChange);
    if (_auth.isSignedIn) {
      try {
        profile.value = await _profiles.fetchMine();
        if (profile.value == null) await _auth.signOut();
      } catch (e, st) {
        log.w('Could not restore the saved session', error: e, stackTrace: st);
        await _auth.signOut();
      }
    }
    return this;
  }

  void _onAuthChange(AuthState state) {
    switch (state.event) {
      case AuthChangeEvent.signedOut:
        profile.value = null;
      case AuthChangeEvent.passwordRecovery:
        recoveringPassword.value = true;
      default:
        break;
    }
  }

  /// Signs in and loads the profile. Throws [AppException] with a user-ready
  /// message on any failure, including accounts that have no staff profile.
  Future<StaffProfile> signIn(String email, String password) async {
    await _auth.signIn(email: email, password: password);
    final loaded = await _profiles.fetchMine();
    if (loaded == null) {
      await _auth.signOut();
      throw AppException('This account doesn\'t have access to Bessie. Ask your director to set you up.');
    }
    profile.value = loaded;
    return loaded;
  }

  Future<void> signOut() async {
    await _auth.signOut();
    profile.value = null;
  }

  Future<void> sendPasswordReset(String email, {String? redirectTo}) => _auth.sendPasswordReset(email, redirectTo: redirectTo);

  Future<void> completePasswordReset(String newPassword) async {
    await _auth.updatePassword(newPassword);
    recoveringPassword.value = false;
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}
