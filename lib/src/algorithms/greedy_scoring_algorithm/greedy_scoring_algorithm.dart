import 'dart:math';

import '../common/steps/standard_steps.dart';
import '../data_models/enums.dart';
import '../data_models/interfaces/algorithm_step.dart';
import '../data_models/interfaces/assignment_algorithm.dart';
import 'greedy_scorer.dart';

/// The preference-tier strategy: same pipeline as the diplomatic one, scored
/// by [GreedyScorer].
class GreedyScoringAlgorithm implements AssignmentAlgorithm {
  final StalemateStrategy stalemateStrategy;
  final Random _random;

  GreedyScoringAlgorithm({
    this.stalemateStrategy = StalemateStrategy.leaveUnassigned,
    Random? random,
  }) : _random = random ?? Random();

  @override
  List<AlgorithmStep> get steps => buildStandardSteps(
    scorer: const GreedyScorer(),
    stalemateStrategy: stalemateStrategy,
    random: _random,
  );
}
