import 'package:bessie/src/models/enums.dart';
import 'package:bessie/src/shared/routes/routes.dart';
import 'package:bessie/src/shared/routes/routes_middleware.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../../cli/support/fake_services.dart';

void main() {
  String? redirect(String route, {required bool signedIn, bool recovering = false, StaffRole? role}) => AuthMiddleware.redirectFor(
    route,
    signedIn: signedIn,
    recoveringPassword: recovering,
    role: role ?? (signedIn ? StaffRole.admin : null),
  );

  const protectedRoutes = [
    BessRoutes.rosters,
    BessRoutes.activityPreferences,
    BessRoutes.schedulePage,
    BessRoutes.sessionManager,
    BessRoutes.branchManager,
    BessRoutes.console,
  ];

  group('signed out', () {
    test('is sent to the login page from every protected page', () {
      for (final route in protectedRoutes) {
        expect(redirect(route, signedIn: false), BessRoutes.login, reason: route);
      }
    });

    test('is sent to login from a route nobody has heard of', () {
      expect(redirect('/nowhere', signedIn: false), BessRoutes.login);
    });

    test('may open the login, forgot-password, reset-password and unknown pages', () {
      for (final route in [BessRoutes.login, BessRoutes.forgotPassword, BessRoutes.resetPassword, BessRoutes.unknown]) {
        expect(redirect(route, signedIn: false), isNull, reason: route);
      }
    });

    test('a missing route name means login', () {
      expect(AuthMiddleware.redirectFor(null, signedIn: false), BessRoutes.login);
    });
  });

  group('signed in as a director or admin', () {
    test('may open every protected page', () {
      for (final role in [StaffRole.root, StaffRole.director, StaffRole.admin]) {
        for (final route in protectedRoutes) {
          expect(redirect(route, signedIn: true, role: role), isNull, reason: '$role $route');
        }
      }
    });

    test('is taken to the rosters from the pages meant for signed-out users', () {
      expect(redirect(BessRoutes.login, signedIn: true), BessRoutes.rosters);
      expect(redirect(BessRoutes.forgotPassword, signedIn: true), BessRoutes.rosters);
    });

    test('may still open the reset-password and unknown pages', () {
      expect(redirect(BessRoutes.resetPassword, signedIn: true), isNull);
      expect(redirect(BessRoutes.unknown, signedIn: true), isNull);
    });
  });

  group('signed in as a counselor', () {
    test('may open the pages that only read data', () {
      for (final route in [BessRoutes.rosters, BessRoutes.activityPreferences, BessRoutes.schedulePage]) {
        expect(redirect(route, signedIn: true, role: StaffRole.counselor), isNull, reason: route);
      }
    });

    test('is sent back to the rosters from the session setup, branch manager and console', () {
      for (final route in [BessRoutes.sessionManager, BessRoutes.branchManager, BessRoutes.console]) {
        expect(redirect(route, signedIn: true, role: StaffRole.counselor), BessRoutes.rosters, reason: route);
      }
    });
  });

  group('following a password reset link', () {
    test('only the reset page may be opened, whether or not a profile is loaded', () {
      for (final signedIn in [true, false]) {
        expect(redirect(BessRoutes.resetPassword, signedIn: signedIn, recovering: true), isNull);
        for (final route in [...protectedRoutes, BessRoutes.login, BessRoutes.forgotPassword, BessRoutes.unknown]) {
          expect(redirect(route, signedIn: signedIn, recovering: true), BessRoutes.resetPassword, reason: '$signedIn $route');
        }
      }
    });
  });

  group('reading the state from the services', () {
    tearDown(Get.reset);

    test('sends a signed-out user to login', () {
      Get.put(TestWorld().auth);

      expect(AuthMiddleware().redirect(BessRoutes.rosters)?.name, BessRoutes.login);
      expect(AuthMiddleware().redirect(BessRoutes.login), isNull);
    });

    test('sends everyone to the reset page while a recovery is under way', () {
      final auth = Get.put(TestWorld().auth);
      auth.recoveringPassword.value = true;

      expect(AuthMiddleware().redirect(BessRoutes.rosters)?.name, BessRoutes.resetPassword);
      expect(AuthMiddleware().redirect(BessRoutes.resetPassword), isNull);
    });
  });

  group('routes', () {
    test('the writers-only pages are the ones that change data', () {
      expect(BessRoutes.writerOnlyRoutes, {BessRoutes.sessionManager, BessRoutes.branchManager, BessRoutes.console});
    });

    test('every route but unknown is registered behind the middleware', () {
      for (final page in BessRoutes.pages) {
        expect(page.middlewares?.whereType<AuthMiddleware>().length ?? 0, page.name == BessRoutes.unknown ? 0 : 1, reason: page.name);
      }
      expect(BessRoutes.pages.last.name, BessRoutes.unknown);
    });

    test('no page controller is looked up when nobody is signed in', () {
      Get.reset();
      for (final route in [...protectedRoutes, BessRoutes.login, null, '/nowhere']) {
        expect(BessRoutes.getControllerForRoute(route), isNull, reason: '$route');
      }
    });
  });
}
