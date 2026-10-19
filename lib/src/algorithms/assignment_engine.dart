import 'dart:math';

import 'algorithm_pipeline.dart';
import 'data_models/assignment_context.dart';
import 'data_models/assignment_result.dart';
import 'data_models/enums.dart';
import 'data_models/interfaces/assignment_algorithm.dart';
import 'diplomatic_algorithm/diplomatic_algorithm.dart';
import 'greedy_scoring_algorithm/greedy_scoring_algorithm.dart';

export 'data_models/analogs/algo_activity.dart';
export 'data_models/analogs/algo_participant.dart';
export 'data_models/analogs/algo_period.dart';
export 'data_models/analogs/algo_scheduled_activity.dart';
export 'data_models/assignment_context.dart';
export 'data_models/assignment_result.dart';
export 'data_models/assignment_stalemate_exception.dart';
export 'data_models/enums.dart' show AssignmentStrategy, PreferenceType, StalemateStrategy;
export 'evaluation/participant_evaluation_report.dart';
export 'evaluation/step_report.dart';

/// The entry point of the camper-to-activity scheduling engine.
///
/// Pure Dart: it depends on nothing but `dart:*` and `package:collection`, never
/// reads the clock (ages come from [AssignmentContext.now]) and, given a seeded
/// [Random], is fully deterministic.
class AssignmentEngine {
  AssignmentEngine._();

  /// Fills the target periods of [context] with new placements.
  ///
  /// * [strategy] selects the scorer: diplomatic (default) or greedy.
  /// * [stalemateStrategy] decides what happens to slots that cannot be filled:
  ///   leave them (default), throw an [AssignmentStalemateException], or fall
  ///   back to a random placement that only respects capacity.
  /// * [random] drives every random choice (tiebreaks and the `randomize`
  ///   fallback); pass a seeded one for reproducible output.
  static AssignmentResult run(
    AssignmentContext context, {
    AssignmentStrategy strategy = AssignmentStrategy.diplomatic,
    StalemateStrategy stalemateStrategy = StalemateStrategy.leaveUnassigned,
    Random? random,
  }) {
    final AssignmentAlgorithm algorithm = switch (strategy) {
      AssignmentStrategy.diplomatic => DiplomaticAlgorithm(stalemateStrategy: stalemateStrategy, random: random),
      AssignmentStrategy.greedy => GreedyScoringAlgorithm(stalemateStrategy: stalemateStrategy, random: random),
    };
    return AlgorithmPipeline(algorithm.steps).run(context);
  }
}
