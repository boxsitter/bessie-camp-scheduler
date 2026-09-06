import 'package:bessie/src/ember_core.dart';
import 'package:get/get.dart';

import '../../../routes/routes.dart';

class SidebarController extends GetxController {
  final activeItem = BessRoutes.rosters.obs;
  final hoverItem = ''.obs;
  final UserService userService = Get.find<UserService>();

  @override
  void onInit() {
    super.onInit();
    // On refresh, set the current route as the active item
    activeItem.value = Get.currentRoute;
  }

  void changeActiveItem(String route) => activeItem.value = route;

  void changeHoverItem(String route) {
    if (!isActive(route)) hoverItem.value = route;
  }

  bool isActive(String route) => activeItem.value == route;

  bool isHovering(String route) => hoverItem.value == route;

  void menuonPressed(String route) {
    print('Menu on tap called!');
    Get.offNamed(route);
  }

  Future<void> logOut() async {
    Get.offAllNamed(BessRoutes.login);
    await userService.logout();
  }
}
