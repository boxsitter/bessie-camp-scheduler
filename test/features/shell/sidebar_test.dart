import 'package:bessie/src/models/enums.dart';
import 'package:bessie/src/shared/routes/routes.dart';
import 'package:bessie/src/shared/widgets/layouts/sidebars/sidebar_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../../cli/support/fake_services.dart';

void main() {
  List<String> routesFor(StaffRole role) => SidebarController.itemsFor(role).map((item) => item.route).toList();

  group('itemsFor', () {
    test('directors and admins see everything', () {
      for (final role in [StaffRole.root, StaffRole.director, StaffRole.admin]) {
        expect(routesFor(role), [
          BessRoutes.rosters,
          BessRoutes.activityPreferences,
          BessRoutes.schedulePage,
          BessRoutes.sessionManager,
          BessRoutes.branchManager,
          BessRoutes.console,
        ], reason: '$role');
      }
    });

    test('counselors see the rosters, preferences and schedule only', () {
      expect(routesFor(StaffRole.counselor), [BessRoutes.rosters, BessRoutes.activityPreferences, BessRoutes.schedulePage]);
    });

    test('counselors never get an item for a route they may not open', () {
      for (final item in SidebarController.itemsFor(StaffRole.counselor)) {
        expect(BessRoutes.writerOnlyRoutes, isNot(contains(item.route)));
      }
    });

    test('no removed page is offered', () {
      final titles = SidebarController.allItems.map((item) => item.title);
      expect(titles, isNot(contains('Dev Testing')));
      expect(titles, containsAll(['Rosters', 'Preferences', 'Schedule', 'Session setup', 'Branch manager', 'Console']));
    });
  });

  group('SidebarController', () {
    tearDown(Get.reset);

    test('shows the items of whoever is signed in, following changes of user', () {
      final world = TestWorld(profile: staffProfile(role: StaffRole.counselor));
      Get.put(world.auth);
      final sidebar = SidebarController();

      expect(sidebar.items.map((item) => item.route), [BessRoutes.rosters, BessRoutes.activityPreferences, BessRoutes.schedulePage]);

      world.auth.profile.value = staffProfile(role: StaffRole.director);
      expect(sidebar.items, hasLength(6));

      world.auth.profile.value = null;
      expect(sidebar.items, isEmpty);
    });

    test('highlights the current route and ignores hovering over it', () {
      Get.put(TestWorld().auth);
      final sidebar = SidebarController();

      sidebar.changeActiveItem(BessRoutes.schedulePage);
      expect(sidebar.isActive(BessRoutes.schedulePage), isTrue);
      expect(sidebar.isActive(BessRoutes.rosters), isFalse);

      sidebar.changeHoverItem(BessRoutes.schedulePage);
      expect(sidebar.isHovering(BessRoutes.schedulePage), isFalse);
      sidebar.changeHoverItem(BessRoutes.rosters);
      expect(sidebar.isHovering(BessRoutes.rosters), isTrue);
    });
  });
}
