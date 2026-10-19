import 'package:get/get.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../models/enums.dart';
import '../../../../services/auth_service.dart';
import '../../../routes/routes.dart';
import 'sidebar_item.dart';

class SidebarController extends GetxController {
  static const List<SidebarItem> allItems = [
    SidebarItem(route: BessRoutes.rosters, title: 'Rosters', icon: LucideIcons.bookUser),
    SidebarItem(route: BessRoutes.activityPreferences, title: 'Preferences', icon: LucideIcons.listOrdered),
    SidebarItem(route: BessRoutes.schedulePage, title: 'Schedule', icon: LucideIcons.columns3),
    SidebarItem(route: BessRoutes.sessionManager, title: 'Session setup', icon: LucideIcons.calendarCog),
    SidebarItem(route: BessRoutes.branchManager, title: 'Branch manager', icon: LucideIcons.flameKindling),
    SidebarItem(route: BessRoutes.console, title: 'Console', icon: LucideIcons.squareTerminal),
  ];

  /// The sidebar items [role] may open: everything for directors and admins,
  /// only the pages that don't change data for counselors.
  static List<SidebarItem> itemsFor(StaffRole role) => [
    for (final item in allItems)
      if (!item.writersOnly || role.canEditSessionData) item,
  ];

  final AuthService _auth = Get.find<AuthService>();

  final RxString activeItem = BessRoutes.rosters.obs;
  final RxString hoverItem = ''.obs;

  /// The items for the signed-in user. Reads the profile, so call it inside an `Obx`.
  List<SidebarItem> get items {
    final role = _auth.profile.value?.role;
    return role == null ? const [] : itemsFor(role);
  }

  void changeActiveItem(String route) => activeItem.value = route;

  void changeHoverItem(String route) {
    if (!isActive(route)) hoverItem.value = route;
  }

  bool isActive(String route) => activeItem.value == route;

  bool isHovering(String route) => hoverItem.value == route;

  void open(String route) {
    if (!isActive(route)) Get.offNamed(route);
  }
}
