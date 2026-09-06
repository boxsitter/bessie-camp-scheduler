import  '../../data_models/interfaces/algorithm_step.dart';
import '../../data_models/pipeline_state.dart';
import '../../evaluation/diplomatic_satisfaction_evaluator.dart';
import '../../evaluation/novelty_evaluator.dart';
import '../../evaluation/participant_evaluation_report.dart';
import '../../evaluation/step_report.dart';

/// An algorithm step that evaluates the final assignments for each participant.
class GenerateEvaluationReportStep extends AlgorithmStep {
  @override
  String get stepName => 'Generate Evaluation Report';

  @override
  StepReport execute(PipelineState state) {
    final satisfactionEvaluator = DiplomaticSatisfactionEvaluator();
    final noveltyEvaluator = NoveltyEvaluator();
    final reports = <ParticipantEvaluationReport>[];

    for (final participantId in state.context.participants.keys) {
      final isSatisfied = satisfactionEvaluator.isSatisfied(
        participantId: participantId,
        context: state.context,
        result: state.result,
      );

      final noveltyScore = noveltyEvaluator.calculateNoveltyPercentage(
        participantId: participantId,
        result: state.result,
      );

      reports.add(
        ParticipantEvaluationReport(
          participantId: participantId,
          preferencesSatisfied: isSatisfied,
          noveltyScore: noveltyScore,
        ),
      );
    }

    // Store the generated reports in the assignment result.
    state.result.evaluationReports = reports;

    return StepReport(
      stepName: stepName,
      summary: 'Generated evaluation reports for ${reports.length} participants.',
      details: {'count': reports.length},
      duration: Duration.zero,
    );
  }
}