import '../../../models/activity.dart';
import '../../../models/cabin.dart';
import '../../../models/camper.dart';
import '../../../models/schedule.dart';

/// What a camper's row needs to know besides the camper: the session's cabins
/// and schedule. Immutable; rebuilt whenever either is loaded again.
class RosterContext {
  RosterContext({required this.schedule, this.cabinsById = const {}, DateTime? now}) : now = now ?? DateTime.now();

  /// Nothing loaded yet.
  factory RosterContext.empty() => RosterContext(
    schedule: Schedule(days: const [], blocks: const [], scheduledActivities: const [], activitiesById: const {}),
  );

  final Schedule schedule;
  final Map<String, Cabin> cabinsById;

  /// The moment ages are calculated against.
  final DateTime now;

  Cabin? cabinOf(Camper camper) {
    final id = camper.cabinId;
    return id == null ? null : cabinsById[id];
  }

  /// The scheduled activity [camper] has in [blockId], if any.
  ScheduledActivity? scheduledIn(Camper camper, String blockId) {
    final id = camper.assignments[blockId];
    return id == null ? null : schedule.scheduledActivityById(id);
  }

  Activity? activityIn(Camper camper, String blockId) {
    final scheduled = scheduledIn(camper, blockId);
    return scheduled == null ? null : schedule.activityOf(scheduled);
  }

  RosterContext copyWith({Schedule? schedule, Map<String, Cabin>? cabinsById}) =>
      RosterContext(schedule: schedule ?? this.schedule, cabinsById: cabinsById ?? this.cabinsById, now: now);
}
