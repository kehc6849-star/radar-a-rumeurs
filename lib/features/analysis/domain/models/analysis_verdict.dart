import 'analysis_source.dart';
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
    this.source = AnalysisSource.localRules,
    this.aiModelName,
    this.notice,
  })  : signals = List<DetectedSignal>.unmodifiable(signals),
        recommendedActions = List<String>.unmodifiable(recommendedActions);

  final VerdictLevel level;

  /// Estimated risk between 0 and 100. It is an estimate, not a proof.
  final int riskScore;

  final List<DetectedSignal> signals;
  final String summary;
  final List<String> recommendedActions;
  final DateTime analyzedAt;
  final AnalysisSource source;

  /// Name of the AI model, when the AI took part in the verdict.
  final String? aiModelName;

  /// A message for the user, for example when the AI could not be reached.
  final String? notice;

  AnalysisVerdict withNotice(String noticeText) {
    return AnalysisVerdict(
      level: level,
      riskScore: riskScore,
      signals: signals,
      summary: summary,
      recommendedActions: recommendedActions,
      analyzedAt: analyzedAt,
      source: source,
      aiModelName: aiModelName,
      notice: noticeText,
    );
  }
}
