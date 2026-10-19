import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../models/enums.dart';
import '../../services/auth_service.dart';
import 'routes.dart';

/// Decides who may open which page: signed-out users go to sign-in, signed-in
/// users don't see the sign-in pages, and only directors and admins reach the
/// pages that change data.
class AuthMiddleware extends GetMiddleware {
  @override
  int? get priority => 0;

  @override
  RouteSettings? redirect(String? route) {
    final auth = Get.find<AuthService>();
    final target = redirectFor(
      route,
      signedIn: auth.isSignedIn,
      recoveringPassword: auth.recoveringPassword.value,
      role: auth.profile.value?.role,
    );
    return target == null ? null : RouteSettings(name: target);
  }

  /// The route to send the user to instead of [route], or null to let them in.
  static String? redirectFor(String? route, {required bool signedIn, bool recoveringPassword = false, StaffRole? role}) {
    // Someone who followed a reset link must choose a new password first.
    if (recoveringPassword) return route == BessRoutes.resetPassword ? null : BessRoutes.resetPassword;

    // The reset page explains itself when the link is missing or has expired.
    if (route == BessRoutes.unknown || route == BessRoutes.resetPassword) return null;

    if (!signedIn) return BessRoutes.publicRoutes.contains(route) ? null : BessRoutes.login;

    if (BessRoutes.guestOnlyRoutes.contains(route)) return BessRoutes.rosters;
    final canEdit = role?.canEditSessionData ?? false;
    if (BessRoutes.writerOnlyRoutes.contains(route) && !canEdit) return BessRoutes.rosters;
    return null;
  }
}
