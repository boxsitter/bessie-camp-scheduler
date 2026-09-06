import 'package:bessie/src/shared/routes/routes_middleware.dart';
import 'package:bessie/src/features/activity_preferences/controllers/activity_preferences_controller_diplomatic.dart';
import 'package:bessie/src/features/dev_testing/dev_testing.dart';
import 'package:get/get.dart';

import '../../features/activity_preferences/views/activity_preferences.dart';
import '../../features/authentication/view/forgot_password/forgot_password.dart';
import '../../features/authentication/view/login/login.dart';
import '../../features/authentication/view/reset_password/reset_password.dart';
import '../../features/branch_manager/branch_manager.dart';
import '../../features/console/view/console.dart';
import '../../features/rosters/controllers/rosters_controller.dart';
import '../../features/rosters/rosters.dart';
import '../../features/schedule/schedule_page.dart';
import '../../features/session_manager/session_manager.dart';
import '../../features/session_manager/session_manager_controller.dart';
import '../../features/unknown_route/unknown_route.dart';
import '../mixins/route_aware_controller_mixin.dart';

class BessRoutes {
  // static const home = '/';
  static const unknown = '/unknown';

  static const responsiveDesignExample = '/responsive-design';
  static const console = '/console';
  static const dev_testing = '/dev_testing';
  static const rosters = '/';
  static const schedulePage = '/schedule-page';
  static const sessionManager = '/session-manager';
  static const branchManager = '/branch-manager';

  static const activityPreferences = '/activity-preferences';
  static const activityPreferencesCampers = '/activity-preferences-campers';
  static const activityPreferencesSelector = '/activity-preferences-selector';

  static const login = '/login';
  static const forgotPassword = '/forgotPassword';
  static const resetPassword = '/resetPassword';

  static Set sideMenuItems = {
    console,
    dev_testing,
    rosters,
    activityPreferences,
    sessionManager,
    branchManager,
    schedulePage,
  };

  static Set publicRoutes = {
    login,
    forgotPassword,
    resetPassword,
    unknown,
  };

  static final List<GetPage> pages = [
    // GetPage(
    //   name: BessRoutes.home,
    //   page: () => const HomeScreen(),
    //   middlewares: [AuthMiddleware()], // PROTECTED
    // ),
    GetPage(
      name: BessRoutes.console,
      page: () => const ConsoleScreen(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: BessRoutes.dev_testing,
      page: () => const DevTesting(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: BessRoutes.rosters,
      page: () => const Rosters(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: BessRoutes.schedulePage,
      page: () => const SchedulePage(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: BessRoutes.sessionManager,
      page: () => const SessionManager(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: BessRoutes.activityPreferences,
      page: () => const ActivityPreferences(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: BessRoutes.activityPreferencesSelector,
      page: () => const ActivityPreferences(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: BessRoutes.branchManager,
      page: () => const BranchManager(),
      middlewares: [AuthMiddleware()],
    ),

    // --- AUTHENTICATION ROUTES (Public for unauthenticated users) ---
    // No AuthMiddleware here to block unauthenticated access,
    // but AuthMiddleware will redirect *away* if already logged in.
    GetPage(name: BessRoutes.login, page: () => const LoginScreen()),
    GetPage(name: BessRoutes.forgotPassword, page: () => const ForgotPasswordScreen()),
    GetPage(name: BessRoutes.resetPassword, page: () => const ResetPasswordScreen()),

    // THIS MUST BE LAST IN THE LIST!!!
    GetPage(
      name: BessRoutes.unknown,
      page: () => const UnknownRoute(),
    ),
  ];

  static RouteAwareControllerMixin? getControllerForRoute(String? routeName) {
    if (routeName == null) return null;

    if (routeName == BessRoutes.rosters && Get.isRegistered<RostersController>()) {
      return Get.find<RostersController>();
    }
    if ((routeName == BessRoutes.activityPreferences || routeName == BessRoutes.activityPreferencesSelector) && Get.isRegistered<ActivityPreferencesControllerDiplomatic>()) {
      return Get.find<ActivityPreferencesControllerDiplomatic>();
    }
    if (routeName == BessRoutes.sessionManager && Get.isRegistered<SessionManagerController>()) {
      return Get.find<SessionManagerController>();
    }
    // Add other route-to-controller mappings here
    return null;
  }
}
