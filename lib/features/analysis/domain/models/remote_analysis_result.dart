import 'threat_family.dart';

class RemoteSignal {
  const RemoteSignal({
    required this.title,
    required this.explanation,
  });

  final String title;
  final String explanation;
}

/// The answer of the analysis server, already checked and cleaned.
class RemoteAnalysisResult {
  RemoteAnalysisResult({
    required this.riskScore,
    required this.threatFamily,
    required List<RemoteSignal> signals,
    required List<String> recommendedActions,
    required this.modelName,
    this.extractedText,
  })  : signals = List<RemoteSignal>.unmodifiable(signals),
        recommendedActions = List<String>.unmodifiable(recommendedActions);

  final int riskScore;
  final ThreatFamily? threatFamily;
  final List<RemoteSignal> signals;
  final List<String> recommendedActions;
  final String modelName;

  /// Text read from a screenshot. It is only used in memory, never stored.
  final String? extractedText;
}
