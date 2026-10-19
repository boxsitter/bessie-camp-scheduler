import 'dart:math';

import 'package:get/get.dart';

import '../algorithms/assignment_engine.dart';
import '../core/errors.dart';
import '../core/logging.dart';
import '../data/roster_repository.dart';
import '../data/session_repository.dart';
import '../models/camper.dart';
import '../models/enums.dart';
import '../models/schedule.dart';

/// What an auto-assignment run did.
class AssignmentRunReport {
  const AssignmentRunReport({
    required this.assignedCount,
    required this.placementCount,
    required this.stalemates,
    required this.evaluationReports,
    required this.stepReports,
  });

  /// Slots the run filled (a double-block activity fills two).
  final int placementCount;

  /// Assignments actually stored (differs from [placementCount] only if
  /// someone changed the roster while the run was in progress).
  final int assignedCount;
  final List<Stalemate> stalemates;
  final List<ParticipantEvaluationReport> evaluationReports;
  final List<StepReport> stepReports;

  bool get hasStalemates => stalemates.isNotEmpty;
}

/// Runs the assignment engine against a session's real data and stores the result.
class AssignmentService extends GetxService {
  AssignmentService(this._sessions, this._roster);

  final SessionRepository _sessions;
  final RosterRepository _roster;

  /// Fills [blockIds] (default: every block) for [camperIds] (default: every
  /// camper in the session). Campers outside [camperIds] keep their
  /// assignments and still occupy seats.
  Future<AssignmentRunReport> run({
    required String sessionId,
    Set<String>? camperIds,
    Set<String>? blockIds,
    AssignmentStrategy strategy = AssignmentStrategy.diplomatic,
    StalemateStrategy stalemateStrategy = StalemateStrategy.leaveUnassigned,
    int? seed,
  }) async {
    final loaded = await Future.wait<Object>([_sessions.fetchSchedule(sessionId), _roster.fetchCampers(sessionId)]);
    final schedule = loaded[0] as Schedule;
    final everyone = loaded[1] as List<Camper>;

    final participants = camperIds == null ? everyone : everyone.where((c) => camperIds.contains(c.id)).toList();
    if (participants.isEmpty) throw AppException('There are no campers to assign.');
    if (schedule.isEmpty) throw AppException('This session has no schedule yet.');

    final targets = blockIds ?? schedule.blocks.map((b) => b.id).toSet();
    final context = buildContext(participants: participants, everyone: everyone, schedule: schedule, targetBlockIds: targets);

    final stopwatch = Stopwatch()..start();
    final AssignmentResult result;
    try {
      result = AssignmentEngine.run(
        context,
        strategy: strategy,
        stalemateStrategy: stalemateStrategy,
        random: Random(seed ?? DateTime.now().microsecondsSinceEpoch),
      );
    } on AssignmentStalemateException catch (e) {
      throw AppException('${e.stalemates.length} campers could not be given an activity. Nothing was saved.', cause: e);
    }
    log.i('Assignment engine finished in ${stopwatch.elapsedMilliseconds}ms: ${result.newPlacements.length} placements');

    final stored = await _roster.applyAssignments(
      sessionId: sessionId,
      assignments: [
        for (final p in result.newPlacements) NewAssignment(camperId: p.participantId, scheduledActivityId: p.scheduledActivityId),
      ],
      satisfaction: result.satisfaction,
    );

    return AssignmentRunReport(
      assignedCount: stored,
      placementCount: result.newPlacements.length,
      stalemates: result.stalemates,
      evaluationReports: result.evaluationReports,
      stepReports: result.stepReports,
    );
  }

  /// Translates the session's data into the engine's plain input. Pure, so it
  /// can be tested without a database.
  static AssignmentContext buildContext({
    required List<Camper> participants,
    required List<Camper> everyone,
    required Schedule schedule,
    required Set<String> targetBlockIds,
    DateTime? now,
  }) {
    final participantIds = participants.map((c) => c.id).toSet();

    // Seats held by campers who are not part of this run.
    final externalEnrollment = <String, int>{};
    for (final camper in everyone) {
      if (participantIds.contains(camper.id)) continue;
      for (final scheduledId in camper.assignments.values) {
        externalEnrollment[scheduledId] = (externalEnrollment[scheduledId] ?? 0) + 1;
      }
    }

    return AssignmentContext(
      participants: [for (final c in participants) AlgoParticipant(id: c.id, birthdate: c.birthdate)],
      preferences: {
        for (final c in participants)
          c.id: {
            for (final entry in c.preferences.entries)
              entry.key: entry.value == PreferenceKind.request ? PreferenceType.request : PreferenceType.veto,
          },
      },
      periods: [for (final b in schedule.blocks) AlgoPeriod(id: b.id, dayId: b.dayId, start: b.start)],
      targetPeriodIds: targetBlockIds,
      activities: [
        for (final a in schedule.activitiesById.values)
          AlgoActivity(
            id: a.id,
            capacity: a.capacity,
            maxAssignments: a.maxAssignments,
            doubleSchedule: a.doubleSchedule,
            assignable: !a.isHidden,
          ),
      ],
      scheduledActivities: [
        for (final s in schedule.scheduledActivities) AlgoScheduledActivity(id: s.id, activityId: s.activityId, periodId: s.blockId),
      ],
      existingAssignments: {for (final c in participants) c.id: c.assignments.values.toSet()},
      externalEnrollment: externalEnrollment,
      now: now ?? DateTime.now(),
    );
  }

  /// Campers who haven't had their preferences saved yet. Auto-assignment
  /// treats them as having no preferences.
  static List<Camper> withoutPreferences(Iterable<Camper> campers) => campers.where((c) => !c.preferencesSubmitted).toList();
}
