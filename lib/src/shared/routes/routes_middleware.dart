import 'package:bessie/src/ember_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'routes.dart'; // Your BessRoutes class is here

class AuthMiddleware extends GetMiddleware {
  @override
  int? get priority => 0;

  UserService userService = Get.find<UserService>();

  @override
  RouteSettings? redirect(String? route) {
    // Define which routes are considered "public" (accessible without login)
    // These are routes that unauthenticated users CAN visit.
    final List<String> publicAuthRoutes = [
      BessRoutes.login,
      BessRoutes.forgotPassword,
      BessRoutes.resetPassword,
      BessRoutes.unknown,
    ];

    final bool isTryingToAccessPublicAuthRoute = publicAuthRoutes.contains(route);

    if (userService.isAuthenticated) {
      // User IS authenticated
      if (isTryingToAccessPublicAuthRoute) {
        // If an authenticated user tries to access login, forgot password, etc.,
        // redirect them to the home page.
        return const RouteSettings(name: BessRoutes.rosters);
      }
      // For any other route (which are effectively protected or other non-auth public pages), allow access.
      return null; // No redirection needed, proceed to the intended route.
    } else {
      // User is NOT authenticated
      if (isTryingToAccessPublicAuthRoute) {
        // If an unauthenticated user is trying to access a public auth route (like login), allow it.
        return null; // No redirection needed
      } else {
        // If an unauthenticated user tries to access any other route (which should be protected),
        // redirect them to the login page.
        return const RouteSettings(name: BessRoutes.login);
      }
    }
  }
}
