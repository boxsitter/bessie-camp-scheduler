import '../../data_models/interfaces/constraint.dart';
import 'adjacent_repetition_constraint.dart';
import 'capacity_constraint.dart';
import 'double_schedule_constraint.dart';
import 'reassignment_constraint.dart';

/// Every hard rule, enforced by the main selection pass. Cheap checks first.
List<Constraint> standardConstraints() => [
      DoubleScheduleConstraint(),
      CapacityConstraint(),
      ReassignmentConstraint(),
      AdjacentRepetitionConstraint(),
    ];

/// The rules that are still enforced by the `randomize` stalemate fallback:
/// seats are real and a double block must be well-formed. Everything else
/// (assignment caps, adjacent repetition) is relaxed.
List<Constraint> essentialConstraints() => [
      DoubleScheduleConstraint(),
      CapacityConstraint(),
    ];
