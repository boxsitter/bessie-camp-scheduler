library;

import 'package:bessie/src/app.dart';
import 'package:bessie/src/shared/controllers/user_controller.dart';
import 'package:bessie/src/shared/routes/navigation_observer.dart';
import 'package:bessie/src/shared/services/popup_service.dart';
import 'package:bessie/src/shared/widgets/context_switcher/controller/session_selector_controller.dart';
import 'package:bessie/src/shared/widgets/header/controllers/menu_bar_controller.dart';
import 'package:bessie/src/shared/widgets/header/header_controller.dart';
import 'package:bessie/src/shared/widgets/layouts/sidebars/sidebar_controller.dart';
import 'package:bessie/src/features/activity_preferences/controllers/activity_preferences_controller_diplomatic.dart';
import 'package:bessie/src/features/authentication/authentication_controller.dart';
import 'package:bessie/src/features/console/controller/console_controller.dart';
import 'package:bessie/src/features/rosters/controllers/rosters_controller.dart';
import 'package:bessie/src/features/schedule/schedule_page_controller.dart';
import 'package:bessie/src/features/session_manager/session_manager_controller.dart';
import 'package:bessie/src/cli/io/io_interfaces.dart';
import 'package:bessie/src/ember_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

const _frontendName = 'Bessie';
const _frontendDescription = 'Cross-platform app interface for managing summer camp logistics with EmberCore';

class BessUi implements CoreFrontend{
  @override
  void init() {
    Get.put(PopupService(), permanent: true);
    Get.put(AuthenticationController(), permanent: true);
    Get.put(MenuBarController(), permanent: true);
    Get.put(SidebarController(), permanent: true);
  }

  @override
  void onLogin() {
    // Get.put(SaveController(), permanent: true);
    Get.put(ConsoleController(), permanent: true);
    Get.put(SessionManagerController(), permanent: true);
    Get.put(ActivityPreferencesControllerDiplomatic(), permanent: true);
    Get.put(SchedulePageController(), permanent: true);
    Get.put(HeaderController(), permanent: true);
    Get.put(RostersController(), permanent: true);
    Get.put(SessionSelectorController(), permanent: true);
    Get.put(UserController(), permanent: true);
  }

  @override
  Future<void> onNewContext() async {
    await Get.delete<SessionManagerController>(force: true);
    await Get.delete<ActivityPreferencesControllerDiplomatic>(force: true);
    await Get.delete<SchedulePageController>(force: true);
    await Get.delete<HeaderController>(force: true);
    await Get.delete<RostersController>(force: true);
    await Get.delete<SessionSelectorController>(force: true);
    await Get.delete<UserController>(force: true);
    onLogin();
  }

  static void launchFlutterApp() {
    Get.put(BessNavigationObserver(), permanent: true);
    runApp(const BessieFlutterApp());
  }

  @override
  String get frontendName => _frontendName;

  @override
  String get frontendDescription => _frontendDescription;

  @override
  void showToast({String? title, String? message, LogType? logType}) {
    final PopupService popupService = Get.find<PopupService>();
    popupService.showToast(title: title, message: message, logType: logType);
  }

  @override
  Future<bool> getConfirmation({required String title, String? message, Map<String, List<String>>? foldedSubcontent}) {
    final PopupService popupService = Get.find<PopupService>();
    return popupService.showConfirmationDialog(title: title, message: message);
  }

  @override
  UserInput getUserInputImplementation() {
    return Get.find<ConsoleController>();
  }

  @override
  UserOutput getUserOutputImplementation() {
    return Get.find<ConsoleController>();
  }


}
