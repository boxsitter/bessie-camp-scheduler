import '../pipeline_state.dart';

/// What a step reports about its own work. The `AlgorithmPipeline` turns this
/// into a `StepReport` by adding the step name and the measured duration, so
/// steps never deal with timing.
class StepOutcome {
  final String summary;
  final Map<String, dynamic> details;

  const StepOutcome({required this.summary, this.details = const {}});
}

/// A single, isolated step of the assignment pipeline.
///
/// A step reads and transforms the shared [PipelineState] and returns a
/// [StepOutcome] describing what it did.
abstract class AlgorithmStep {
  /// A descriptive name for the step, used in its `StepReport`.
  String get stepName;

  /// Executes the logic of this step.
  StepOutcome execute(PipelineState state);
}
