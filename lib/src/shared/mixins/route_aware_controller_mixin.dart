import 'package:get/get.dart';

mixin RouteAwareControllerMixin on GetxController {
  /// Called when this page becomes visible, either by being pushed or by a
  /// page on top of it being popped.
  ///
  /// This will NOT be called if the navigation is from a popup/dialog.
  void onNavigateTo(String to, String? from) {}

  /// Called when this page becomes invisible, either by a new page being
  /// pushed on top of it or by this page being popped.
  ///
  /// This will NOT be called if the navigation is to a popup/dialog.
  void onNavigateFrom(String from, String to) {}
}