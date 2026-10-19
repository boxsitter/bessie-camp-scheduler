import '../../../models/camper.dart';

/// Decisions derived from which campers are selected. Pure so they can be
/// tested without a UI.
abstract final class RosterSelection {
  /// What "toggle arrived" should set the selection to: everyone arrived when
  /// anyone in the selection hasn't, otherwise everyone not arrived.
  static bool arrivedTarget(Iterable<Camper> selected) => selected.any((camper) => !camper.arrived);

  /// Why the selection can't have its cabins swapped, or null when it can.
  ///
  /// A swap sends every selected camper to the other cabin, so the selection
  /// must be campers that all have a cabin, spread over exactly two cabins.
  static String? cabinSwapProblem(Iterable<Camper> selected) {
    final campers = selected.toList();
    if (campers.isEmpty) return 'Select the campers whose cabins should be swapped.';
    if (campers.any((camper) => camper.cabinId == null)) {
      return 'Every selected camper needs a cabin to swap cabins.';
    }
    final cabins = {for (final camper in campers) camper.cabinId};
    if (cabins.length != 2) return 'Select campers from exactly two cabins to swap them.';
    return null;
  }

  /// Checkbox state of a set of rows: true when all are selected, null when
  /// some are, false when none are.
  static bool? stateOf(Iterable<String> ids, Set<String> selected) {
    var any = false;
    var all = true;
    for (final id in ids) {
      if (selected.contains(id)) {
        any = true;
      } else {
        all = false;
      }
    }
    if (!any) return false;
    return all ? true : null;
  }

  /// Every id in [all] that is not in [selected].
  static Set<String> invert(Iterable<String> all, Set<String> selected) => {
    for (final id in all)
      if (!selected.contains(id)) id,
  };
}
