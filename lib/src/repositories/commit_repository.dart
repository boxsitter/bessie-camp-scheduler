import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bessie/src/repositories/pull_repository.dart';
import 'package:get/get.dart';


import '../ember_core.dart';
import '../services/database_repair_service.dart';
import '../services/path_service.dart';

class CommitRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final PullRepository pullRepo = Get.find<PullRepository>();
  ContextService get clientContextService => Get.find<ContextService>();
  final PathService pathService = Get.find<PathService>();
  CommitService requestService = Get.find<CommitService>();

  FirebaseFirestore get db => _db;

  /// Efficiently applies create/update (push) and delete operations to Firestore
  /// using batched writes, processing directly from the input Sets.
  Future<void> _bulkApplyChanges({
    required Set<CoreObject> objectsToPush,
    required Set<CoreObject> objectsToDelete,
  }) async {
    if (objectsToPush.isEmpty && objectsToDelete.isEmpty) {
      Debug.logInfo('Bulk Apply: No objects to push or delete.');
      return;
    }

    Debug.logInfo('Bulk Apply: Starting. Processing ${objectsToPush.length} pushes and ${objectsToDelete.length} deletes.');

    // --- Parallel Path Resolution ---
    // Resolve all paths at once to avoid awaiting inside the loop.
    final pushPathFutures = objectsToPush.map((obj) => pathService.getDocPathFromId(obj.id).then((path) => {'obj': obj, 'path': path})).toList();
    final deletePathFutures = objectsToDelete.map((obj) => pathService.getDocPathFromId(obj.id).then((path) => {'obj': obj, 'path': path})).toList();

    final pushResults = await Future.wait(pushPathFutures);
    final deleteResults = await Future.wait(deletePathFutures);

    // --- Batch Processing ---
    final allOps = [
      ...pushResults.map((r) => {'type': 'push', ...r}),
      ...deleteResults.map((r) => {'type': 'delete', ...r}),
    ];

    int batchesCommitted = 0;
    int totalOpsCommitted = 0;
    const int maxBatchSize = 500; // Firestore limit

    for (int i = 0; i < allOps.length; i += maxBatchSize) {
      WriteBatch batch = _db.batch();
      int pushesInBatch = 0;
      int deletesInBatch = 0;
      final batchNum = batchesCommitted + 1;

      final sublist = allOps.sublist(i, i + maxBatchSize > allOps.length ? allOps.length : i + maxBatchSize);

      for (final op in sublist) {
        final CoreObject coreObject = op['obj'] as CoreObject;
        final String path = op['path'] as String;

        try {
        if (path.isNotEmpty && !path.contains('//') && path.split('/').length % 2 == 0) {
          final docRef = _db.doc(path);
          if (op['type'] == 'push') {
            Map<String, dynamic> document = coreObject.toJson();
            CoreHelperFunctions.updateDocumentTimestamp(document);

              batch.set(docRef, document, SetOptions(merge: true));
            pushesInBatch++;
            } else if (op['type'] == 'delete') {
            batch.delete(docRef);
            deletesInBatch++;
          }
          } else {
          Debug.logInfo('Warning (Batch #$batchNum): Invalid path "$path" for object ID "${coreObject.id}". Skipping.');
          }
        } catch (e) {
          Debug.logInfo('Error processing object ID "${coreObject.id}" in batch #$batchNum: $e. Skipping.');
        }
      }

      if (pushesInBatch > 0 || deletesInBatch > 0) {
        try {
          Debug.logInfo('Bulk Apply: Committing batch #$batchNum ($pushesInBatch pushes, $deletesInBatch deletes)...');
          await batch.commit();
          totalOpsCommitted += (pushesInBatch + deletesInBatch);
          batchesCommitted++;
          Debug.logInfo('Bulk Apply: Batch #$batchesCommitted committed successfully.');
        } catch (e) {
          Debug.logInfo('Error committing Firestore batch #$batchNum: $e');
          rethrow;
        }
      } else {
        Debug.logInfo('Bulk Apply: Batch #$batchNum contained no valid operations to commit.');
      }
    }
    Debug.logInfo('Bulk Apply: Finished. $totalOpsCommitted operations committed across $batchesCommitted batch(es).');
  }

  Future<bool> commit(Commit commit) async {
    DatabaseRepairService repairService = Get.find<DatabaseRepairService>();

    if (commit.objectsToPush.isEmpty && commit.objectsToDelete.isEmpty) {
      Debug.logInfo('Nothing to commit!');
      return false;
    }

    if (!await requestService.disarmCommit(commit)) {
      Debug.logInfo('Operation cannot proceed');
      return false;
    }

    // if the commit is intended to be merged rather than pushed, do that
    if (commit.merge && commit.objectsToPush.isNotEmpty) {
      final objectsToMerge = commit.objectsToPush.values.toSet();
      commit.objectsToPush.clear();
      await repairService.mergeObjectsWithDatabase(
        commit: commit,
        objects: objectsToMerge,
        prioritizeAFields: true,
        prioritizeAValues: true,
        overwriteWithEmptyAValues: false,
        aFieldsToIgnore: {'createdAt'},
      );
    }

    bool containsOnlyDomain = false;
    if (commit.objectsToPush.length == 1 && commit.objectsToDelete.isEmpty) {
      for (CoreObject object in commit.objectsToPush.values) {
        if (object is Domain) {
          containsOnlyDomain = true;
        }
      }
    }

    // Don't update ref tracker if the commit only has a domain in it
    if (!containsOnlyDomain) {
      Set<CoreObject> ignore = {};
      Set<CoreObject> objectsToDeleteSnapshot = commit.objectsToDelete.values.toSet();
      for (CoreObject object in objectsToDeleteSnapshot) {
        await _cleanBeforeDelete(commit, object, ignore);
        ignore.add(object);
      }

      Session newSession = commit.getObjectOfType<Session>() ?? await clientContextService.session;
      await Future.wait([
        Future(() => _updateRefTracker(newSession.refTracker, commit.objectsToPush.values.toSet())),
        Future(() => _updatePrincipalDependentLinkTracker(newSession.principalDependentLinkTracker, commit.objectsToPush.values.toSet())),
      ]);
      commit.addObjectToPush(newSession);
    }

    await _bulkApplyChanges(objectsToPush: commit.objectsToPush.values.toSet(), objectsToDelete: commit.objectsToDelete.values.toSet());
    return true;
  }

  static void _updateRefTracker(Map<String, Set<String>> refTracker, Set<CoreObject> objects) {
    final Set<Map<String, dynamic>> documents = objects.map((element) => element.toJson()).toSet();
    // Process each document to update the tracker.
    for (final Map<String, dynamic>doc in documents) {
      final String docId = doc['id'] as String;
      // Extract the set of referenced IDs from the document.
      final Set<String> currentRefs = _thisDocumentReferences(doc, docId);
      // Remove stale references:
      // For each key in the tracker, if the doc's id is present but the key is no longer referenced in the doc, remove it.
      for (final String key in refTracker.keys.toList()) {
        if (refTracker[key]!.contains(docId) && !currentRefs.contains(key)) {
          refTracker[key]!.remove(docId);
        }
      }

      // Add missing references:
      // For each referenced id in the document, ensure that the doc's id is added to the tracker.
      for (final id in currentRefs) {
        refTracker.putIfAbsent(id, () => <String>{}).add(docId);
      }
    }

    // Remove unreferenced objects:
    // Delete any tracker entry whose set is empty.
    refTracker.removeWhere((key, set) => set.isEmpty);
  }

  static void _updatePrincipalDependentLinkTracker(Map<PrincipalId, Set<DependentId>> linkTracker, Set<CoreObject> objects) {
    for (CoreObject coreObject in objects) {
      if (coreObject is Dependent) {
        Dependent dependent = coreObject as Dependent;
        if (linkTracker.containsKey(dependent.principalPar)) {
          linkTracker[dependent.principalPar]?.add(coreObject.id);
        } else {
          linkTracker[dependent.principalPar] = {coreObject.id};
        }
      }
    }
  }

  static Set<String> _thisDocumentReferences(Map<String, dynamic> document, String thisDocId) {
    Set<String> output = _collectReferences(document.values.toList());
    output.remove(thisDocId);
    return output;
  }

  static Set<String> _collectReferences(dynamic item) {
    Set<String> referencedIds = {};

    // Base case: if the item itself is a valid reference
    if (item is String && CoreIdValidation.isPotentialId(item)) {
      referencedIds.add(item);
    } else if (item is List) {
      // Recursively process each element in the list
      for (var element in item) {
        referencedIds.addAll(_collectReferences(element));
      }
    } else if (item is Map) {
      // Recursively process each value in the map
      for (var value in item.values) {
        referencedIds.addAll(_collectReferences(value));
      }
    }

    return referencedIds;
  }

  Future<void> _cleanBeforeDelete(Commit commit, CoreObject objectToDelete, Set<CoreObject> ignore) async {
    if (ignore.contains(objectToDelete)) {
      return;
    }

    if (objectToDelete is Domain) {
      commit.addObjectToDelete(objectToDelete);
      return;
    }

    // --- Modification starts here ---
    Set<String> componentIds = _getCmps(objectToDelete.toJson());
    // Create a list of futures to run in parallel
    List<Future<void>> deleteComponentFutures = [];

    for (String id in componentIds) {
      // Each component's cleaning process is added as a future to the list.
      deleteComponentFutures.add(() async {
        CoreObject? componentObject;
        try {
          // Fetch the object first.
          componentObject = commit.getObject(id) ?? await pullRepo.getObject(id);

          if (componentObject != null) {
            // Recursively call _cleanBeforeDelete.
            await _cleanBeforeDelete(commit, componentObject, ignore);
          } else {
            Debug.logInfo('Warning: Could not find or fetch component object for ID $id during pre-delete cleaning.');
          }

        } catch (error) {
          print("Error processing component $id during pre-delete cleaning: $error");
        }
      }()); // Immediately invoke the async anonymous function
    }

    // Wait for all the parallel component cleaning operations to complete.
    if (deleteComponentFutures.isNotEmpty) {
      await Future.wait(deleteComponentFutures);
    }
    // --- Modification ends here ---


    Session session = commit.getObjectOfType<Session>() ?? await clientContextService.session;
    commit.addObjectToPush(session);
    Set<String>? objectsToPurgeIds = session.refTracker[objectToDelete.id];
    objectsToPurgeIds?.remove(objectToDelete.id); // I have no idea if it can end up in there but it's an easy check

    if (objectsToPurgeIds == null) {
      commit.addObjectToDelete(objectToDelete);
      return;
    }

    // This part can also be parallelized
    final purgeFutures = objectsToPurgeIds.map((id) async {
      if (!commit.objectsToDelete.containsKey(id) && id != objectToDelete.id) {
        CoreObject? objectToPurge = commit.getObject(id) ?? await pullRepo.getObject(id);
        if(objectToPurge != null){
        objectToPurge.purgeRef(objectToDelete.id);
        commit.addObjectToPush(objectToPurge);
      }
      }
    });

    await Future.wait(purgeFutures);

    commit.addObjectToDelete(objectToDelete);
  }

  Set<String> _getCmps(Map<String, dynamic> json) {
    final Set<String> output = {};

    json.forEach((key, value) {
      final String lowerKey = key.toLowerCase();
      if (lowerKey.endsWith("cmp") || lowerKey.endsWith("cmps")) {
        if (value is String) {
          output.add(value);
        } else if (value is List) {
          for (var element in value) {
            if (element is String) {
              output.add(element);
            }
          }
        }
      }
    });

    return output;
  }
}

