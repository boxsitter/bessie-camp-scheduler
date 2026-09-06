import '../ember_core.dart';

class CoreIdValidation {
  static const String validCharacters = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  static const Set<String> validDomains = {'rot', 'org', 'brn', 'sea', 'ses'};
  static final RegExp potentialIdPattern = RegExp(r'^[^-]+-[^-]+-(rot|org|brn|sea|ses)(?:-|$)');
  
  static bool isValidDomain(String domain) => validDomains.contains(domain);

  static void validateIdsShareCollection(Set<String> ids) {
    if (ids.isEmpty) return;

    final List<String> firstParts = IdFunctions.getIdParts(ids.first);
    final String expectedDomain = firstParts[2];
    final String expectedType = firstParts[1];

    for (final id in ids.skip(1)) {
      print(id);
      final parts = IdFunctions.getIdParts(id);
      if (parts[2] != expectedDomain) {
        throw ArgumentError("Not all objects are of the same domain");
      }
      if (parts[1] != expectedType) {
        throw ArgumentError("Not all objects are of the same type");
      }
    }
  }

  /// Checks if [value] appears to be a Core ID by ensuring it has exactly 4 parts and starts with a valid domain
  static bool isPotentialId(String value) {
    return potentialIdPattern.hasMatch(value) && value.split('-').length == 4;
  }

  /// Performs a simple full check on the Core ID format.
  /// Throws an error describing the failure if the format is invalid.
  static void simpleValidate(String id) {
    final List<String> idParts = IdFunctions.getIdParts(id);
    if (idParts.length != 4) {
      throw ArgumentError("ID '$id' does not have exactly 5 parts (found ${idParts.length}).");
    }
    if (!validDomains.contains(idParts[2])) {
      throw ArgumentError("ID '$id' has an invalid domain '${idParts[2]}'.");
    }
    if (idParts.last.length != 7) {
      throw ArgumentError("ID '$id' has a random part of length ${idParts.last.length}, expected 7.");
    }
  }

  static bool validateObjectType(String id, String expectedObjectType) {
    if (IdFunctions.getIdPart(id, 1) == expectedObjectType) {
      return true;
    }
    return false;
  }

// /// Validates a single scalar Core ID.
// /// [expectedDomain] enforces that the ID's domain matches.
// /// [expectedObjectType] optionally enforces the object type.
// /// Throws an error with a descriptive message on failure.
// static void validateScalarId(String id, {required String expectedDomain, String? expectedObjectType}) {
//   simpleValidate(id); // Throws error if invalid format.
//   final List<String> idParts = IdFunctions.getIdParts(id);
//   if (idParts[0] != expectedDomain) {
//     throw ArgumentError("ID '$id' has domain '${idParts[0]}', expected '$expectedDomain'.");
//   }
//   if (expectedObjectType != null && idParts[1] != expectedObjectType) {
//     throw ArgumentError("ID '$id' has object type '${idParts[1]}', expected '$expectedObjectType'.");
//   }
// }
//
// /// Validates a collection (List) of potential Core IDs.
// /// Ensures that if any item is a potential ID, then each item is valid and all items have the same objectType.
// /// Throws an error with a descriptive message on failure.
// static void validateIdCollection(Iterable collection, String expectedDomain) {
//   String? commonObjectType;
//   int index = 0;
//   for (var item in collection) {
//     if (item is String && isPotentialId(item)) {
//       try {
//         validateScalarId(item, expectedDomain: expectedDomain);
//       } catch (e) {
//         throw ArgumentError("In collection at index $index: $e");
//       }
//       final parts = IdFunctions.getIdParts(item);
//       String currentObjectType = parts[1];
//       if (commonObjectType == null) {
//         commonObjectType = currentObjectType;
//       } else {
//         if (commonObjectType != currentObjectType) {
//           throw ArgumentError("Inconsistent object type in collection at index $index: expected '$commonObjectType' but found '$currentObjectType'.");
//         }
//       }
//     }
//     index++;
//   }
// }
//
// /// Validates the structure of a flat CoreObject JSON.
// /// Requirements:
// ///     and must have the same domain as the top-level ID.
// ///   • In any collection of IDs, all items must have the same objectType.
// /// Throws an error with a descriptive message on failure.
// static void validateDocument(Map<String, dynamic> json) {
//   // Validate top-level "id" field.
//   if (!json.containsKey('id')) {
//     throw ArgumentError("Missing required 'id' field.");
//   }
//   dynamic idValue = json['id'];
//   if (idValue is! String) {
//     throw ArgumentError("The 'id' field must be a string.");
//   }
//   try {
//     simpleValidate(idValue);
//   } catch (e) {
//     throw ArgumentError("Top-level 'id' field error: $e");
//   }
//   String expectedDomain = IdFunctions.getIdPart(idValue, 0);
//   String expectedObjectType = IdFunctions.getIdPart(idValue, 1);
//
//   // Validate every other top-level field.
//   json.forEach((key, value) {
//     if (key == 'id') return; // Already validated.
//     if (value is String) {
//       if (isPotentialId(value)) {
//         try {
//           validateScalarId(value, expectedDomain: expectedDomain, expectedObjectType: expectedObjectType);
//         } catch (e) {
//           throw ArgumentError("Field '$key' error: $e");
//         }
//       }
//     } else if (value is List) {
//       try {
//         validateIdCollection(value, expectedDomain);
//       } catch (e) {
//         throw ArgumentError("Field '$key' collection error: $e");
//       }
//     }
//     // Other types are ignored.
//   });
// }
}