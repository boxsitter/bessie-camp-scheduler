import 'dart:math';

import '../common/steps/standard_steps.dart';
import '../data_models/enums.dart';
import '../data_models/interfaces/algorithm_step.dart';
import '../data_models/interfaces/assignment_algorithm.dart';
import 'diplomatic_scorer.dart';

/// The production strategy: unfulfilled requests first, then novel activities,
/// then repeats (see [DiplomaticScorer]).
class DiplomaticAlgorithm implements AssignmentAlgorithm {
  final StalemateStrategy stalemateStrategy;
  final Random _random;

  DiplomaticAlgorithm({
    this.stalemateStrategy = StalemateStrategy.leaveUnassigned,
    Random? random,
  }) : _random = random ?? Random();

  @override
  List<AlgorithmStep> get steps => buildStandardSteps(
    scorer: const DiplomaticScorer(),
    stalemateStrategy: stalemateStrategy,
    random: _random,
  );
}
