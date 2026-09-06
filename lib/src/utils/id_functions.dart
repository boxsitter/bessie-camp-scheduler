import 'dart:math';

import '../ember_core.dart';

class IdFunctions {
  static final Random _secureRandom = Random.secure();

  static String clean(String input) {
    return input
        .toLowerCase() // PUT THIS BACK
        .replaceAll(' ', '_')
    // Revert regex to only allow lowercase/numbers/_
        .replaceAll(RegExp(r'[^a-z0-9_]'), '');
  }


  /// Generates a Core ID in the format:
  /// [tag]-[objectType]-[domain]-[6 char random string]
  /// Throws an error if idType or domain is invalid or tag is too short.
  static String generateCoreId(String domain, String objectType, String tag) {
    if (!CoreIdValidation.isValidDomain(domain)) {
      throw ArgumentError('$domain is not a valid domain');
    }
    final cleanType = clean(objectType);
    final cleanTag = clean(tag);
    String randomPart = List.generate(7, (_) => CoreIdValidation.validCharacters[_secureRandom.nextInt(CoreIdValidation.validCharacters.length)]).join();
    return '$cleanTag-$cleanType-$domain-$randomPart';
  }

  /// Returns the specified part of a Core ID.
  /// Index mapping:
  /// 0: tag, 1: objectType/collection name, 2: domain, 3: random part.
  static String getIdPart(String id, int index) {
    return id.split('-')[index];
  }

  /// 0: tag, 1: objectType/collection name, 2: domain, 3: random part.
  static List<String> getIdParts(String id) {
    return id.split('-');
  }

}