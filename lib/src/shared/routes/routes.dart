import 'package:get/get.dart';

import '../../features/activity_preferences/controllers/activity_preferences_controller.dart';
import '../../features/activity_preferences/views/activity_preferences.dart';
import '../../features/authentication/view/forgot_password/forgot_password.dart';
import '../../features/authentication/view/login/login.dart';
import '../../features/authentication/view/reset_password/reset_password.dart';
import '../../features/branch_manager/branch_manager.dart';
import '../../features/branch_manager/branch_manager_controller.dart';
import '../../features/console/view/console.dart';
import '../../features/rosters/controllers/rosters_controller.dart';
import '../../features/rosters/rosters.dart';
import '../../features/schedule/schedule_page.dart';
import '../../features/schedule/schedule_page_controller.dart';
import '../../features/session_manager/session_manager.dart';
import '../../features/session_manager/session_manager_controller.dart';
import '../../features/unknown_route/unknown_route.dart';
import '../mixins/route_aware_controller_mixin.dart';
import 'routes_middleware.dart';

class BessRoutes {
  const BessRoutes._();

  static const login = '/login';
  static const forgotPassword = '/forgotPassword';
  static const resetPassword = '/resetPassword';

  static const rosters = '/';
  static const activityPreferences = '/activity-preferences';
  static const schedulePage = '/schedule-page';
  static const sessionManager = '/session-manager';
  static const branchManager = '/branch-manager';
  static const console = '/console';
  static const unknown = '/unknown';

  /// Reachable without being signed in.
  static const Set<String> publicRoutes = {login, forgotPassword, resetPassword, unknown};

  /// For people who are not signed in yet; signed-in users are sent to [rosters].
  static const Set<String> guestOnlyRoutes = {login, forgotPassword};

  /// Pages that change session data or the camp's structure: directors and admins only.
  static const Set<String> writerOnlyRoutes = {sessionManager, branchManager, console};

  static final GetPage unknownPage = GetPage(name: unknown, page: () => const UnknownRoute());

  static final List<GetPage> pages = [
    _page(rosters, () => const Rosters()),
    _page(activityPreferences, () => const ActivityPreferences()),
    _page(schedulePage, () => const SchedulePage()),
    _page(sessionManager, () => const SessionManager()),
    _page(branchManager, () => const BranchManager()),
    _page(console, () => const ConsoleScreen()),
    _page(login, () => const LoginScreen()),
    _page(forgotPassword, () => const ForgotPasswordScreen()),
    _page(resetPassword, () => const ResetPasswordScreen()),
    unknownPage,
  ];

  static GetPage _page(String name, GetPageBuilder page) => GetPage(name: name, page: page, middlewares: [AuthMiddleware()]);

  /// The controller of the page at [routeName], or null when the route has none
  /// or the controller doesn't exist (nobody is signed in).
  static RouteAwareControllerMixin? getControllerForRoute(String? routeName) => switch (routeName) {
    rosters => _controller<RostersController>(),
    activityPreferences => _controller<ActivityPreferencesController>(),
    schedulePage => _controller<SchedulePageController>(),
    sessionManager => _controller<SessionManagerController>(),
    branchManager => _controller<BranchManagerController>(),
    _ => null,
  };

  static RouteAwareControllerMixin? _controller<T extends GetxController>() {
    if (!Get.isRegistered<T>()) return null;
    final controller = Get.find<T>();
    return controller is RouteAwareControllerMixin ? controller : null;
  }
}
