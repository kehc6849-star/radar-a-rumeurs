import '../models/analysis_verdict.dart';
import '../models/detected_signal.dart';
import '../models/normalized_content.dart';
import '../models/threat_family.dart';
import '../models/verdict_level.dart';
import '../rules/scam_detection_rule.dart';
import 'content_analyzer.dart';
import 'content_validator.dart';
import 'risk_assessment_policy.dart';
import 'safety_advice_catalog.dart';
import 'text_normalizer.dart';
import 'verdict_summary_catalog.dart';

/// Analysis engine that runs entirely on the phone with local rules.
///
/// Nothing leaves the device and nothing is stored or logged.
class RuleBasedContentAnalyzer implements ContentAnalyzer {
  RuleBasedContentAnalyzer({
    required List<ScamDetectionRule> rules,
    this.contentValidator = const ContentValidator(),
    this.textNormalizer = const TextNormalizer(),
  }) : _rules = List<ScamDetectionRule>.unmodifiable(rules);

  final List<ScamDetectionRule> _rules;
  final ContentValidator contentValidator;
  final TextNormalizer textNormalizer;

  @override
  Future<AnalysisVerdict> analyzeContent(String rawContent) async {
    final String validatedContent = contentValidator.validate(rawContent);
    final NormalizedContent normalizedContent =
        textNormalizer.normalize(validatedContent);

    final List<DetectedSignal> detectedSignals = <DetectedSignal>[];

    for (final ScamDetectionRule rule in _rules) {
      detectedSignals.addAll(rule.evaluate(normalizedContent));
    }

    // Strongest signals first: they are the most useful for the user.
    detectedSignals.sort(
      (DetectedSignal firstSignal, DetectedSignal secondSignal) =>
          secondSignal.weight.compareTo(firstSignal.weight),
    );

    final int riskScore = RiskAssessmentPolicy.computeRiskScore(detectedSignals);
    final VerdictLevel verdictLevel = RiskAssessmentPolicy.determineLevel(riskScore);

    final List<ThreatFamily> orderedFamilies = detectedSignals
        .map((DetectedSignal signal) => signal.family)
        .toList(growable: false);

    return AnalysisVerdict(
      level: verdictLevel,
      riskScore: riskScore,
      signals: detectedSignals,
      summary: VerdictSummaryCatalog.buildSummary(verdictLevel),
      recommendedActions: SafetyAdviceCatalog.buildAdvice(orderedFamilies),
      analyzedAt: DateTime.now(),
    );
  }
}
