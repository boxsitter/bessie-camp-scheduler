import '../../../models/camper.dart';
import '../../../models/enums.dart';
import '../../../models/schedule.dart';

/// How often a camper has the activity they have in a block.
enum RepetitionLevel { once, twice, many }

/// How a candidate activity suits a single camper.
enum PreferenceHint { requested, vetoed, neutral, repeated }

/// Seats in a scheduled activity if some campers were added to it.
class Seats {
  const Seats({required this.enrolled, required this.capacity, required this.incoming});

  /// Campers in the activity now.
  final int enrolled;
  final int capacity;

  /// Campers that would be added (the selected ones not already in it).
  final int incoming;

  bool get wouldOverflow => enrolled + incoming > capacity;
}

/// Statistics about activities, computed from the roster.
abstract final class ActivityHints {
  /// scheduled activity id -> how many of [campers] are in it.
  static Map<String, int> enrollment(Iterable<Camper> campers) {
    final counts = <String, int>{};
    for (final camper in campers) {
      for (final scheduledId in camper.assignments.values) {
        counts[scheduledId] = (counts[scheduledId] ?? 0) + 1;
      }
    }
    return counts;
  }

  /// catalog activity id -> how many times [camper] has been given it.
  static Map<String, int> timesAssigned(Camper camper, Schedule schedule) {
    final counts = <String, int>{};
    for (final scheduledId in camper.assignments.values) {
      final scheduled = schedule.scheduledActivityById(scheduledId);
      if (scheduled == null) continue;
      counts[scheduled.activityId] = (counts[scheduled.activityId] ?? 0) + 1;
    }
    return counts;
  }

  /// For the repetition view: how often the activity [camper] has in
  /// [blockId] occurs in their week. Null when they have nothing there.
  static RepetitionLevel? repetition(Camper camper, String blockId, Schedule schedule) {
    final scheduledId = camper.assignments[blockId];
    final scheduled = scheduledId == null ? null : schedule.scheduledActivityById(scheduledId);
    if (scheduled == null) return null;
    final count = timesAssigned(camper, schedule)[scheduled.activityId] ?? 0;
    if (count <= 0) return null;
    return switch (count) {
      1 => RepetitionLevel.once,
      2 => RepetitionLevel.twice,
      _ => RepetitionLevel.many,
    };
  }

  /// How [candidate] suits [camper]: what they asked for, unless they would
  /// get it for a third time (the block's current assignment, which would be
  /// replaced, is not counted).
  static PreferenceHint preferenceHint(Camper camper, ScheduledActivity candidate, Schedule schedule) {
    var elsewhere = 0;
    for (final entry in camper.assignments.entries) {
      if (entry.key == candidate.blockId) continue;
      final scheduled = schedule.scheduledActivityById(entry.value);
      if (scheduled != null && scheduled.activityId == candidate.activityId) elsewhere++;
    }
    if (elsewhere >= 2) return PreferenceHint.repeated;

    return switch (camper.preferences[candidate.activityId]) {
      PreferenceKind.request => PreferenceHint.requested,
      PreferenceKind.veto => PreferenceHint.vetoed,
      null => PreferenceHint.neutral,
    };
  }

  static Seats seats({
    required ScheduledActivity scheduled,
    required int capacity,
    required Iterable<Camper> selected,
    required Map<String, int> enrollment,
  }) {
    final incoming = selected.where((camper) => camper.assignments[scheduled.blockId] != scheduled.id).length;
    return Seats(enrolled: enrollment[scheduled.id] ?? 0, capacity: capacity, incoming: incoming);
  }
}
