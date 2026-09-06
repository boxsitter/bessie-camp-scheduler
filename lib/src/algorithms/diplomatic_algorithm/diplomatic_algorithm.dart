import 'package:bessie/src/algorithms/diplomatic_algorithm/score_diplomatic_assignments_step.dart';

import '../common/constraints/adjacent_repetition_constraint.dart';
import '../common/constraints/capacity_constraint.dart';
import '../common/constraints/double_schedule_constraint.dart';
import '../common/constraints/reassignment_constraint.dart';
import '../common/steps/generate_evaluation_report.dart';
import '../common/steps/generate_potential_assignments_step.dart';
import '../common/steps/process_assignments_step.dart';
import '../common/steps/sort_assignments_step.dart';
import '../data_models/enums.dart';
import '../data_models/interfaces/algorithm_step.dart';
import '../data_models/interfaces/assignment_algorithm.dart';

class DiplomaticAlgorithm implements AssignmentAlgorithm {
  final StalemateStrategy stalemateStrategy;

  DiplomaticAlgorithm({this.stalemateStrategy = StalemateStrategy.leaveUnassigned});

  @override
  List<AlgorithmStep> get steps => [
    GeneratePotentialAssignmentsStep(),
    ScoreDiplomaticAssignmentsStep(),
    SortAssignmentsStep(),
    ProcessAssignmentsStep(
      constraints: [CapacityConstraint(), ReassignmentConstraint(), AdjacentRepetitionConstraint(), DoubleScheduleConstraint()],
      stalemateStrategy: stalemateStrategy,
    ),
    GenerateEvaluationReportStep(),
  ];
}
