import 'dart:collection';

import 'package:bessie/src/shared/mixins/route_aware_controller_mixin.dart';
import 'package:bessie/src/shared/utils/helpers/helper_functions.dart';
import 'package:bessie/src/ember_core.dart';
import 'package:get/get.dart';

class SessionManagerController extends GetxController with RouteAwareControllerMixin {
  final CabinService cabinsService = Get.find<CabinService>();
  final CommitRepository commitRepo = Get.find<CommitRepository>();

  // --- State Variables (No longer Rx) ---
  Map<String, String> cabinPrinIdsToNames = {};
  Set<String> selectedCabinPrinIds = {};
  bool isLoading = true;

  @override
  Future<void> onNavigateTo(String to, String? from) async {
    isLoading = true;
    update();

    cabinPrinIdsToNames.clear();
    selectedCabinPrinIds.clear();

    Map<String, String> rawData = await cabinsService.getPrincipalCabinNames();
    List<MapEntry<String, String>> sortedEntries = rawData.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    cabinPrinIdsToNames = LinkedHashMap.fromEntries(sortedEntries);

    selectedCabinPrinIds = (await cabinsService.getCabinDependentIdsToPrincipalIds()).values.toSet();
    isLoading = false;
    update();
  }


  // Method called by the UI when a checkbox is tapped
  void toggleCabinSelection(String cabinPrinId) {
    if (selectedCabinPrinIds.contains(cabinPrinId)) {
      selectedCabinPrinIds.remove(cabinPrinId);
      Debug.logInfo('$cabinPrinId selection is now: false');
    } else {
      selectedCabinPrinIds.add(cabinPrinId);
      Debug.logInfo('$cabinPrinId selection is now: true');
    }
    update(); // Notify UI of selection change
  }

  Future<void> commitSelection() async {
    Set<String> registeredPrinCabinIds = await cabinsService.getRegisteredPrincipalCabinIds();
    Commit commit = Commit(disarmRequirementsLevel: 1, confirmationMessage: 'Warning: Deregistering cabins will delete them and remove campers from those cabins. This cannot be undone!');

    for (String selectedCabinPrinId in selectedCabinPrinIds) {
      if (!registeredPrinCabinIds.contains(selectedCabinPrinId)) {
        await cabinsService.registerCabinToSessionFromId(commit, selectedCabinPrinId);
      }
    }

    // for each current registered cabin prin id
    for (String registeredPrinCabinId in registeredPrinCabinIds) {
      if (!selectedCabinPrinIds.contains(registeredPrinCabinId)) {
        final Map<String, String> cabinPrincipalIdsToDependentIds = BessHelperFunctions.transposeMap(await cabinsService.getCabinDependentIdsToPrincipalIds());
        commit.addObjectToDelete(commit.getObject(cabinPrincipalIdsToDependentIds[registeredPrinCabinId]) ?? await cabinsService.getDependantCabin(cabinPrincipalIdsToDependentIds[registeredPrinCabinId]!));
      }
    }

    commitRepo.commit(commit);
  }
}
