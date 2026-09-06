import 'package:bessie/src/models/interfaces/rosterable.dart';

class CollectionValidation {

  static bool isValidRoster(List<dynamic> collection) {
    // All members must be rosterable
    for (final element in collection) {
      if (element is! Rosterable) {
        return false;
      }
    }
    final List<Rosterable> rosterableCollection = collection as List<Rosterable>;

    // No duplicates allowed
    List<Rosterable> noDupes = rosterableCollection.toSet().toList();

    if (!haveSameElements(noDupes, rosterableCollection)) {
      return false;
    }

    // All members must share the same type
    Type? type;
    for (final element in collection) {
      if (type == null) {
        type = element.runtimeType;
      } else if (element.runtimeType != type) {
        return false;
      }
    }
    return true;
  }

  static bool haveSameElements<T>(List<T> list1, List<T> list2) {
    // 1. Check lengths
    if (list1.length != list2.length) {
      return false;
    }

    // If both are empty, they are equivalent
    if (list1.isEmpty) { // list2 is also empty due to the length check
      return true;
    }

    // 2. Count element frequencies for list1
    final Map<T, int> freqMap1 = {};
    for (final T element in list1) {
      freqMap1[element] = (freqMap1[element] ?? 0) + 1;
    }

    // 3. Count element frequencies for list2
    final Map<T, int> freqMap2 = {};
    for (final T element in list2) {
      freqMap2[element] = (freqMap2[element] ?? 0) + 1;
    }

    // 4. Compare frequency maps
    // Check if the number of unique elements is the same
    if (freqMap1.keys.length != freqMap2.keys.length) {
      return false;
    }

    // Check if all elements and their counts match
    for (final T key in freqMap1.keys) {
      if (!freqMap2.containsKey(key) || freqMap1[key] != freqMap2[key]) {
        return false;
      }
    }

    // Using MapEquality from package:collection for a more concise comparison (optional)
    // return const MapEquality().equals(freqMap1, freqMap2);

    return true;
  }
}