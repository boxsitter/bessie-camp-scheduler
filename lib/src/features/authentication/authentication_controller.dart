import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/bindings.dart';
import '../../core/logging.dart';
import '../../services/auth_service.dart';
import '../../shared/routes/routes.dart';
import '../../shared/services/toast.dart';
import '../../shared/widgets/header/header_controller.dart';

/// Signing in and out, and the forgot/reset password flow.
///
/// Sessions are saved by Supabase on every platform, so there is no
/// "remember me": a signed-in user stays signed in until they sign out.
class AuthenticationController extends GetxController {
  final AuthService _auth = Get.find<AuthService>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  /// True while a sign-in, reset request or password change is in flight.
  final RxBool isLoading = false.obs;
  final RxBool hidePassword = true.obs;

  bool _signingOut = false;
  Worker? _profileWatcher;

  /// Where the emailed reset link should bring the user back to.
  ///
  /// Flutter web serves this app with hash URLs, so the reset page is
  /// `<origin>/#/resetPassword`. Supabase appends the one-time code before the
  /// `#`, where supabase_flutter picks it up. The address must be listed in
  /// `additional_redirect_urls` of the Supabase auth settings.
  static String passwordResetRedirect(Uri base) {
    final location = Uri(
      scheme: base.scheme,
      host: base.host,
      port: base.hasPort ? base.port : null,
      path: base.path.isEmpty ? '/' : base.path,
    );
    return location.replace(fragment: BessRoutes.resetPassword).toString();
  }

  @override
  void onInit() {
    super.onInit();
    // The server can end a session on its own (revoked, expired refresh token).
    _profileWatcher = ever(_auth.profile, (profile) {
      if (profile == null && !_signingOut && !BessRoutes.publicRoutes.contains(Get.currentRoute) && Get.currentRoute.isNotEmpty) {
        _endExpiredSession();
      }
    });
  }

  void togglePasswordVisibility() => hidePassword.value = !hidePassword.value;

  /// Signs in with the email and password typed into the login form.
  Future<void> signIn() async {
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      final profile = await attempt(() => _auth.signIn(emailController.text, passwordController.text));
      if (profile != null) await _openApp();
    } finally {
      isLoading.value = false;
      passwordController.clear();
    }
  }

  /// Emails a password reset link to the address typed into the form.
  /// Returns whether the request went through.
  Future<bool> sendResetLink() async {
    if (isLoading.value) return false;
    isLoading.value = true;
    try {
      final redirectTo = kIsWeb ? passwordResetRedirect(Uri.base) : null;
      final sent = await attempt(() async {
        await _auth.sendPasswordReset(emailController.text.trim(), redirectTo: redirectTo);
        return true;
      });
      return sent ?? false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Saves the new password typed into the reset form and continues into the app.
  Future<void> resetPassword() async {
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      final changed = await attempt(() async {
        await _auth.completePasswordReset(newPasswordController.text);
        return true;
      });
      if (changed != true) return;
      newPasswordController.clear();
      confirmPasswordController.clear();
      Toast.success('Your password has been changed.');
      await _openApp();
    } finally {
      isLoading.value = false;
    }
  }

  /// Gives up on a password reset: forgets the recovery session and returns to sign-in.
  Future<void> cancelPasswordReset() async {
    _auth.recoveringPassword.value = false;
    newPasswordController.clear();
    confirmPasswordController.clear();
    await signOut();
  }

  Future<void> signOut() async {
    _signingOut = true;
    try {
      try {
        await _auth.signOut();
      } catch (e, st) {
        // Supabase drops the local session before it tells the server, so the
        // user is signed out here even when the server could not be reached.
        log.w('Sign-out could not reach the server', error: e, stackTrace: st);
        _auth.profile.value = null;
      }
      await AppBindings.onSignedOut();
      passwordController.clear();
      await Get.offAllNamed(BessRoutes.login);
    } finally {
      _signingOut = false;
    }
  }

  /// Goes into the app for whoever is signed in, loading their camp first.
  Future<void> _openApp() async {
    if (!_auth.isSignedIn) await _auth.init();
    if (!_auth.isSignedIn) {
      await Get.offAllNamed(BessRoutes.login);
      return;
    }

    // Already inside the app (e.g. changing the password while signed in)?
    if (!Get.isRegistered<HeaderController>()) {
      try {
        await AppBindings.onSignedIn();
      } catch (e, st) {
        Toast.failure(e, st);
        await signOut();
        return;
      }
    }
    await Get.offAllNamed(BessRoutes.rosters);
  }

  Future<void> _endExpiredSession() async {
    Toast.info('You have been signed out. Please sign in again.');
    await AppBindings.onSignedOut();
    await Get.offAllNamed(BessRoutes.login);
  }

  @override
  void onClose() {
    _profileWatcher?.dispose();
    emailController.dispose();
    passwordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
