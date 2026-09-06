// ignore_for_file: unnecessary_null_comparison

import 'package:collection/collection.dart';
import 'package:get/get.dart';

import '../ember_core.dart';
import '../debug/repair_exceptions.dart';
import '../repositories/contextless_repository.dart';

class DatabaseRepairService extends GetxService {
  static const double matchThreshold = 0.75;
  static const double fieldPresenceWeight = 0.20;
  static const double valueEqualityWeight = 0.25;
  static const Set<String> specialFields = {'name', 'firstName'};
  static const double specialFieldPresenceWeight = 0.15;
  static const double specialValueEqualityWeight = 0.40;
  static const Set<String> alwaysIgnore = {'id', 'updatedAt'};

  RosterService rosterService = Get.find<RosterService>();
  ScheduleService scheduleService = Get.find<ScheduleService>();
  CabinService cabinService = Get.find<CabinService>();

  PullRepository pullRepo = Get.find<PullRepository>();
  ContextlessRepository contextlessRepo = Get.find<ContextlessRepository>();

  Future<void> cleanOrphanedDependents(Commit commit, Session session) async {
    final Map<String, Set<String>> principalDependentLinkTracker = session.principalDependentLinkTracker;
    Set<String> deletedPrincipalIds = await pullRepo.findMissingKeys(principalDependentLinkTracker.keys.toSet());
    for (String principalId in deletedPrincipalIds) {
      commit.addObjectsToDelete(await pullRepo.getObjects(principalDependentLinkTracker[principalId]!));
    }
  }

