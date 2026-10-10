import 'detected_signal.dart';
import 'verdict_level.dart';

/// Final answer of an analysis, ready to be displayed.
class AnalysisVerdict {
  AnalysisVerdict({
    required this.level,
    required this.riskScore,
    required List<DetectedSignal> signals,
    required this.summary,
    required List<String> recommendedActions,
    required this.analyzedAt,
  })  : signals = List<DetectedSignal>.unmodifiable(signals),
        recommendedActions = List<String>.unmodifiable(recommendedActions);

  final VerdictLevel level;

  /// Estimated risk between 0 and 100. It is an estimate, not a proof.
  final int riskScore;

  final List<DetectedSignal> signals;
  final String summary;
  final List<String> recommendedActions;
  final DateTime analyzedAt;
}
