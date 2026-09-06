import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../ember_core.dart';
import '../services/path_service.dart';

/// A generic repository for live-updating Firestore data.
class LiveDataRepository {
  PullRepository pullRepo = Get.find<PullRepository>();
  final FirebaseFirestore _db = Get.find<PullRepository>().db;
  final PathService pathService = Get.find<PathService>();

  /// Watches a single Firestore document by its full [documentPath].
  /// Parses it into [T] via [fromJson]. If the doc doesn't exist, emits `null`.
  Stream<T?> watchDoc<T>({
    required String documentPath,
    required T Function(Map<String, dynamic> json) fromJson,
  }) {
    final resolvedPath = documentPath; // Assuming direct path

    return _db.doc(resolvedPath).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      try {
        final data = snapshot.data() as Map<String, dynamic>;
        return fromJson(data);
      } catch (e) {
        print("Error parsing document ${snapshot.id}: $e");
        return null;
      }
    });
  }

  /// Watches a Firestore collection identified by [collectionName] and [domain].
  /// The actual path is resolved via [pathService].
  /// Parses documents into [T] via [fromJson], returning a Stream of Map String, T.
  /// Optional [queryBuilder] can be provided to filter/order the collection.
  ///
  /// - If [updateDataInRealtime] is true (default): Emits a new Map whenever
  ///   documents are added, removed, OR modified. Document data is always fresh.
  /// - If [updateDataInRealtime] is false: Emits a new Map ONLY when documents
  ///   are added or removed (membership changes). The data for the documents
  ///   in the Map is fetched once at the time of the membership change and
  ///   will not update in real-time if the document content changes later.
  Future<Stream<Map<String, T>>> watchCollection<T>({
    required String collectionName,
    required String domain,
    bool updateDataInRealtime = true,
    // Optional: Re-add if you need custom queries beyond the base collection path
    // Query<Map<String, dynamic>> Function(Query<Map<String, dynamic>> query)? queryBuilder,
  }) async {
    // Resolve the collection path using the provided service
    final String resolvedPath = await pathService.getCollectionPath(collectionName, domain);
    Query<Map<String, dynamic>> query = _db.collection(resolvedPath);

    // Optional: Apply custom query modifications if queryBuilder is used
    // if (queryBuilder != null) {
    //   query = queryBuilder(query);
    // }

    if (updateDataInRealtime) {
      // --- Mode 1: Real-time data updates ---
      return query.snapshots().map((snapshot) {
        final resultMap = <String, T>{};
        for (final doc in snapshot.docs) {
          // Ensure doc exists and data is not null before parsing
          if (doc.exists) {
            try {
              // Pass the document ID and data to the provided fromJson function
              final parsedObject = CoreObject.fromJson(doc.data());
              resultMap[doc.id] = parsedObject;
            } catch (e) {
              print("Error parsing document ${doc.id} (realtime) in collection $collectionName ($domain): $e");
              // Decide how to handle parse errors (e.g., skip the doc, log, etc.)
            }
          }
        }
        // Debug print (optional)
        // print("WATCH COLLECTION (Realtime): Emitting Map with ${resultMap.length} docs for $collectionName ($domain)");
        return resultMap;
      });
    } else {
      // --- Mode 2: Only update Map on membership changes ---
      return query.snapshots()
      // 1. Map snapshots to the set of document IDs.
          .map((snapshot) => snapshot.docs.map((doc) => doc.id).toSet())
      // 2. Use distinct to filter out emissions where the set of IDs hasn't changed.
          .distinct((previousIds, currentIds) =>
      previousIds.length == currentIds.length && previousIds.containsAll(currentIds))
      // 3. When the distinct set of IDs is emitted, trigger a one-time fetch (`get()`).
          .asyncMap((_) async {
        // Debug print (optional)
        // print("WATCH COLLECTION (Membership Changed - Fetching Data): Fetching $collectionName ($domain)");
        final currentSnapshot = await query.get();
        final resultMap = <String, T>{};
        for (final doc in currentSnapshot.docs) {
          // Ensure doc exists and data is not null before parsing
          if (doc.exists) {
            try {
              // Pass the document ID and data to the provided fromJson function
              final parsedObject = CoreObject.fromJson(doc.data());
              resultMap[doc.id] = parsedObject;
            } catch (e) {
              print("Error parsing document ${doc.id} (snapshot fetch) in collection $collectionName ($domain): $e");
              // Decide how to handle parse errors
            }
          }
        }
        // Debug print (optional)
        // print("WATCH COLLECTION (Membership Changed - Fetching Data): Emitting Map with ${resultMap.length} docs for $collectionName ($domain)");
        return resultMap;
      });
    }
  }
}
