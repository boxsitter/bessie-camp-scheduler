import 'package:get/get.dart';

/// Whether the sidebar is shown.
///
/// Until the user opens or closes it, the layout decides (a narrow window
/// starts with the sidebar hidden).
class MenuBarController extends GetxController {
  bool? _userChoice;
  bool _hiddenByDefault = false;

  bool get sidebarHidden => _userChoice ?? _hiddenByDefault;

  /// What the layout wants while the user hasn't chosen. Plain assignment, so
  /// it is safe to set while building.
  set hiddenByDefault(bool value) => _hiddenByDefault = value;

  void toggleHideSidebar() => setHideSidebar(!sidebarHidden);

  void setHideSidebar(bool hidden) {
    _userChoice = hidden;
    update();
  }
}
