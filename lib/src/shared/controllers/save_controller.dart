// import 'dart:async';
// import 'dart:collection';
//
// import 'package:bessie/src/ember_core.dart';
// import 'package:get/get.dart';
//
// class SaveController extends GetxController {
//   final CommitRepository commitRepo = Get.find<CommitRepository>();
//   final Queue<Commit> _commitQueue = Queue<Commit>();
//   Timer? _autosaveTimer;
//   bool isSaving = false;
//   bool isAutoSaving = false;
//
//   bool get queueIsEmpty => _commitQueue.isEmpty;
//
//   // You can adjust the autosave duration as needed
//   final Duration _autosaveDuration = const Duration(seconds: 30);
//
//   @override
//   void onInit() {
//     super.onInit();
//     _startAutosaveTimer();
//   }
//
//   @override
//   void onClose() {
//     _autosaveTimer?.cancel();
//     super.onClose();
//   }
//
//   /// Adds a [Commit] to the queue to be saved.
//   void addCommitToQueue(Commit commit) {
//     _commitQueue.add(commit);
//   }
//
//   /// Merges all commits in the queue and saves them.
//   Future<void> save({bool? isAutoSave}) async {
//     if (_commitQueue.isEmpty) {
//       Debug.logInfo('SaveController: No commits to save.');
//       return;
//     }
//     if (isAutoSave == true) {
//       isAutoSaving = true;
//     } else {
//       isSaving = true;
//     }
//     update();
//
//     // Create a single commit to merge all queued commits into.
//     final mergedCommit = Commit(disarmRequirementsLevel: 0); // Or appropriate level
//
//     for (final commit in _commitQueue) {
//       // Merge objects to push
//       commit.objectsToPush.forEach((id, object) {
//         mergedCommit.addObjectToPush(object);
//       });
//
//       // Merge objects to delete
//       commit.objectsToDelete.forEach((id, object) {
//         mergedCommit.addObjectToDelete(object);
//       });
//     }
//
//     // Ensure consistency: if an object is marked for deletion, it shouldn't also be pushed.
//     for (final id in mergedCommit.objectsToDelete.keys) {
//       if (mergedCommit.objectsToPush.containsKey(id)) {
//         mergedCommit.objectsToPush.remove(id);
//       }
//     }
//
//     if (mergedCommit.objectsToPush.isEmpty && mergedCommit.objectsToDelete.isEmpty) {
//       Debug.logInfo('SaveController: Merged commit is empty, nothing to save.');
//       _commitQueue.clear();
//       return;
//     }
//
//     Debug.logInfo('SaveController: Saving merged commit.');
//     final success = await commitRepo.commit(mergedCommit);
//     await Future.delayed(Duration(seconds: 3)); // todo: remove
//     if (success) {
//       _commitQueue.clear();
//       Debug.logInfo('SaveController: Save successful.');
//     } else {
//       Debug.logInfo('SaveController: Save failed. Commits remain in queue.');
//     }
//     if (isAutoSave == true) {
//       isAutoSaving = false;
//     } else {
//       isSaving = false;
//     }
//     update();
//   }
//
//   void _startAutosaveTimer() {
//     _autosaveTimer = Timer.periodic(_autosaveDuration, (timer) {
//       Debug.logInfo('SaveController: Autosave triggered.');
//       save(isAutoSave: true);
//     });
//   }
// }