  /// Checks a document for various corruption conditions.
  ///
  /// Returns `true` if the document is considered not corrupt.
  /// Throws a `RepairException` if a corruption is found.
  ///
  /// Args:
  ///   path: The direct Firestore path to the document. Use this OR `id`.
  ///   id: The CoreObject ID. Use this OR `path`. If provided, `pullRepo.getDoc` will be used.
  ///   templateJson: A Map representing the expected structure and fields of the document.
  ///   expectedType: The expected Dart runtimeType of the deserialized CoreObject (e.g., User.runtimeType).
  ///   objectTypeStringForId: The string representation of the object type as expected in the Core ID's type part (e.g., "usr", "org").
  Future<bool> checkDocumentCorruption({
    String? path,
    String? id,
    required Map<String, dynamic> templateJson,
    required Type expectedType,
    required String objectTypeStringForId,
  }) async {
    Map<String, dynamic>? docData;
    String documentKeyFromSource;
    String? resolvedPath = path; // For error reporting

    if (path != null && id != null) {
      throw RepairArgumentError(reason: "Provide either path or id, not both.");
    }
    if (path == null && id == null) {
      throw RepairArgumentError(reason: "Either path or id must be provided.");
    }

    try {
      if (path != null) {
        documentKeyFromSource = path.split('/').last;
        docData = await contextlessRepo.pull(path); //
        if (docData == null) {
          // contextlessRepo.pull returns null if doc doesn't exist or on error.
          throw RepairDocNotFoundError(path: path, keyInfo: documentKeyFromSource);
        }
      } else {
        // id != null
        documentKeyFromSource = id!;
        // Attempt to get the actual path for better error reporting if possible
        // This depends on PathService being accessible or if pullRepo can provide it.
        // For now, we'll just use the ID for keyInfo.
        docData = await pullRepo.getDoc(id); //
        if (docData.isEmpty) {
          // pullRepo.getDoc returns {} if not found
          throw RepairDocNotFoundError(id: id, keyInfo: documentKeyFromSource);
        }
      }

      // 1. Check for 'id' field in document data
      if (!docData.containsKey('id') || docData['id'] == null) {
        throw RepairIdIssue(reason: "internal_id_missing_or_null", documentKey: documentKeyFromSource);
      }
      if (docData['id'] is! String) {
        throw RepairIdIssue(reason: "internal_id_not_string", documentKey: documentKeyFromSource);
      }
      final String internalId = docData['id'] as String;

      // 2. Validate internal ID format using CoreIdValidation
      try {
        CoreIdValidation.simpleValidate(internalId); //
      } catch (e) {
        throw RepairIdIssue(reason: "internal_id_invalid_format", internalId: internalId, documentKey: documentKeyFromSource);
      }

      // 3. Match internal ID with document key from source (path/id)
      if (internalId != documentKeyFromSource) {
        throw RepairIdIssue(reason: "internal_id_mismatch", internalId: internalId, documentKey: documentKeyFromSource);
      }

      // 4. Field count and name mismatch with templateJson
      final Set<String> docKeys = docData.keys.toSet();
      final Set<String> templateKeys = templateJson.keys.toSet();

      if (docKeys.length != templateKeys.length) {
        throw RepairFieldIssue(
          reason: "field_count_mismatch",
          documentKey: documentKeyFromSource,
          docKeys: docKeys,
          templateKeys: templateKeys,
        );
      }
      if (!SetEquality().equals(docKeys, templateKeys)) {
        //
        final Set<String> missingInDoc = templateKeys.difference(docKeys);
        final Set<String> extraInDoc = docKeys.difference(templateKeys);
        throw RepairFieldIssue(
          reason: "field_name_mismatch",
          documentKey: documentKeyFromSource,
          missingInDoc: missingInDoc,
          extraInDoc: extraInDoc,
        );
      }

      // 5. Deserialization, Type Check, Reserialization
      CoreObject deserializedObject;
      try {
        deserializedObject = CoreObject.fromJson(docData); //
      } catch (e) {
        throw RepairSerializationIssue(stage: "deserialization", errorMessage: e.toString(), documentKey: documentKeyFromSource);
      }

      if (deserializedObject.runtimeType != expectedType) {
        throw RepairTypeIssue(
          expectedType: expectedType.toString(),
          actualType: deserializedObject.runtimeType.toString(),
          documentKey: documentKeyFromSource,
        );
      }

      final String objectTypeFromId = IdFunctions.getIdPart(internalId, 1); //
      if (objectTypeFromId != objectTypeStringForId) {
        throw RepairIdIssue(reason: "id_type_part_mismatch", internalId: internalId, documentKey: documentKeyFromSource);
      }

      try {
        final Map<String, dynamic> reserializedJson = deserializedObject.toJson();
        if (reserializedJson.isEmpty && docData.isNotEmpty) {
          throw RepairSerializationIssue(
            stage: "serialization",
            errorMessage: "Reserialization resulted in an empty map for a non-empty document.",
            documentKey: documentKeyFromSource,
          );
        }
      } catch (e) {
        throw RepairSerializationIssue(stage: "serialization", errorMessage: e.toString(), documentKey: documentKeyFromSource);
      }

      for (final key in templateKeys) {
        if (templateJson[key] != null && docData[key] == null) {
          throw RepairFieldIssue(reason: "unexpected_null_value", documentKey: documentKeyFromSource);
        }
      }
    } catch (e, st) {
      if (e is RepairException) {
        Error.throwWithStackTrace(Debug.parseException(e), st);
      }
      // For other unexpected errors during the check process itself
      String keyInfo = resolvedPath ?? id ?? "unknown_source_key";
      throw RepairUnexpectedError(errorMessage: e.toString(), keyInfo: keyInfo);
    }

    return true; // All checks passed, document is not corrupt
  }

  Future<void> mergeObjectsWithDatabase({
    required Commit commit,
    required Set<CoreObject> objects,
    required bool prioritizeAFields,
    required bool prioritizeAValues,
    required bool overwriteWithEmptyAValues,
    Set<String>? aFieldsToIgnore,
  }) async {
    for (CoreObject object in objects) {
      await mergeObjectWithDatabase(
        commit: commit,
        objectToMerge: object,
        prioritizeAFields: prioritizeAFields,
        prioritizeAValues: prioritizeAValues,
        overwriteWithEmptyAValues: overwriteWithEmptyAValues,
        aFieldsToIgnore: aFieldsToIgnore,
      );
    }
  }

