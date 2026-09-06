import 'package:bessie/src/ember_core.dart';
import 'package:get/get.dart';

class SessionSelectorController extends GetxController {
  // Observable for the currently selected session key in the dropdown
  final RxnString selectedSessionKey = RxnString(); // Nullable observable

  // --- State Variables ---
  // Holds the session data fetched from the service
  final sessions = Rx<Map<String, String>>({});
  // Manages the loading state to show a progress indicator in the UI
  final isLoading = true.obs;

  final RxString sessionName = RxString('loading...');
  final RxString seasonName = RxString('loading...');

  /// Called automatically when the controller is initialized.
  @override
  void onInit() {
    super.onInit();
    _fetchSessions();
    setSessionName();
    setSeasonName();
  }

  /// Fetches the session names from the ContextService and updates the state.
  Future<void> _fetchSessions() async {
    // Set loading to true before fetching
    isLoading.value = true;
    // Fetch the data from the service (no mapping needed)
    sessions.value = await Get.find<ContextService>().getSessionNames();
    isLoading.value = false;
  }

  // Method to update the selection from the dropdown
  void updateSelection(String? key) {
    selectedSessionKey.value = key;
  }

  /// Called by the "Switch" button to perform the migration.
  Future<void> migrateToSelectedContext() async {
    final selectedId = selectedSessionKey.value;
    if (selectedId != null) {
      // Call the existing migrateContext method from your service
      await Get.find<ContextService>().migrateContext(selectedId);
    }
  }

  Future<void> setSessionName() async {
    sessionName.value = await Get.find<ContextService>().sessionName;
  }

  Future<void> setSeasonName() async {
    seasonName.value = await Get.find<ContextService>().seasonName;
  }
}
