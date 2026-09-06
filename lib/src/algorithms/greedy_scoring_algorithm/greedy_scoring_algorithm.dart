

import 'package:bessie/src/algorithms/greedy_scoring_algorithm/score_assignments_step.dart';

import '../common/constraints/adjacent_repetition_constraint.dart';
import '../common/constraints/capacity_constraint.dart';
import '../common/constraints/double_schedule_constraint.dart';
import '../common/constraints/reassignment_constraint.dart';
import '../common/steps/generate_potential_assignments_step.dart';
import '../common/steps/process_assignments_step.dart';
import '../common/steps/sort_assignments_step.dart';
import '../data_models/interfaces/algorithm_step.dart';
import '../data_models/interfaces/assignment_algorithm.dart';

class GreedyScoringAlgorithm implements AssignmentAlgorithm {
  @override
  List<AlgorithmStep> get steps => [
    GeneratePotentialAssignmentsStep(),
    ScoreAssignmentsStep(),
    SortAssignmentsStep(),
    ProcessAssignmentsStep(constraints: [CapacityConstraint(), ReassignmentConstraint(), AdjacentRepetitionConstraint(), DoubleScheduleConstraint()]),
  ];
}