  Future<void> mergeObjectWithDatabase({
    required Commit commit,
    required CoreObject objectToMerge,
    required bool prioritizeAFields,
    required bool prioritizeAValues,
    required bool overwriteWithEmptyAValues,
    Set<String>? aFieldsToIgnore,
  }) async {
    String idA = objectToMerge.id;
    Map<String, dynamic> jsonA = objectToMerge.toJson();
    Map<String, dynamic>? jsonB;

    if (await pullRepo.docExists(idA)) {
      jsonB = await pullRepo.getDoc(idA);
    } else {
      String jsonACollection = IdFunctions.getIdPart(idA, 1);
      String jsonADomain = IdFunctions.getIdPart(idA, 2);
      Map<String, dynamic>? likelyMatch = await getLikelyMatchFromCollection(
        jsonA: jsonA,
        collectionName: jsonACollection,
        domain: jsonADomain,
      );
      if (likelyMatch != null) {
        jsonB = likelyMatch;
      }
    }

    if (jsonB == null) {
      commit.addObjectToPush(CoreObject.fromJson(jsonA));
      return;
    }

    // Start with B's data as our base
    final mergedJson = {...jsonB};

    // Iterate over each field in A
    jsonA.forEach((key, valueA) {
      // If this field is ignored, skip it
      if ((aFieldsToIgnore != null && aFieldsToIgnore.contains(key)) || key == 'id') {
        return;
      }

      // If B doesn't have this field
      if (!jsonB!.containsKey(key)) {
        // Only add the field if prioritizeAFields is true
        if (prioritizeAFields) {
          mergedJson[key] = valueA;
        }
      } else {
        // B does have this field
        final valueB = jsonB[key];

        // If B’s value is null but A’s is not, use A’s value
        if (jsonB[key] == null && valueA != null) {
          mergedJson[key] = valueA;
        }
        // If both values are non-null and differ
        else if (valueB != null && valueA != null && valueB != valueA) {
          if (prioritizeAValues) {
            // If A is empty but overwriteWithEmptyAValues is false, skip overwriting
            if (!_isEmptyValue(valueA) || overwriteWithEmptyAValues) {
              mergedJson[key] = valueA;
            }
            // else keep B's value
          }
          // else if not prioritizeAValues, do nothing here (keep B)
        }
      }
    });

    // If we are NOT prioritizing A’s fields, keep any extra fields that only exist in B
    if (!prioritizeAFields) {
      jsonB.forEach((key, valueB) {
        // If A doesn't have this key
        if (!jsonA.containsKey(key)) {
          // Also skip if it's in the ignore list
          if (aFieldsToIgnore != null && aFieldsToIgnore.contains(key)) {
            return;
          }
          mergedJson[key] = valueB;
        }
      });
    }

    // If there's a known doc ID from B, we keep that. Otherwise, fallback to A's ID.
    mergedJson['id'] = (jsonB.containsKey('id')) ? jsonB['id'] : idA;

    dynamic mergedObject = CoreObject.fromJson(mergedJson);
    commit.addObjectToPush(mergedObject as CoreObject);
  }

  bool _isEmptyValue(dynamic value) {
    if (value == null) return true;
    if (value is String && value.isEmpty) return true;
    if (value is Iterable && value.isEmpty) return true;
    if (value is Map && value.isEmpty) return true;
    return false;
  }

  Future<Map<String, dynamic>?> getLikelyMatchFromCollection({
    required Map<String, dynamic> jsonA,
    required String collectionName,
    required String domain,
  }) async {
    Set<Map<String, dynamic>> jsons = (await pullRepo.getDocsInCollection(collectionName, domain)).values.toSet();
    for (var jsonB in jsons) {
      if (computeJsonSimilarity(jsonA, jsonB) >= matchThreshold) {
        Debug.logInfo('MATCHING DOC FOUND!');
        return jsonB;
      }
    }
    return null;
  }

  /// Compares two JSON maps and returns a similarity score in [0..1].
  ///
  /// By default, this method:
  /// - Weighs "field presence" more heavily than "exact matching values."
  /// - Performs a recursive equality check on nested values
  /// - Treats numeric fields as equal only if they have the same value.
  /// - Id is excluded
  ///
  /// The sum of all weights MUST equal 1.0 or an error will be thrown
  /// specialFields is not required to be set, however if it is,
  /// specialFieldPresenceWeight and specialValueEqualityWeight
  /// must not be null

