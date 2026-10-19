import 'algorithm_step.dart';

/// A scheduling strategy: an ordered combination of pipeline steps.
abstract class AssignmentAlgorithm {
  /// The steps, in execution order.
  List<AlgorithmStep> get steps;
}
