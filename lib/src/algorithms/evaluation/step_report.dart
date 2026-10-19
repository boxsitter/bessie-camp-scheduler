/// A timing and summary record of one executed pipeline step.
///
/// Steps do not create these themselves: they return a `StepOutcome` and the
/// `AlgorithmPipeline` measures the wall-clock duration and attaches it.
class StepReport {
  final String stepName;
  final String summary;
  final Duration duration;
  final Map<String, dynamic> details;

  const StepReport({
    required this.stepName,
    required this.summary,
    required this.duration,
    this.details = const {},
  });

  @override
  String toString() {
    return '[$stepName] - ${duration.inMilliseconds}ms: $summary';
  }
}
