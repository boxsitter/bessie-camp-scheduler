import 'dart:math';

import 'package:bessie/src/algorithms/assignment_engine.dart';

import 'scenario_builder.dart';

/// Generates random but always *consistent* scenarios for the property tests:
/// the initial state never double-books anyone and never exceeds a capacity, so
/// any violation found in a result was introduced by the engine.
///
/// A scenario has 1-3 days of 2-5 periods, 4-9 activities (about a quarter are
/// double-schedule, a few are hidden, some have an assignment cap), 3-20
/// participants with random requests and vetoes, a few existing assignments
/// (hidden activities and complete double blocks included), seats taken by
/// campers outside the run, and a random subset of periods to fill.
class RandomScenario {
  RandomScenario._();

  static AssignmentContext generate(int seed) {
    final rnd = Random(seed);
    final builder = ScenarioBuilder();

    // --- periods ---
    final periodsByDay = <List<String>>[];
    final dayCount = 1 + rnd.nextInt(3);
    for (var d = 0; d < dayCount; d++) {
      final count = 2 + rnd.nextInt(4);
      builder.day('d$d', periods: count);
      periodsByDay.add([for (var i = 1; i <= count; i++) 'd$d$i']);
    }
    final allPeriods = [for (final day in periodsByDay) ...day];

    // --- activities and their scheduled instances ---
    // Half of the seeds are generous (plenty of seats, activities offered almost
    // everywhere) and half are tight (scarce seats, sparse offering), so both
    // fully-filled schedules and stalemates are well represented.
    final generous = rnd.nextBool();
    final activityCount = 4 + rnd.nextInt(6);
    final capacity = <String, int>{};
    final doubles = <String>{};
    final offered = <String, List<String>>{}; // activityId -> periodIds
    final scheduledIdsByPeriod =
        <String, List<String>>{}; // periodId -> activityIds
    for (var a = 0; a < activityCount; a++) {
      final id = 'a$a';
      final isDouble = rnd.nextInt(4) == 0;
      final hidden =
          a >= 2 && rnd.nextInt(8) == 0; // a0 and a1 are always assignable
      capacity[id] = generous ? 4 + rnd.nextInt(10) : 1 + rnd.nextInt(5);
      if (isDouble) doubles.add(id);
      builder.activity(
        id,
        capacity: capacity[id]!,
        maxAssignments: rnd.nextInt(4) == 0 ? 1 + rnd.nextInt(2) : null,
        doubleSchedule: isDouble,
        assignable: !hidden,
      );
      final periods = [
        for (final p in allPeriods)
          if (rnd.nextInt(10) < (generous ? 8 : 5)) p,
      ];
      if (periods.isEmpty) {
        periods.add(allPeriods[rnd.nextInt(allPeriods.length)]);
      }
      offered[id] = periods;
      builder.offer(id, periods);
      for (final p in periods) {
        (scheduledIdsByPeriod[p] ??= []).add(id);
      }
    }

    // --- participants and preferences ---
    final participantCount = 3 + rnd.nextInt(18);
    final participantIds = [for (var i = 0; i < participantCount; i++) 'p$i'];
    for (final id in participantIds) {
      final requests = <String>[];
      final vetoes = <String>[];
      for (var a = 0; a < activityCount; a++) {
        final roll = rnd.nextDouble();
        if (roll < 0.2) {
          requests.add('a$a');
        } else if (roll < 0.35) {
          vetoes.add('a$a');
        }
      }
      builder.participant(
        id,
        age: 6 + rnd.nextInt(11),
        requests: requests,
        vetoes: vetoes,
      );
    }

    // --- existing assignments (consistent: no double-booking, within capacity) ---
    final seats = <String, int>{}; // scheduledActivityId -> seats taken
    final busy = <String, Set<String>>{}; // participantId -> periodIds
    bool hasSeat(String activityId, String periodId) =>
        (seats[ScenarioBuilder.sa(activityId, periodId)] ?? 0) <
        capacity[activityId]!;
    void take(String participantId, String activityId, String periodId) {
      final saId = ScenarioBuilder.sa(activityId, periodId);
      seats[saId] = (seats[saId] ?? 0) + 1;
      (busy[participantId] ??= {}).add(periodId);
      builder.existing(participantId, [saId]);
    }

    for (final participantId in participantIds) {
      if (rnd.nextInt(4) != 0) continue;
      for (var k = 0; k < 1 + rnd.nextInt(2); k++) {
        final periodId = allPeriods[rnd.nextInt(allPeriods.length)];
        final here = scheduledIdsByPeriod[periodId];
        if (here == null ||
            (busy[participantId]?.contains(periodId) ?? false)) {
          continue;
        }
        final activityId = here[rnd.nextInt(here.length)];
        if (!hasSeat(activityId, periodId)) continue;

        if (!doubles.contains(activityId)) {
          take(participantId, activityId, periodId);
          continue;
        }
        // A double activity is only ever held as a complete block.
        final day = periodsByDay.firstWhere((d) => d.contains(periodId));
        final index = day.indexOf(periodId);
        if (index + 1 >= day.length) continue;
        final nextId = day[index + 1];
        if (!offered[activityId]!.contains(nextId) ||
            (busy[participantId]?.contains(nextId) ?? false) ||
            !hasSeat(activityId, nextId)) {
          continue;
        }
        take(participantId, activityId, periodId);
        take(participantId, activityId, nextId);
      }
    }

    // --- seats taken by campers outside the run ---
    for (final entry in offered.entries) {
      for (final periodId in entry.value) {
        if (rnd.nextInt(10) >= 3) continue;
        final saId = ScenarioBuilder.sa(entry.key, periodId);
        final free = capacity[entry.key]! - (seats[saId] ?? 0);
        if (free > 0) builder.external(saId, 1 + rnd.nextInt(free));
      }
    }

    // --- target periods ---
    final targets = [
      for (final p in allPeriods)
        if (rnd.nextInt(10) < 6) p,
    ];
    if (targets.isEmpty) {
      targets.add(allPeriods[rnd.nextInt(allPeriods.length)]);
    }
    builder.targets(targets);

    return builder.build();
  }
}
