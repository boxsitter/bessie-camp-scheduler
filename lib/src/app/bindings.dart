import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/auth_repository.dart';
import '../data/catalog_repository.dart';
import '../data/profile_repository.dart';
import '../data/roster_repository.dart';
import '../data/session_repository.dart';
import '../features/activity_preferences/controllers/activity_preferences_controller.dart';
import '../features/authentication/authentication_controller.dart';
import '../features/branch_manager/branch_manager_controller.dart';
import '../features/console/controller/console_controller.dart';
import '../features/rosters/controllers/rosters_controller.dart';
import '../features/schedule/schedule_page_controller.dart';
import '../features/session_manager/session_manager_controller.dart';
import '../services/assignment_service.dart';
import '../services/auth_service.dart';
import '../services/backup_service.dart';
import '../services/context_service.dart';
import '../services/file_service.dart';
import '../services/roster_import_service.dart';
import '../shared/routes/navigation_observer.dart';
import '../shared/services/popup_service.dart';
import '../shared/widgets/context_switcher/controller/session_selector_controller.dart';
import '../shared/widgets/header/controllers/menu_bar_controller.dart';
import '../shared/widgets/header/header_controller.dart';
import '../shared/widgets/layouts/sidebars/sidebar_controller.dart';

/// The one place dependencies are created and wired together.
///
/// * [registerCore] runs once at startup: data access, services and the
///   controllers the login screen needs.
/// * [onSignedIn] / [onSignedOut] create and tear down everything that
///   belongs to a signed-in user (the camp context and the page controllers).
class AppBindings {
  const AppBindings._();

  static void registerCore(SupabaseClient client) {
    // Data access: stateless wrappers over the Supabase client.
    final auth = Get.put(AuthRepository(client), permanent: true);
    final profiles = Get.put(ProfileRepository(client), permanent: true);
    final catalog = Get.put(CatalogRepository(client), permanent: true);
    final sessions = Get.put(SessionRepository(client), permanent: true);
    final roster = Get.put(RosterRepository(client), permanent: true);

    // Services.
    final authService = Get.put(AuthService(auth, profiles), permanent: true);
    Get.put(ContextService(catalog, profiles, authService), permanent: true);
    Get.put(AssignmentService(sessions, roster), permanent: true);
    Get.put(const RosterCsvParser(), permanent: true);
    Get.put(const BackupService(), permanent: true);
    Get.put(const FileService(), permanent: true);

    // UI infrastructure that exists before sign-in.
    Get.put(PopupService(), permanent: true);
    Get.put(BessNavigationObserver(), permanent: true);
    Get.put(AuthenticationController(), permanent: true);
    Get.put(MenuBarController(), permanent: true);
    Get.put(SidebarController(), permanent: true);
  }

  /// Loads the camp context and creates the page controllers. Call after a
  /// successful sign-in (or when a saved session is restored at startup).
  static Future<void> onSignedIn() async {
    await Get.find<ContextService>().load();

    Get.put(ConsoleController(), permanent: true);
    Get.put(HeaderController(), permanent: true);
    Get.put(SessionSelectorController(), permanent: true);
    Get.put(RostersController(), permanent: true);
    Get.put(ActivityPreferencesController(), permanent: true);
    Get.put(SessionManagerController(), permanent: true);
    Get.put(SchedulePageController(), permanent: true);
    Get.put(BranchManagerController(), permanent: true);
  }

  static Future<void> onSignedOut() async {
    for (final delete in <Future<bool> Function()>[
      () => Get.delete<BranchManagerController>(force: true),
      () => Get.delete<SchedulePageController>(force: true),
      () => Get.delete<SessionManagerController>(force: true),
      () => Get.delete<ActivityPreferencesController>(force: true),
      () => Get.delete<RostersController>(force: true),
      () => Get.delete<SessionSelectorController>(force: true),
      () => Get.delete<HeaderController>(force: true),
      () => Get.delete<ConsoleController>(force: true),
    ]) {
      await delete();
    }
    Get.find<ContextService>().clear();
  }
}
