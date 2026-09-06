import 'package:get/get.dart';

import '../ember_core.dart';
import '../algorithms/algorithm_pipeline.dart';
import '../algorithms/data_models/analogs/algo_activity.dart';
import '../algorithms/data_models/analogs/algo_participant.dart';
import '../algorithms/data_models/analogs/algo_period.dart';
import '../algorithms/data_models/analogs/algo_scheduled_activity.dart';
import '../algorithms/data_models/assignment_context.dart';
import '../algorithms/data_models/assignment_result.dart';
import '../algorithms/data_models/enums.dart';
import '../algorithms/diplomatic_algorithm/diplomatic_algorithm.dart';
import '../algorithms/evaluation/satisfaction_calculator.dart';

class AssignmentService extends GetxService {
  // --- DEPENDENCIES ---
  // Services needed to fetch data from your backend.
  final ScheduleService scheduleService = Get.find<ScheduleService>();
  final RosterService rosterService = Get.find<RosterService>();
  final PullRepository pullRepo = Get.find<PullRepository>();
  final IOService iOService = Get.find<IOService>();

  // --- ADD THIS HELPER METHOD ---
  /// Normalizes a raw preference value to one of the three diplomatic states.
  double _normalizePreference(double? pref) {
    if (pref == 1.0) {
      return 1.0; // Request
    }
    if (pref == 0.0) {
      return 0.0; // Veto
    }
    // All other values (null, 0.1-0.9) are treated as flexible.
    return 0.5;
  }

