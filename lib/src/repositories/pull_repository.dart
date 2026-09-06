import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:get/get.dart';

import '../ember_core.dart';
import '../services/path_service.dart';

class PullRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  PathService get pathService => Get.find<PathService>();

  FirebaseFirestore get db => _db;

  Future<bool> docExists(String id) async {
    final resolvedPath = await pathService.getDocPathFromId(id);
    Debug.logInfo('Getting doc: $id');

    try {
      final docSnapshot = await _db.doc(resolvedPath).get();
      // If doc doesn't exist or doc.data() is null, return empty map
      if (!docSnapshot.exists || docSnapshot.data() == null) {
        return false;
      } else {
        return true;
      }
    } on FirebaseException catch (e) {
      Debug.logInfo('Error fetching document at $resolvedPath: ${e.message}');
      rethrow;
    } catch (e) {
      // Handle all other errors
      Debug.logInfo('Error fetching document at $resolvedPath: $e');
      rethrow;
    }
  }

  /// Retrieves a document from Firestore for the given [id] using the resolved document path.
  /// Returns a map of the document data if it exists, or null if it doesn't.
  /// Throws an error if there is an issue during retrieval.
  Future<Map<String, dynamic>> getDoc(String id) async {
    final resolvedPath = await pathService.getDocPathFromId(id);
    Debug.logInfo('Getting doc: $id');

    try {
      final docSnapshot = await _db.doc(resolvedPath).get();

      // If doc doesn't exist or doc.data() is null, return empty map
      if (!docSnapshot.exists || docSnapshot.data() == null) {
        return {};
      }

      // Convert timestamps in the final data map
      final data = docSnapshot.data()!;
      // REMOVE THE LINE BELOW
      // convertToDateTime(data);
      return data;
    } on FirebaseException catch (e) {
      Debug.logInfo('Error fetching document at $resolvedPath: ${e.message}');
      rethrow;
    } catch (e) {
      // Handle all other errors
      Debug.logInfo('Error fetching document at $resolvedPath: $e');
      rethrow;
    }
  }


  /// Retrieves multiple documents from Firestore for the given set of [ids].
  /// Validates that all IDs share the same collection and batches the queries according to Firestore’s whereIn limit.
  /// Returns a map where each key is a document ID and the value is its data.
  Future<Map<String, Map<String, dynamic>>> getDocs(Set<String> ids) async {
    if (ids.isEmpty) {
      return {};
    }

    // Validate that all IDs share the same collection path
    CoreIdValidation.validateIdsShareCollection(ids);
    final collection = await pathService.getCollectionPathFromId(ids.first);
    final idList = ids.toList();

    Debug.logInfo('Getting docs: [${ids.join('\n')}]');

    // Create batches of at most 10 IDs each
    final batches = <List<String>>[];
    for (int i = 0; i < idList.length; i += 10) {
      final end = (i + 10 <= idList.length) ? i + 10 : idList.length;
      batches.add(idList.sublist(i, end));
    }

    final results = <String, Map<String, dynamic>>{};

    try {
      // Execute each batch query concurrently
      final batchResults = await Future.wait(batches.map((batch) async {
        final querySnapshot = await _db
            .collection(collection)
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        final batchMap = <String, Map<String, dynamic>>{};
        for (final doc in querySnapshot.docs) {
          final data = doc.data();
          // REMOVE THE LINE BELOW
          // convertToDateTime(data);
          batchMap[doc.id] = data;
        }
        return batchMap;
      }));

      // Merge the maps from all batches
      for (final map in batchResults) {
        results.addAll(map);
      }
    } on FirebaseException catch (e) {
      Debug.logInfo('Error fetching documents: ${e.message}');
      rethrow;
    } catch (e) {
      Debug.logInfo('Error fetching documents: $e');
      rethrow;
    }

    // If none found or all were null => results is empty
    return results;
  }

  /// Retrieves all documents from the collection specified by [collectionName] and [domain].
  /// Returns a map of document IDs to their data.
  /// Throws an error if the retrieval fails.
  Future<Map<String, Map<String, dynamic>>> getDocsInCollection(String collectionName, String domain,) async {
    final collectionPath = await pathService.getCollectionPath(collectionName, domain);
    Debug.logInfo('Fetching all documents from collection: $collectionPath');
    try {
      final querySnapshot = await _db.collection(collectionPath).get();

      // If no docs, return empty map
      if (querySnapshot.docs.isEmpty) {
        return {};
      }

      final results = <String, Map<String, dynamic>>{};
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        results[doc.id] = data;
      }
      return results;
    } on FirebaseException catch (e) {
      throw StateError(
        'Error fetching documents from $collectionName: ${e.message}',
      );
    } catch (e) {
      Debug.logInfo('Error fetching documents from collection $collectionName: $e');
      rethrow;
    }
  }

  /// Retrieves the specific [field] from a document identified by [id].
  /// Throws an error if the document or the field is not found.
  Future<dynamic> _getDocumentField(String id, String field) async {
    final document = await getDoc(id);
    if (!document.containsKey(field)) {
      throw ArgumentError('Field \'$field\' does not exist in document with id \'$id\'.');
    }
    return document[field];
  }

  Future<Map<String, dynamic>> getFieldFromCollection(String collectionName, String domain, String field) async {
    final List<Map<String, dynamic>> documents = (await getDocsInCollection(collectionName, domain)).values.toList();

    final Map<String, dynamic> fieldValues = {};

    for (final document in documents) {
      if (document.containsKey(field)) {
        fieldValues[document['id']] = document[field];
      } else {
        throw ArgumentError('Field \'$field\' not found in one of the documents in collection \'$collectionName\'');
      }
    }

    if (fieldValues.isEmpty) {
      Debug.logInfo('Warning: Field \'$field\' was not found in any documents in collection \'$collectionName\' (domain: \'$domain\'). Returning empty list.');
    }

    return fieldValues;
  }

  /// Retrieves the value of [field] from the document with the given [id] and casts it to type [T].
  /// Throws an error if the document is missing, the field doesn't exist, or if the value isn't of type [T].
  Future<T> getFieldValue<T>(String id, String field) async {
    final value = await _getDocumentField(id, field);
    if (value is! T) {
      throw ArgumentError(
          'Field \'$field\' is expected to be of type ${T.toString()} but found ${value.runtimeType}.');
    }
    Debug.logInfo('Getting field: $field in $id');
    return value;
  }

  /// Retrieves the value of [field] from the document with the given [id] as a List,
  /// and converts it to a [Set] of type [T].
  /// Throws an error if the document or field is missing, if the field is not a List, or if the conversion fails.
  Future<Set<T>> getSetFieldValue<T>(String id, String field) async {
    final value = await _getDocumentField(id, field);
    if (value is! List) {
      throw ArgumentError(
          'Field \'$field\' is expected to be a List but found ${value.runtimeType}.'
      );
    }
    Debug.logInfo('Getting set: $field in $id');
    try {
      return (value).map((e) => e as T).toSet();
    } catch (_) {
      throw ArgumentError(
          'Field \'$field\' contains values that can\'t be cast to ${T.toString()}.'
      );
    }
  }

  /// Retrieves a document with the given [id] and converts its data into an object of type [T]
  /// using the provided [fromJson] function.
  /// Throws an error if the document is not found.
  Future<T> getObject<T>(String id) async {
    final data = await getDoc(id);
    return CoreObject.fromJson(data) as T;
  }

  /// Retrieves multiple documents specified by the set of [ids] and converts each into an object of type [T]
  /// using the provided [fromJson] function.
  /// Throws an error if any document is not found.
  /// Returns a set of the converted objects.
  Future<Set<T>> getObjects<T>(Set<String> ids) async {
    final documentMap = await getDocs(ids);
    return ids.map((id) {
      final data = documentMap[id];
      if (data == null) {
        throw StateError('No document found for ID: $id');
      }
      return CoreObject.fromJson(data) as T;
    }).toSet();
  }

  /// Retrieves all documents from the collection defined by [collectionName] and [domain],
  /// converting each document’s data into an object of type [T] via the [fromJson] function.
  /// Throws an error if any document is missing.
  /// Returns a set of the converted objects.
  Future<Map<String, T>> getObjectsInCollection<T>(String collectionName, String domain) async {
    final documentMap = await getDocsInCollection(collectionName, domain);
    final Map<String, T> output = {};
    for (final entry in documentMap.entries) {
      output[entry.key] = CoreObject.fromJson(entry.value) as T;
    }
    return output;
  }

  /// Queries the collection (determined by [collectionName] and [domain]) with the provided [conditions].
  /// Conditions may include equality filters as well as inequality operators ('isLessThanOrEqualTo', 'isGreaterThanOrEqualTo').
  /// Limits the query to one result and returns the ID of the first matching document.
  /// Throws an error if no matching document is found.
  Future<String> _queryCollection(String collectionName, String domain, Map<String, dynamic> conditions,) async {
    Query query = _db.collection(await pathService.getCollectionPath(collectionName, domain));
    conditions.forEach((field, value) {
      if (value is Map<String, dynamic>) {
        // Handle inequality operators (example for two operators)
        value.forEach((operator, operand) {
          switch (operator) {
            case 'isLessThanOrEqualTo':
              query = query.where(field, isLessThanOrEqualTo: operand);
              break;
            case 'isGreaterThanOrEqualTo':
              query = query.where(field, isGreaterThanOrEqualTo: operand);
              break;
            default:
              throw ArgumentError('Unsupported operator: $operator');
          }
        });
      } else {
        query = query.where(field, isEqualTo: value);
      }
    });
    final querySnapshot = await query.limit(1).get();
    if (querySnapshot.docs.isEmpty) {
      throw StateError('No document found in \'$collectionName\' matching $conditions');
    }
    return querySnapshot.docs.first.id;
  }

  /// Queries a collection (specified by [collectionName] and [domain]) for the first document where [field] equals [value].
  /// Returns the matching document's ID if found, otherwise null.
  /// Internally leverages the [_queryCollection] method.
  Future<String?> queryField<T>(String collectionName, String domain, String field, T value,) async {
    return await _queryCollection(collectionName, domain, { field: value });
  }


  /// Queries for the first active document in the collection (specified by [collectionName] and [domain]).
  /// An active document is defined as one with a 'start' less than or equal to the current time
  /// and an 'end' greater than or equal to the current time.
  /// Returns the ID of the active document, or throws an error if none is found.
  // TODO: Handle no active sessions/seasons!!!
  Future<String> getActiveObjectId(String collectionName, String domain) async {
    final now = DateTime.now().toUtc();
    final conditions = {
      'start': {'isLessThanOrEqualTo': now},
      'end': {'isGreaterThanOrEqualTo': now},
    };

    try {
      return await _queryCollection(collectionName, domain, conditions);
    } catch (e) {
      Debug.logInfo('Error fetching active objects: $e');
      rethrow;
    }
  }

  /// Finds which of the provided keys do not correspond to existing Firestore documents.
  ///
  /// Handles keys potentially resolving to different collections via the provided [pathService].
  /// Optimizes reads by grouping keys by collection and using batched `whereIn` queries,
  /// executed concurrently across different collections using Future.wait.
  ///
  /// Args:
  ///   keysToCheck: The set of original keys (e.g., 'user1', 'orderABC') to check for existence.
  ///   db: The FirebaseFirestore instance.
  ///   pathService: The service used to resolve keys to full paths and extract collection paths.
  ///
  /// Returns:
  ///   A Future resolving to a Set containing the *original keys* from [keysToCheck]
  ///   that were determined to be missing in Firestore, considering only keys for which
  ///   path resolution was successful.
  Future<Set<String>> findMissingKeys(Set<String> keysToCheck) async {
    // --- 1. Handle Empty Input ---
    if (keysToCheck.isEmpty) {
      Debug.logInfo('[findMissingKeys] Input key set is empty. Returning empty set.');
      return {};
    }

    Debug.logInfo('[findMissingKeys] Starting check for ${keysToCheck.length} keys.');

    // --- 2. Resolve Paths and Group by Collection ---
    // Map: collectionPath -> Set<originalKey>
    final Map<String, Set<String>> keysByCollection = {};
    // Map: originalKey -> fullPath (needed to map results back)
    final Map<String, String> originalKeyToFullPath = {};

    for (final key in keysToCheck) {
      String? fullPath;
      String? collectionPath;
      try {
        fullPath = await pathService.getDocPathFromId(key);
        if (fullPath.trim().isEmpty) {
          Debug.logInfo('[findMissingKeys] Warning: Resolved path for key \'$key\' is empty. Skipping.');
          continue; // Skip keys that don't resolve to a non-empty path
        }

        collectionPath = await pathService.getCollectionPathFromId(key);
        if (collectionPath.trim().isEmpty) {
          Debug.logInfo('[findMissingKeys] Warning: Could not determine collection path for \'$fullPath\' (from key \'$key\'). Skipping grouping for this key.');
          // Key is still in originalKeyToFullPath, will be treated as missing if not found later
          continue; // Skip grouping if collection path can't be determined
        }

        // Add key to the set for its collection path
        (keysByCollection[collectionPath] ??= {}).add(key);

      } catch (e) {
        // Catch errors during path resolution or collection path extraction
        Debug.logInfo('[findMissingKeys] Error processing key \'$key\' (Path: \$fullPath\'): $e. Skipping key.');
        // Ensure key is not left in map if resolution failed partway
        originalKeyToFullPath.remove(key);
      }
    }

    // Check if any keys could be successfully resolved and grouped
    if (keysByCollection.isEmpty) {
      Debug.logInfo('[findMissingKeys] No keys could be grouped by collection (check path resolution logs).');
      // Decide what to return: maybe all originally checked keys, or only those resolvable?
      // Let's return keys that *could* be resolved but maybe not grouped or found
      Debug.logInfo('[findMissingKeys] Assuming all keys (${originalKeyToFullPath.length}) with resolved paths are missing.');
      return originalKeyToFullPath.keys.toSet();
    }

    Debug.logInfo('[findMissingKeys] Grouped ${originalKeyToFullPath.length} resolvable keys into ${keysByCollection.length} collections.');

    // --- 3. Prepare Batched `whereIn` Queries ---
    final List<Future<QuerySnapshot<Map<String, dynamic>>>> queryFutures = [];
    // Firestore limit for items in 'whereIn' or 'arrayContainsAny'
    const int firestoreWhereInLimit = 30;

    keysByCollection.forEach((collectionPath, keysInCollection) {
      if (keysInCollection.isNotEmpty) {
        // For the 'whereIn' query, we need the actual Firestore document IDs,
        // which are typically the last part of the full path.
        final List<String> docIdsInCollectionBatch = keysInCollection
        // Get the full path stored earlier for this original key
            .map((key) => originalKeyToFullPath[key])
        // Filter out nulls just in case (shouldn't happen with above logic)
            .nonNulls
        // Extract the last segment as the document ID
            .map((path) => path.contains('/') ? path.split('/').last : path)
        // Filter out potentially empty IDs if path splitting failed unexpectedly
            .where((id) => id.isNotEmpty)
            .toList();

        if (docIdsInCollectionBatch.isEmpty) {
          Debug.logInfo('[findMissingKeys] Warning: No valid document IDs extracted for collection \'$collectionPath\'. Skipping query.');
          return; // Continue to next collection path
        }

        // Use '.slices()' from 'package:collection/collection.dart' for easy batching
        final List<List<String>> batches = docIdsInCollectionBatch.slices(firestoreWhereInLimit).toList();

        Debug.logInfo('[findMissingKeys] Collection \'$collectionPath\': ${keysInCollection.length} keys -> ${batches.length} Firestore query batch(es).');

        // Create a query Future for each batch
        for (final batch in batches) {
          if (batch.isNotEmpty) {
            // Prepare the query targeting the specific collection and batch of IDs
            final query = db
                .collection(collectionPath)
                .where(FieldPath.documentId, whereIn: batch)
                .get();
            queryFutures.add(query);
          }
        }
      } else {
        Debug.logInfo('[findMissingKeys] Info: Collection \'$collectionPath\' had no keys associated after resolution/grouping. Skipping query.');
      }
    });

    // Check if any queries were actually prepared
    if (queryFutures.isEmpty) {
      Debug.logInfo('[findMissingKeys] No Firestore queries were prepared (check grouping/ID extraction logs).');
      Debug.logInfo('[findMissingKeys] Assuming all keys (${originalKeyToFullPath.length}) with resolved paths are missing.');
      return originalKeyToFullPath.keys.toSet();
    }

    // --- 4. Execute Queries Concurrently ---
    Debug.logInfo('[findMissingKeys] Executing ${queryFutures.length} Firestore queries concurrently via Future.wait...');
    List<QuerySnapshot<Map<String, dynamic>>> queryResults;
    try {
      // Wait for all the prepared query Futures to complete
      queryResults = await Future.wait(queryFutures);
      Debug.logInfo('[findMissingKeys] All ${queryFutures.length} queries completed.');
    } catch (e, stackTrace) {
      Debug.logInfo('[findMissingKeys] CRITICAL: Error during Future.wait executing Firestore queries: $e');
      print(stackTrace);
      // Strategy on error: rethrow, return partial, assume all missing?
      // Rethrowing is often best, letting the caller handle the failure state.
      rethrow;
    }

    // --- 5. Collect Found Document Full Paths ---
    // Using full paths obtained from doc.reference.path is reliable
    final Set<String> foundFullPaths = {};
    int foundDocsCount = 0;
    for (final querySnapshot in queryResults) {
      for (final doc in querySnapshot.docs) {
        // Double-check existence (though whereIn should only return existing)
        if (doc.exists) {
          foundFullPaths.add(doc.reference.path);
          foundDocsCount++;
        }
      }
    }
    Debug.logInfo('[findMissingKeys] Found $foundDocsCount existing documents across all queries (unique paths: ${foundFullPaths.length}).');


    // --- 6. Map Found Paths Back to Original Keys ---
    // Determine which original keys correspond to the paths found
    final Set<String> foundOriginalKeys = {};
    originalKeyToFullPath.forEach((originalKey, fullPath) {
      if (foundFullPaths.contains(fullPath)) {
        foundOriginalKeys.add(originalKey);
      }
    });

    // --- 7. Calculate Missing Keys ---
    // Compare the set of keys for which we successfully got a path
    // against the set of those keys that were actually found.
    final Set<String> checkableKeys = originalKeyToFullPath.keys.toSet();
    final Set<String> missingKeys = checkableKeys.difference(foundOriginalKeys);

    Debug.logInfo('[findMissingKeys] Determined ${missingKeys.length} missing keys out of ${checkableKeys.length} successfully resolved keys.');
    // For debugging: print(missingKeys);

    // --- 8. Return Missing Keys ---
    return missingKeys;
  }

}
