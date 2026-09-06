import '../pipeline_state.dart';
import '../../evaluation/step_report.dart';

/// Defines the contract for a single, isolated step in the assignment algorithm pipeline.
///
/// Each step performs a specific transformation on the [PipelineState] and
/// returns a [StepReport] detailing its outcome.
abstract class AlgorithmStep {
  /// A descriptive name for the step, used for logging and reporting.
  String get stepName;

  /// Executes the logic for this step.
  StepReport execute(PipelineState state);
}
