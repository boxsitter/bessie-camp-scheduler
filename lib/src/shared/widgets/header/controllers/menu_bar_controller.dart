import 'package:bessie/src/shared/mixins/route_aware_controller_mixin.dart';
import 'package:get/get.dart';

class MenuBarController extends GetxController with RouteAwareControllerMixin {
  bool? _sidebarHidden;
  bool get sidebarHidden => _sidebarHidden == null ? false : _sidebarHidden!;
  bool? get sidebarHiddenRaw => _sidebarHidden;

  void toggleHideSidebar() {
    if (_sidebarHidden == null) {
      _sidebarHidden = true;
    } else {
      _sidebarHidden = !sidebarHidden;
    }
    update();
  }

  void setHideSidebar(bool value) {
    _sidebarHidden = value;
    update();
  }
}