  double computeJsonSimilarity(Map<String, dynamic> jsonA, Map<String, dynamic> jsonB) {
    if (specialFields == null && fieldPresenceWeight + valueEqualityWeight != 1.0) {
      throw ArgumentError('The sum of fieldPresenceWeight and valueEqualityWeight must be 1.0');
    } else if ((specialValueEqualityWeight == null)) {
      throw ArgumentError(
        'specialFieldPresenceWeight and specialValueEqualityWeight cannot be null if specialFields is not null',
      );
    } else if (fieldPresenceWeight + valueEqualityWeight + specialFieldPresenceWeight + specialValueEqualityWeight != 1.0) {
      throw ArgumentError('The sum of all weights must be 1.0');
    }

    bool specialFieldsPresent =
        specialFields.any((field) => jsonA.containsKey(field) || jsonB.containsKey(field));

    double effectiveFieldPresenceWeight;
    double effectiveValueEqualityWeight;
    double effectiveSpecialFieldPresenceWeight = 0;
    double effectiveSpecialValueEqualityWeight = 0;

    if (specialFieldsPresent) {
      effectiveFieldPresenceWeight = fieldPresenceWeight;
      effectiveValueEqualityWeight = valueEqualityWeight;
      effectiveSpecialFieldPresenceWeight = specialFieldPresenceWeight;
      effectiveSpecialValueEqualityWeight = specialValueEqualityWeight;
    } else {
      double originalRegularWeightSum = fieldPresenceWeight + valueEqualityWeight;
      if (originalRegularWeightSum <= 0) {
        effectiveFieldPresenceWeight = 0.5; // Default split if original weights are zero
        effectiveValueEqualityWeight = 0.5;
      } else {
        effectiveFieldPresenceWeight = fieldPresenceWeight / originalRegularWeightSum;
        effectiveValueEqualityWeight = valueEqualityWeight / originalRegularWeightSum;
      }
    }

    final Set<String> regularExclude = {...specialFields, ...alwaysIgnore};
    double fieldPresenceIndex = compareFieldPresence(jsonA: jsonA, jsonB: jsonB, exclude: regularExclude);
    double valueEqualityIndex = compareValueEquality(jsonA: jsonA, jsonB: jsonB, exclude: regularExclude);

    double sum = fieldPresenceIndex * effectiveFieldPresenceWeight + valueEqualityIndex * effectiveValueEqualityWeight;


    if (specialFieldsPresent) {
      double specialFieldPresenceIndex = compareFieldPresence(
        jsonA: jsonA,
        jsonB: jsonB,
        limitedTo: specialFields,
        exclude: alwaysIgnore,
      );
      double specialValueEqualityIndex = compareValueEquality(
        jsonA: jsonA,
        jsonB: jsonB,
        limitedTo: specialFields,
        exclude: alwaysIgnore,
      );
      sum +=
          specialFieldPresenceIndex * effectiveSpecialFieldPresenceWeight +
          specialValueEqualityIndex * effectiveSpecialValueEqualityWeight;
    }

    return sum;
  }

  /// Computes how similar two JSONs are in terms of field presence.
  ///
  /// - Returns 1.0 if `jsonA` and `jsonB` have exactly the same fields (after
  ///   filtering), 0.0 if they share none.
  /// - If `limitedTo` is non-null, only consider fields within that set.
  /// - If `exclude` is non-null, exclude fields in that set.
  /// - If both `limitedTo` and `exclude` are null, consider all fields.
  ///
  /// This uses the Jaccard index (|A ∩ B| / |A ∪ B|) for the relevant fields.
  double compareFieldPresence({
    required Map<String, dynamic> jsonA,
    required Map<String, dynamic> jsonB,
    Set<String>? limitedTo,
    Set<String>? exclude,
  }) {
    Set<String> fieldsA = jsonA.keys.toSet();
    Set<String> fieldsB = jsonB.keys.toSet();

    // Apply `limitedTo` if present.
    if (limitedTo != null) {
      fieldsA = fieldsA.intersection(limitedTo);
      fieldsB = fieldsB.intersection(limitedTo);
    }

    // Apply `exclude` if present.
    if (exclude != null) {
      fieldsA = fieldsA.difference(exclude);
      fieldsB = fieldsB.difference(exclude);
    }

    // Compute intersection and union for the filtered sets.
    final intersection = fieldsA.intersection(fieldsB);
    final union = fieldsA.union(fieldsB);

    // If both sets are empty after filtering, we'll treat them as "same," i.e. score = 1.0.
    if (union.isEmpty) {
      return 1.0;
    }

    // Use Jaccard index: intersectionSize / unionSize.
    return intersection.length / union.length;
  }

