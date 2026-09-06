import 'package:bessie/src/shared/routes/routes.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../widgets/layouts/sidebars/sidebar_controller.dart';

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

    // Notify the controller of the page we are LEAVING
    final fromController = BessRoutes.getControllerForRoute(from);
    if (fromController != null) {
      fromController.onNavigateFrom(from!, to);
    }

    final toController = BessRoutes.getControllerForRoute(to);
    if (toController != null) {
      bool shouldCallOnNavigateTo = true;

      // If this is a 'pop' event AND we are returning to the route
      // we already considered the main page, it means an overlay was
      // just closed. In this case, we should NOT call onNavigateTo.
      if (!isPush && to == _currentPageRoute) {
        shouldCallOnNavigateTo = false;
      }

      if (shouldCallOnNavigateTo) {
        toController.onNavigateTo(to, from);
        // Since a true navigation occurred to a registered page,
        // update our state to reflect the new current page.
        _currentPageRoute = to;
      }
    }

    // Update the sidebar's active item regardless of the controller logic.
    if (Get.isRegistered<SidebarController>()) {
      Get.find<SidebarController>().changeActiveItem(to);
    }
  }
}