  /// Runs the assignment algorithm for a given set of campers and time blocks.
  Future<void> runAlgorithm(
    Commit commit,
    Set<CamperId> camperIds,
    Set<AMABlockId> blockIds, {
    StalemateStrategy stalemateStrategy = StalemateStrategy.leaveUnassigned,
  }) async {
    // 1. CONFIGURE ALGORITHM
    // The pipeline now uses the DiplomaticAlgorithm with a configurable stalemate strategy.
    final AlgorithmPipeline pipeline = AlgorithmPipeline(DiplomaticAlgorithm(stalemateStrategy: stalemateStrategy).steps);

    // 2. FETCH DATA
    // Fetch all raw data concurrently for efficiency.
    final fetchedData = await Future.wait([
      pullRepo.getObjects<Camper>(camperIds),
      scheduleService.getScheduleBlocks(),
      scheduleService.principalActivities,
      scheduleService.activityDependents,
    ]);

    final fetchedCampers = fetchedData[0] as Set<Camper>;
    final allScheduleBlocks = fetchedData[1] as Map<String, ScheduleBlock>;
    final principalActivities = fetchedData[2] as Map<String, PrincipalActivity>;
    final activityDependents = fetchedData[3] as Set<ActivityDependent>;

    // --- LOGIC SEPARATION ---
    // A. Create a map of ALL scheduled activities to their period.
    // This is used ONLY to check if a camper is busy in any way (including hidden).
    final allScheduledActivityToPeriodMap = {
      for (var dep in activityDependents) dep.id: dep.blockRef
    };

    // B. Create a filtered list of activities and scheduled instances that are NOT hidden.
    // This is what the algorithm will actually try to assign.
    final nonHiddenActivities = Map.fromEntries(
      principalActivities.entries.where((e) => e.value.category != ActivityCategory.hidden),
    );

    final allActivities = Map.fromEntries(
      nonHiddenActivities.entries.map(
        (entry) => MapEntry(
          entry.key,
          AlgoActivity(
            id: entry.value.id,
            capacity: entry.value.capacity,
            maxAssignments: entry.value.maxAssignments,
            doubleSchedule: entry.value.doubleSchedule,
          ),
        ),
      ),
    );

    final allScheduledActivities = {
      for (var dep in activityDependents)
        // Ensure we only consider scheduled activities that are not hidden
        if (nonHiddenActivities.containsKey(dep.principalPar))
          dep.id: AlgoScheduledActivity(id: dep.id, activityId: dep.principalPar, periodId: dep.blockRef),
    };

    // Create maps for efficient lookups later.
    final camperMap = {for (var c in fetchedCampers) c.id: c};
    final activityDepMap = {for (var ad in activityDependents) ad.id: ad};

    // This provides the complete, unfiltered list of existing assignment IDs.
    final existingAssignments = {
      for (var c in fetchedCampers)
        c.id: c.activityAssignmentRefs.values.whereType<String>().toList()
    };

    for (final blockId in blockIds) {
      final scheduledInPeriod = allScheduledActivities.values.where((sa) => sa.periodId == blockId);
      scheduledInPeriod.fold<int>(0, (sum, scheduled) {
        final activity = allActivities[scheduled.activityId];
        return sum + (activity?.capacity ?? 0);
      });

      // ignore: unused_local_variable
      int unassignedCampersCount = 0;
      for (final camper in fetchedCampers) {
        final assignments = existingAssignments[camper.id] ?? [];
        final isAssigned =
            assignments.any((id) => allScheduledActivityToPeriodMap[id] == blockId);
        if (!isAssigned) {
          unassignedCampersCount++;
        }
      }

      // if (totalCapacity < unassignedCampersCount) {
      //   throw Exception('Insufficient capacity in period $blockId. Required: $unassignedCampersCount, Available: $totalCapacity');
      // }
    }

    final allAmaBlocks = Map.fromEntries(
      allScheduleBlocks.entries
          .where((e) => e.value is AMABlock)
          .map((entry) => MapEntry(entry.key, AlgoPeriod(id: entry.value.id, start: entry.value.start))),
    );

    final participants = {for (var c in fetchedCampers) c.id: AlgoParticipant(id: c.id, birthdate: c.birthdate)};

    // --- NORMALIZE PREFERENCES DURING CONTEXT CREATION ---
    final context = AssignmentContext(
      participants: participants,
      participantPreferences: {
        for (var c in fetchedCampers)
          c.id: c.preferenceRefs.map((key, value) => MapEntry(key, _normalizePreference(value)))
      },
      targetPeriods: {for (var id in blockIds) id: allAmaBlocks[id]!},
      allActivities: allActivities,
      allScheduledActivities: allScheduledActivities,
      existingAssignments: existingAssignments,
      weeklyPeriodsSorted: allAmaBlocks.values.toList()
        ..sort((a, b) => a.start.toUtc().compareTo(b.start.toUtc())),
      allScheduledActivityToPeriodMap: allScheduledActivityToPeriodMap,
    );

    // 4. RUN ALGORITHM
    final AssignmentResult result = pipeline.run(context);

    // 5. PROCESS & COMMIT RESULTS
    // --- NEW: Commit the successful assignments ---
    for (final assignment in result.successfulAssignments) {
      final camper = camperMap[assignment.participant.id];
      final activityDep = activityDepMap[assignment.scheduledActivity.id];

      if (camper != null && activityDep != null) {
        await rosterService.assignCamperToActivityEfficient(commit, camper, activityDep, activityDependents, true);
      }
    }

    final satisfactionCalculator = SatisfactionCalculator();
    for (final camperId in context.participants.keys) {
      final score = satisfactionCalculator.calculate(participantId: camperId, context: context, result: result);
      // Use the camperMap to get the camper object instantly
      final camper = camperMap[camperId];
      if (camper != null && score != null) {
        camper.activitySatisfactionIndex = score;
        commit.addObjectToPush(camper);
      }
    }

    // --- ADD THIS SECTION ---
    // 6. EXPORT THE EVALUATION REPORT
    if (result.evaluationReports.isNotEmpty) {
      await iOService.exportEvaluationReportAsCsv(
        reports: result.evaluationReports,
        fileName: 'assignment_evaluation_report.csv',
      );
    }
  }
}
