import 'dart:math';

import 'package:bessie/src/algorithms/assignment_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/invariants.dart';
import 'support/scenario_builder.dart';

/// A realistic camp: 300 campers, 3 days of 5 periods (15 periods), 25
/// activities offered in every period (5 of them double-schedule, 5 capped at
/// two assignments), 3 requests and 1 veto per camper. That is ~112k raw
/// (camper, period, activity) combinations, ~104k candidates once vetoes and
/// unfinishable doubles are removed.
AssignmentContext bigCamp({int campers = 300, int seed = 42}) {
  final rnd = Random(seed);
  final builder = ScenarioBuilder()
      .day('mon', periods: 5)
      .day('tue', periods: 5)
      .day('wed', periods: 5);
  for (var a = 0; a < 25; a++) {
    builder
        .activity(
          'a$a',
          capacity: 15,
          doubleSchedule: a >= 5 && a < 10,
          maxAssignments: a < 5 ? 2 : null,
        )
        .offerEverywhere('a$a');
  }
  for (var i = 0; i < campers; i++) {
    final picks =
        ([for (var a = 0; a < 25; a++) 'a$a']..shuffle(rnd)).take(4).toList();
    builder.participant(
      'c$i',
      age: 7 + i % 9,
      requests: picks.take(3).toList(),
      vetoes: [picks.last],
    );
  }
  return builder.build();
}

void main() {
  // The budget is deliberately generous so the test is robust on slow CI (the
  // engine needs roughly a tenth of it on a development machine) while still
  // catching any return to per-candidate list scans, which are O(N^2).
  const budget = Duration(seconds: 5);

  for (final strategy in AssignmentStrategy.values) {
    test(
      '300 campers x 15 periods x 25 activities (${strategy.name}) finishes in a few seconds',
      () {
        final context = bigCamp();
        final stopwatch = Stopwatch()..start();
        final result = AssignmentEngine.run(
          context,
          strategy: strategy,
          random: Random(1),
        );
        stopwatch.stop();

        final candidates =
            result.stepReports.first.details['count']
                as int; // 'Generate Potential Assignments'
        expect(candidates, greaterThan(100000));
        // ignore: avoid_print
        print(
          '${strategy.name}: $candidates candidates, ${result.newPlacements.length} placements, '
          '${result.stalemates.length} stalemates in ${stopwatch.elapsedMilliseconds} ms '
          '(${result.stepReports.map((r) => '${r.stepName.split(' ').first}=${r.duration.inMilliseconds}ms').join(', ')})',
        );

        expect(stopwatch.elapsed, lessThan(budget));

        // And the result is right, not just fast: 300 x 15 slots, ample seats.
        expect(result.newPlacements.length, greaterThan(4000));
        expectEngineInvariants(context, result, label: strategy.name);
      },
    );
  }

  test('a camp with heavy existing enrollment is also fast', () {
    // Everyone already holds the first period (hidden activity) and half the
    // seats of every activity are taken by campers outside the run.
    final rnd = Random(7);
    final builder = ScenarioBuilder()
        .day('mon', periods: 5)
        .day('tue', periods: 5)
        .day('wed', periods: 5);
    builder.activity('staff', assignable: false, capacity: 1000).offer(
      'staff',
      ['mon1'],
    );
    for (var a = 0; a < 25; a++) {
      builder.activity('a$a', capacity: 12).offerEverywhere('a$a');
      for (final p in ['mon', 'tue', 'wed']) {
        for (var i = 1; i <= 5; i++) {
          builder.external('a$a@$p$i', 6);
        }
      }
    }
    for (var i = 0; i < 300; i++) {
      builder.participant(
        'c$i',
        age: 7 + i % 9,
        requests: ['a${rnd.nextInt(25)}'],
      );
      builder.existing('c$i', ['staff@mon1']);
    }
    final context = builder.build();

    final stopwatch = Stopwatch()..start();
    final result = AssignmentEngine.run(context, random: Random(2));
    stopwatch.stop();

    expect(stopwatch.elapsed, lessThan(budget));
    expectEngineInvariants(context, result);
  });
}