  /// Compares values for all matching fields in [jsonA] and [jsonB], returning
  /// a score in [0..1].
  ///
  /// - Only considers fields that exist in both JSONs (the intersection).
  /// - If [limitedTo] is non-null, only consider fields in that set.
  /// - If [exclude] is non-null, skip fields in that set.
  /// - If there are no fields left after filtering, we return 1.0 by convention
  ///   (i.e., "no mismatches" among nonexistent fields).
  /// - Comparison is done with a simple `==` (top-layer).
  double compareValueEquality({
    required Map<String, dynamic> jsonA,
    required Map<String, dynamic> jsonB,
    Set<String>? limitedTo,
    Set<String>? exclude,
  }) {
    // Gather field names from each JSON as sets.
    var fieldsA = jsonA.keys.toSet();
    var fieldsB = jsonB.keys.toSet();

    // Apply `limitedTo` if present.
    if (limitedTo != null) {
      fieldsA = fieldsA.intersection(limitedTo);
      fieldsB = fieldsB.intersection(limitedTo);
    }

    // Apply `exclude` if present.
    if (exclude != null) {
      fieldsA = fieldsA.difference(exclude);
      fieldsB = fieldsB.difference(exclude);
    }

    // Only compare fields that exist in both JSONs.
    final commonFields = fieldsA.intersection(fieldsB);

    if (commonFields.isEmpty) {
      // If *neither* JSON had any relevant fields after filtering,
      // then they are "equally empty" - score 1.0.
      if (fieldsA.isEmpty && fieldsB.isEmpty) {
        return 1.0;
      } else {
        // Otherwise, at least one JSON had relevant fields, but
        // none were shared. Value equality for the considered
        // set is 0.0 because no values could be compared.
        return 0.0;
      }
    }

    int matchCount = 0;
    for (var key in commonFields) {
      if (_valuesAreEqual(jsonA[key], jsonB[key])) {
        matchCount++;
      }
    }

    // Return fraction of how many matched out of total in the intersection.
    // commonFields length is guaranteed to be > 0 here.
    return matchCount / commonFields.length;
  }

  bool _valuesAreEqual(dynamic a, dynamic b) {
    if (a is DateTime && b is DateTime) {
      // Convert both to UTC before comparing their equality
      return a.toUtc() == b.toUtc();
    }

    // If both are Lists, do a listEquality check
    if (a is List && b is List) {
      if (a.length != b.length) return false;
      for (int i = 0; i < a.length; i++) {
        if (!_valuesAreEqual(a[i], b[i])) return false;
      }
      return true;
    }

    // If both are Maps, do a mapEquality check
    if (a is Map && b is Map) {
      if (a.length != b.length) return false;
      for (var k in a.keys) {
        if (!b.containsKey(k) || !_valuesAreEqual(a[k], b[k])) {
          return false;
        }
      }
      return true;
    }

    // Otherwise, fall back to `==`
    return a == b;
  }

  /// Queues reset operations for all camper and activity data in a single commit.
  ///
  /// This method resets all camper preferences and assignments and clears all
  /// activity rosters by adding update operations to the provided [commit] batch.
  /// It fetches the current list of campers and activities from their respective
  /// services to ensure all documents are targeted.
  ///
  /// Returns `true` if the reset operations were successfully added to the
  /// batch, and `false` if an error occurred.
  Future<bool> resetAllAssignmentsAndPreferences({required Commit commit}) async {
    final results = await Future.wait([
      rosterService.registeredCampers,
      scheduleService.amas,
      scheduleService.getScheduledPrincipalActivitiesToNames(false),
      cabinService.cabinDependents,
      scheduleService.activityDependents,
    ]);
    final Set<Camper> allCampers = results[0] as Set<Camper>;
    final Set<AMABlock> allAmaBlocks = results[1] as Set<AMABlock>;
    final Set<String> scheduledPrincipalActivityIds = (results[2] as Map<String, String>).keys.toSet();
    final Set<CabinDependent> cabins = results[3] as Set<CabinDependent>;
    final Set<ActivityDependent> activityDependants = results[4] as Set<ActivityDependent>;

    for (Camper camper in allCampers) {
      camper.preferenceWeightRefs.clear();
      camper.activityAssignmentRefs.clear();
      for (String principalActivityId in scheduledPrincipalActivityIds) {
        camper.preferenceWeightRefs[principalActivityId] = 1.0;
      }
      for (AMABlock block in allAmaBlocks) {
        camper.activityAssignmentRefs[block.id] = null;
      }
    }
    commit.addObjectsToPush(allCampers);
    commit.addObjectsToPush(cabins);
    for (ActivityDependent activity in activityDependants) {
      activity.camperRefs.clear();
    }
    commit.addObjectsToPush(activityDependants);
    return true;
  }
}
