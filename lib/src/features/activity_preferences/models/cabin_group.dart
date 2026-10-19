import 'package:collection/collection.dart';

import '../../../models/cabin.dart';
import '../../../models/camper.dart';

/// Title of the group of campers without a (session) cabin.
const noCabinTitle = 'No cabin';

/// Identifies the group of campers without a cabin in [CabinGroup.key].
const noCabinKey = 'no-cabin';

/// The campers of one cabin (or of no cabin), with how far along their
/// preferences are.
class CabinGroup {
  const CabinGroup({required this.cabinId, required this.title, required this.campers});

  /// Null for campers who are not in any of the session's cabins.
  final String? cabinId;
  final String title;

  /// Sorted by last name, then first name.
  final List<Camper> campers;

  /// Unique among the groups of one session.
  String get key => cabinId ?? noCabinKey;

  int get total => campers.length;

  /// Campers whose preferences have been saved by a counselor.
  int get submitted => campers.where((c) => c.preferencesSubmitted).length;

  bool get isComplete => total > 0 && submitted == total;
  bool get isInProgress => submitted > 0 && !isComplete;
}

/// Groups [campers] by cabin, in the order of [cabins]. Cabins without
/// campers are left out; campers who are in none of [cabins] are gathered in
/// a last group.
List<CabinGroup> groupCampersByCabin(List<Cabin> cabins, Iterable<Camper> campers) {
  int byName(Camper a, Camper b) {
    final byLast = a.lastName.toLowerCase().compareTo(b.lastName.toLowerCase());
    return byLast != 0 ? byLast : a.firstName.toLowerCase().compareTo(b.firstName.toLowerCase());
  }

  final byCabin = groupBy(campers, (Camper c) => c.cabinId);
  final knownCabinIds = {for (final cabin in cabins) cabin.id};
  final strays = campers.where((c) => !knownCabinIds.contains(c.cabinId)).sorted(byName);

  return [
    for (final cabin in cabins)
      if (byCabin[cabin.id] case final members?)
        if (members.isNotEmpty) CabinGroup(cabinId: cabin.id, title: cabin.title, campers: members.sorted(byName)),
    if (strays.isNotEmpty) CabinGroup(cabinId: null, title: noCabinTitle, campers: strays),
  ];
}
