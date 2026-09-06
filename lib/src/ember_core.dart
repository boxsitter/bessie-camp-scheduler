import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bessie/src/repositories/authentication_repository.dart';
import 'package:bessie/src/repositories/contextless_repository.dart';
import 'package:bessie/src/repositories/live_data_repository.dart';
import 'package:bessie/src/services/database_repair_service.dart';
import 'package:bessie/src/services/path_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';

import 'ember_core.dart';
import '../firebase_options.dart';

export 'models/debug/ember_exception.dart';
export 'models/debug/ember_info.dart';
export 'debug/debug.dart';
export 'debug/core_exceptions.dart';
export 'models/interfaces/logable.dart';
export 'frontend/frontend_interface.dart';
export 'frontend/frontend_manager.dart';
export 'models/superclasses/core_object.dart';
export 'models/interfaces/dependent.dart';
export 'models/interfaces/principal.dart';
export 'models/superclasses/schedule_block.dart';
export 'models/interfaces/domain.dart';
export 'models/interfaces/rosterable.dart';
export 'models/interfaces/titled.dart';
export 'models/core_objects/dependent/cabin_dependent.dart';
export 'models/core_objects/dependent/activity_dependent.dart';
export 'models/core_objects/domain/branch.dart';
export 'models/core_objects/domain/session.dart';
export 'models/core_objects/domain/organization.dart';
export 'models/core_objects/domain/season.dart';
export 'models/core_objects/principal/principal_activity.dart';
export 'models/core_objects/principal/principal_cabin.dart';
export 'models/core_objects/schedule_block/ama_block.dart';
export 'models/core_objects/camper.dart';
export 'models/core_objects/schedule.dart';
export 'models/core_objects/schedule_day.dart';
export 'models/core_objects/core_user.dart';
export 'services/activity_preference_service.dart';
export 'services/cabin_service.dart';
export 'services/context_service.dart';
export 'services/console_service.dart';
export 'services/io_service.dart';
export 'services/assignment_service.dart';
export 'services/commit_service.dart';
export 'services/schedule_service.dart';
export 'services/roster_service.dart';
export 'services/user_service.dart';
export 'utils/id_functions.dart';
export 'utils/helper_functions.dart';
export 'utils/formatter.dart';
export 'utils/model_helper_functions.dart';
export 'commands/core_commands.dart';
export 'utils/date_time_helpers.dart';
export 'validators/bess_id_validation.dart';
export 'validators/input_validation.dart';
export 'repositories/commit_repository.dart';
export 'repositories/pull_repository.dart';


export 'models/commit.dart';
export 'models/preference_choice.dart';
export 'models/roster_group.dart';
export 'models/roster_field.dart';

// enums
export 'models/enums.dart';

class EmberCore {
  static void init (CoreFrontend frontendInterface) {
    FrontendManager.setFrontend(frontendInterface);
    Get.put(ClientContext(), permanent: true);
    Get.put(AuthenticationRepository(), permanent: true);
    Get.put(UserService(), permanent: true);
    frontendInterface.init();
  }

  static Future<void> onLogin() async {
    Get.put(CommitService(), permanent: true);
    Get.put(PullRepository(), permanent: true);
    Get.put(PathService(), permanent: true);
    final CommitRepository commitRepo = Get.put(CommitRepository(), permanent: true);
    ContextService contextService = Get.put(ContextService(), permanent: true);
    await contextService.setDefaultContext();
    Get.put(ContextlessRepository(), permanent: true);
    Get.put(CabinService(), permanent: true);
    Get.put(LiveDataRepository(), permanent: true);
    Get.put(IOService(), permanent: true);
    Get.put(RosterService(), permanent: true);
    Get.put(ActivityPreferenceService(), permanent: true);
    Get.put(ScheduleService(), permanent: true);
    Get.put(AssignmentService(), permanent: true);
    final DatabaseRepairService repairService = Get.put(DatabaseRepairService(), permanent: true);
    onNewContext(repairService, commitRepo);
  }

  static Future<void> onNewContext(DatabaseRepairService repairService, CommitRepository commitRepo) async {
    // Commit commit = Commit(disarmRequirementsLevel: 0);
    // await Get.find<DatabaseRepairService>().cleanOrphanedDependents(commit, await Get.find<ContextService>().session);
    // commit.disarm(); // not good practice but this operation needs to happen regardless if the user confirms or not since it is an extension of an already confirmed action
    // Get.find<CommitRepository>().commit(commit);
  }

}

class FireStarter {
  static bool _isInitialized = false; // Simple flag to track initialization

  static Future<void> initialize() async {
    // Prevent multiple initializations
    if (_isInitialized) {
      Debug.logInfo('Firebase already initialized.');
      return;
    }

    try {
      Debug.logInfo('Initializing Firebase...');
      // Ensure WidgetsFlutterBinding is initialized BEFORE Firebase.initializeApp
      // This is usually done in main(), but adding here for safety if called elsewhere.
      // WidgetsFlutterBinding.ensureInitialized(); // Uncomment if needed, but best practice is in main()

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _isInitialized = true; // Mark as initialized SUCCESSFULLY
      Debug.logInfo('Firebase initialized successfully.');

      // --- Firestore specific setup ---
      final db = FirebaseFirestore.instance;

      // Firestore Emulator Setup (Consider platform differences)
      // Emulator is typically not used in production or web deployment.
      // `kIsWeb` helps differentiate web builds.
      if (Debug.useFirestoreEmulator) {
        try {
          print("Attempting to use Firestore Emulator...");
          // Ensure host is correct, especially if not running locally (e.g., Docker)
          db.useFirestoreEmulator('localhost', 6200);
          print("Using Firestore Emulator.");
        } catch (e) {
          print(
            "WARNING: Failed to connect to Firestore emulator at localhost:6200. "
                "Ensure it's running. Falling back to cloud Firestore. Error: $e",
          );
          // Decide if this error should prevent app startup or just log a warning.
        }
      }

      // Persistence Settings (Can have browser limitations)
      // Consider enabling only if needed and test cross-browser compatibility.
      // if (kIsWeb) {
      //   try {
      //     await db.enablePersistence(
      //       const PersistenceSettings(synchronizeTabs: true),
      //     );
      //     Debug.logInfo('Firestore persistence with tab synchronization enabled (Web).');
      //   } catch (e) {
      //     Debug.logInfo('Firestore Web Persistence failed: $e');
      //   }
      // } else {
      //    // Mobile persistence settings if needed
      //    // db.settings = const Settings(persistenceEnabled: true, cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED);
      //    Debug.logInfo('Firestore persistence enabled (Mobile).');
      // }
      // --- End Firestore specific setup ---
    } catch (e) {
      Debug.logInfo('-----------------------------------------');
      Debug.logInfo('FATAL: Error initializing Firebase: $e');
      Debug.logInfo('-----------------------------------------');
      // Depending on your app, you might want to rethrow the error
      // or show a user-friendly error message and prevent app continuation.
      _isInitialized =
      false; // Ensure it's marked as not initialized on failure
      rethrow; // Rethrow to indicate critical failure
    }
  }

  // Optional: Getter to check status from outside
  static bool get isInitialized => _isInitialized;
}