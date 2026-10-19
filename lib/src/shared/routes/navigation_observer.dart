import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../widgets/layouts/sidebars/sidebar_controller.dart';
import 'routes.dart';

/// Tells page controllers when their page appears and disappears, and keeps
/// the sidebar's highlighted item in step with the current route.
class BessNavigationObserver extends NavigatorObserver {
  String? _currentPageRoute;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _handleNavigation(route.settings.name, previousRoute?.settings.name, isPush: true);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _handleNavigation(previousRoute?.settings.name, route.settings.name, isPush: false);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _handleNavigation(newRoute?.settings.name, oldRoute?.settings.name, isPush: true);
  }

  void _handleNavigation(String? to, String? from, {required bool isPush}) {
    if (to == null) return;

    // The page we are leaving.
    BessRoutes.getControllerForRoute(from)?.onNavigateFrom(from!, to);

    final toController = BessRoutes.getControllerForRoute(to);
    // Popping back to the page that is already current means an overlay (a
    // dialog, a popup) closed; the page itself never went away.
    final overlayClosed = !isPush && to == _currentPageRoute;
    if (toController != null && !overlayClosed) {
      toController.onNavigateTo(to, from);
      _currentPageRoute = to;
    }

    if (Get.isRegistered<SidebarController>()) {
      Get.find<SidebarController>().changeActiveItem(to);
    }
  }
}
