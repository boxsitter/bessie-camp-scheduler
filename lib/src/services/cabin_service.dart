import 'package:get/get.dart';

import '../ember_core.dart';

class CabinService extends GetxService {
  CommitService requestService = Get.find<CommitService>();
  PullRepository pullRepo = Get.find<PullRepository>();

  Future<Set<CabinDependent>> get cabinDependents async =>
      (await pullRepo.getObjectsInCollection<CabinDependent>('cabin_dependent', 'ses')).values.toSet();
  Future<Map<String, PrincipalCabin>> get principalCabins async =>
      await pullRepo.getObjectsInCollection<PrincipalCabin>('principal_cabin', 'brn');

  Future<String?> getCabinDependentIdByName(String name, Commit commit) async {
    String? principalId = commit.queryFieldByType(PrincipalCabin, 'name', name);
    if (principalId != null) {
      return commit.queryFieldByType(CabinDependent, 'principalPar', principalId);
    }

    // TODO: The code for caching cabins in the push request is rough, clean it up
    principalId = await pullRepo.queryField('principal_cabin', 'brn', 'name', name);
    String? output;
    if (principalId != null) {
      commit.addObjectToPush(await pullRepo.getObject(principalId));
      output = await pullRepo.queryField('cabin_dependent', 'ses', 'principalPar', principalId);
    }

    if (output != null) {
      commit.addObjectToPush(await pullRepo.getObject(output));
    }

    return output;
  }

  Future<Set<Camper>> getCampersInCabin(String id) async {
    Set<String> camperIds = await pullRepo.getSetFieldValue(id, 'camperRefs');
    return await pullRepo.getObjects(camperIds);
  }

  Future<Map<String, String>> getPrincipalCabinNames() async {
    final rawData = await pullRepo.getFieldFromCollection('principal_cabin', 'brn', 'name');
    Map<String, String> valuesToString = rawData.map((key, value) => MapEntry(key, value as String));
    return valuesToString;
  }

  Future<PrincipalCabin> getPrincipalCabin(String id) {
    // TODO: check and make sure id points to a prin cabin
    return pullRepo.getObject(id);
  }

  Future<PrincipalCabin> getDependantCabin(String id) {
    // TODO: check and make sure id points to a cabin dep
    return pullRepo.getObject(id);
  }

  Future<Map<String, String>> getCabinDependentIdsToPrincipalIds() async {
    final rawData = await pullRepo.getFieldFromCollection('cabin_dependent', 'ses', 'principalPar');
    Map<String, String> valuesToString = rawData.map((key, value) => MapEntry(key, value as String));
    return valuesToString;
  }

  Future<Map<CabinDependent, PrincipalCabin>> getCabinDependentToPrincipalCabins() async {
    final results = await Future.wait([this.cabinDependents, this.principalCabins]);

    Set<CabinDependent> cabinDependents = results[0] as Set<CabinDependent>;
    Set<PrincipalCabin> principalCabins = (results[1] as Map<String, PrincipalCabin>).values.toSet();
    Map<CabinDependent, PrincipalCabin> output = {};

    Map<String, PrincipalCabin> principalCabinsById = {for (var principal in principalCabins) principal.id: principal};

    for (var dependent in cabinDependents) {
      PrincipalCabin? matchingPrincipal = principalCabinsById[dependent.principalPar];

      if (matchingPrincipal != null) {
        output[dependent] = matchingPrincipal;
      }
    }

    // Return the resulting map
    return output;
  }

  Future<Set<String>> getRegisteredPrincipalCabinIds() async {
    final rawData = await pullRepo.getFieldFromCollection('cabin_dependent', 'ses', 'principalPar');
    Set<dynamic> dynamicSet = rawData.values.toSet();
    Set<String> stringSet = {};
    for (var item in dynamicSet) {
      stringSet.add(item as String);
    }
    return stringSet;
  }

  void createPrincipalCabin(Commit commit, String name, int capacity, String village, int index) {
    PrincipalCabin cabinToCreate = PrincipalCabin(name: name, capacity: capacity, village: village, index: index);
    commit.addObjectToPush(cabinToCreate);
  }

  // Future<DeleteRequest> deleteBranchCabin() {
  //   // TODO: implement this
  // }

  Future<void> registerCabinToSession(Commit commit, PrincipalCabin principalCabin) async {
    if ((await getRegisteredPrincipalCabinIds()).contains(principalCabin.id)) {
      Debug.logInfo('This cabin is already registered to this session');
      return;
    }
    CabinDependent cabinToRegister = CabinDependent(principalPar: principalCabin.id);
    commit.addObjectToPush(cabinToRegister);
  }

