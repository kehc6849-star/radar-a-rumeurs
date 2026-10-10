import 'threat_family.dart';

/// One suspicious element found in a message, with a plain explanation.
class DetectedSignal {
  const DetectedSignal({
    required this.ruleIdentifier,
    required this.title,
    required this.explanation,
    required this.weight,
    required this.family,
  }) : assert(weight > 0 && weight <= 100);

  final String ruleIdentifier;
  final String title;
  final String explanation;

  /// How much this signal raises the risk score (between 1 and 100).
  final int weight;

  final ThreatFamily family;
}
