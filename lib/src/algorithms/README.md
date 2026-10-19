# Assignment engine

Pure Dart (only `dart:*` and `package:collection`) camper-to-activity scheduler.
Entry point: `assignment_engine.dart`.

```dart
final result = AssignmentEngine.run(
  AssignmentContext(/* participants, preferences, periods, targetPeriodIds,
                       activities, scheduledActivities, existingAssignments,
                       externalEnrollment, now */),
  strategy: AssignmentStrategy.diplomatic,            // or .greedy
  stalemateStrategy: StalemateStrategy.leaveUnassigned, // or .fail / .randomize
  random: Random(42),                                  // seeded => reproducible
);
result.newPlacements;   // only what this run added
result.satisfaction;    // participantId -> 0..1 (omitted if stalemate / nothing held)
result.stalemates;      // unfillable (participant, period) slots, with reasons
```

The engine never reads the clock (ages use `context.now`) and, given a seeded
`Random`, is fully deterministic.

## Pipeline

`AlgorithmPipeline` runs these steps over a `PipelineState` and times each one
(steps return a `StepOutcome`; the pipeline attaches the duration):

1. **Generate Potential Assignments** - one candidate per free (participant,
   target period, assignable activity). Vetoes and hidden activities are never
   candidates; a double-schedule activity is ONE candidate for the whole block
   and only exists if the next period (same day) offers it and the participant
   is free in both.
2. **Score** - initial score from the strategy's `AssignmentScorer` (pure).
3. **Sort** - one random tiebreak key per candidate (injectable `Random`),
   order by (score desc, tiebreak asc, generation order).
4. **Process** - lazy-greedy selection over a priority queue: pop the best,
   skip if the participant became busy, re-score against the live ledger,
   re-insert if it no longer beats the next one, otherwise check every hard
   constraint (both halves of a double) and accept or drop it for good.
5. **Resolve Stalemates** - for slots still empty: `leaveUnassigned` records
   them, `fail` throws `AssignmentStalemateException`, `randomize` tries the
   participant's non-vetoed activities in random order with only capacity and
   double-schedule feasibility enforced, then records what is still impossible.
6. **Generate Evaluation Report** - per-participant reports and satisfaction
   over the whole week (existing + new placements).

All state about who holds what lives in one `AssignmentLedger` (existing
assignments incl. hidden activities, `externalEnrollment`, new placements) with
indexed counts, so each constraint check is O(1) or O(that participant's
assignments).

## Strategies

Same pipeline, different `AssignmentScorer` (must be pure and never raise a
candidate's score as assignments are made - the lazy loop relies on it):

* **diplomatic** (default): unreceived request 1000 > not-yet-assigned activity
  500 > repeat 10, then the same-day repetition penalty `-50 * 0.6^distance`.
  The age bonus constant is 0.0 (disabled).
* **greedy**: preference tier (request +100, neutral +10, veto -1000) + age
  bonus (max 20 up to age 8, linear to 0 at 13) + the same repetition penalty.

## Constraints

Composable `Constraint.isViolated(candidate, context, ledger)`; violations must
be monotone. `standardConstraints()`: capacity (counts external enrollment,
checks both halves of a double), reassignment (`maxAssignments`, a double block
is one occurrence), adjacent repetition (non-double activities), double-schedule
feasibility. `essentialConstraints()` (capacity + double feasibility) is what
`randomize` still enforces.

## Layout

```
assignment_engine.dart      public facade and exports
algorithm_pipeline.dart     runs and times the steps
data_models/                context, ledger, candidates, result, enums, interfaces
common/constraints/         the four constraints + standard sets
common/scoring/             shared scoring terms (age bonus, repetition penalty)
common/steps/               the pipeline steps and the shared step list
diplomatic_algorithm/       DiplomaticAlgorithm + DiplomaticScorer
greedy_scoring_algorithm/   GreedyScoringAlgorithm + GreedyScorer
evaluation/                 satisfaction, novelty, reports, constants
```

## Running the checks

```
export PATH=/opt/sdk/flutter/bin:$PATH
dart analyze lib/src/algorithms test/algorithms
flutter test test/algorithms
```

Tests live in `test/algorithms/` (scenario builder, random scenario generator,
invariant checks and an eager-greedy oracle are in `test/algorithms/support/`).
