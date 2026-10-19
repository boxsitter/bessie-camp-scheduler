import '../../data_models/interfaces/algorithm_step.dart';
import '../../data_models/pipeline_state.dart';
import '../../evaluation/diplomatic_satisfaction_evaluator.dart';
import '../../evaluation/novelty_evaluator.dart';
import '../../evaluation/participant_evaluation_report.dart';
import '../../evaluation/satisfaction_calculator.dart';

/// The last step: evaluates every participant's whole week (existing plus new
/// placements) and stores the evaluation reports and the satisfaction indexes
/// in the pipeline state.
class GenerateEvaluationReportStep extends AlgorithmStep {
  @override
  String get stepName => 'Generate Evaluation Report';

  @override
  StepOutcome execute(PipelineState state) {
    final satisfactionEvaluator = DiplomaticSatisfactionEvaluator();
    final noveltyEvaluator = NoveltyEvaluator();
    final satisfactionCalculator = SatisfactionCalculator();
    final reports = <ParticipantEvaluationReport>[];

    for (final participant in state.context.participants) {
      final participantId = participant.id;

      reports.add(
        ParticipantEvaluationReport(
          participantId: participantId,
          preferencesSatisfied: satisfactionEvaluator.isSatisfied(
            participantId: participantId,
            context: state.context,
            ledger: state.ledger,
          ),
          noveltyScore: noveltyEvaluator.calculateNoveltyPercentage(
            participantId: participantId,
            ledger: state.ledger,
          ),
        ),
      );

      final satisfaction = satisfactionCalculator.calculate(
        participantId: participantId,
        context: state.context,
        ledger: state.ledger,
        stalemates: state.stalemates,
      );
      if (satisfaction != null) {
        state.satisfaction[participantId] = satisfaction;
      }
    }

    state.evaluationReports = reports;

    return StepOutcome(
      summary:
          'Evaluated ${reports.length} participants; '
          '${state.satisfaction.length} have a satisfaction index.',
      details: {
        'count': reports.length,
        'scoredParticipants': state.satisfaction.length,
      },
    );
  }
}