  Future<void> registerCabinToSessionFromId(Commit commit, String principalCabinId) async {
    PrincipalCabin principalCabin = commit.getObject(principalCabinId) ?? await pullRepo.getObject(principalCabinId);
    await registerCabinToSession(commit, principalCabin);
  }

  // Future<DeleteRequest> unregisterCabinDependent() {
  //   // TODO: implement this
  // }

  // packages/ember_core/lib/src/services/cabin_service.dart

  /// Robustly assigns a camper to a specific cabin, handling re-assignment.
  ///
  /// This method ensures a consistent state by first removing the camper from
  /// their current cabin (if any) before adding them to the new one.
  Future<void> addCamperToCabin(Commit commit, String cabinDependentId, String camperId) async {
    final CabinDependent cabinDependent = commit.getObject(cabinDependentId) ?? await pullRepo.getObject(cabinDependentId);
    final PrincipalCabin principalCabin =
        commit.getObject(cabinDependent.principalPar) ?? await pullRepo.getObject(cabinDependent.principalPar);
    final Camper camperToAdd = commit.getObject(camperId) ?? await pullRepo.getObject(camperId);

    // 2. Check if the camper is already in the target cabin. If so, do nothing.
    if (camperToAdd.cabinRef == cabinDependentId) {
      Debug.logInfo('Info: ${camperToAdd.fullName} is already in cabin ${principalCabin.title}. No action needed.');
      return;
    }

    // 3. Handle re-assignment: If the camper is currently in a different cabin, remove them first.
    if (camperToAdd.cabinRef != null) {
      Debug.logInfo(
        'Info: ${camperToAdd.fullName} is being moved from another cabin. Removing from old cabin first.',
        userMessage: '${camperToAdd.fullName} is being moved to ${principalCabin.title}.',
      );
      final oldCabinDependent =
          commit.getObject<CabinDependent>(camperToAdd.cabinRef!) ??
          await pullRepo.getObject<CabinDependent>(camperToAdd.cabinRef!);
      await removeCamperFromCabin(commit, oldCabinDependent.id, camperToAdd.id);
    }

    // // 4. Check for capacity before adding.
    // if (cabinDependent.camperRefs.length >= principalCabin.capacity) {
    //   throw StateError(
    //     'Can\'t add camper: ${camperToAdd.fullName} to cabin ${principalCabin.title} because it will put it over capacity.',
    //   );
    // }

    // 5. Perform the assignment and update object states.
    cabinDependent.camperRefs.add(camperToAdd.id);
    camperToAdd.cabinRef = cabinDependent.id;
    camperToAdd.cabinName = principalCabin.title;

    // 6. Add the modified objects to the commit.
    commit.addObjectsToPush({cabinDependent, camperToAdd});
    Debug.logSuccess(
      '${camperToAdd.fullName} successfully assigned to cabin ${principalCabin.title}.',
      userMessage: 'Success! ${camperToAdd.fullName} has been assigned to ${principalCabin.title}.',
    );
  }

  /// Robustly removes a camper from a specific cabin.
  ///
  /// This method enforces a consistent state by ensuring the camper is removed
  /// from the cabin's roster AND the cabin is removed from the camper's reference.
  Future<void> removeCamperFromCabin(Commit commit, String cabinDependentId, String camperId) async {
    // 1. Fetch the latest state of objects from the commit or repo.
    final CabinDependent cabinDep = commit.getObject(cabinDependentId) ?? await pullRepo.getObject(cabinDependentId);
    final Camper camperToRemove = commit.getObject(camperId) ?? await pullRepo.getObject(camperId);

    bool cabinChanged = false;
    bool camperChanged = false;

    // 2. Unconditionally remove the reference from the cabin's roster.
    if (cabinDep.camperRefs.remove(camperToRemove.id)) {
      cabinChanged = true;
    }

    // 3. Unconditionally remove the reference from the camper's assignment.
    if (camperToRemove.cabinRef != null) {
      camperToRemove.cabinRef = null;
      camperToRemove.cabinName = null;
      camperChanged = true;
    }

    // 4. If any change occurred, add the affected objects to the commit.
    if (camperChanged || cabinChanged) {
      commit.addObjectsToPush({if (camperChanged) camperToRemove, if (cabinChanged) cabinDep});
      Debug.logSuccess(
        '${camperToRemove.fullName} removed from cabin. State synchronized.',
        userMessage: 'Success! ${camperToRemove.fullName} has been removed from their cabin.',
      );
    } else {
      Debug.logInfo('Info: Attempted to remove ${camperToRemove.fullName} from cabin, but no assignment links were found.');
    }
  }
}
