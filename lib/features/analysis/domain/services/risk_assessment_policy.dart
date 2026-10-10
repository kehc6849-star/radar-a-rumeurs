import '../models/detected_signal.dart';
import '../models/verdict_level.dart';

/// Turns detected signals into a score and a verdict level.
class RiskAssessmentPolicy {
  const RiskAssessmentPolicy._();

  static const int maximumRiskScore = 100;

  /// Below this score, nothing important was found.
  static const int suspiciousScoreThreshold = 20;

  /// From this score, one strong signal (or several weak ones) is enough
  /// to warn the user clearly.
  static const int dangerousScoreThreshold = 45;

  static int computeRiskScore(List<DetectedSignal> detectedSignals) {
    final int totalWeight = detectedSignals.fold<int>(
      0,
      (int runningTotal, DetectedSignal signal) => runningTotal + signal.weight,
    );

    return totalWeight > maximumRiskScore ? maximumRiskScore : totalWeight;
  }

  static VerdictLevel determineLevel(int riskScore) {
    if (riskScore >= dangerousScoreThreshold) {
      return VerdictLevel.dangerous;
    }

    if (riskScore >= suspiciousScoreThreshold) {
      return VerdictLevel.suspicious;
    }

    return VerdictLevel.noSignalFound;
  }
}
