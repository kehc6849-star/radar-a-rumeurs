import '../models/analysis_source.dart';
import '../models/analysis_verdict.dart';
import '../models/detected_signal.dart';
import '../models/remote_analysis_result.dart';
import '../models/threat_family.dart';
import '../models/verdict_level.dart';
import 'risk_assessment_policy.dart';
import 'safety_advice_catalog.dart';
import 'verdict_summary_catalog.dart';

/// Combines the local verdict and the AI result into one verdict.
///
/// Main rule: the AI can RAISE the risk, never lower it below what the local
/// rules found. This protects the user when a message tries to fool the model.
class VerdictFusionPolicy {
  const VerdictFusionPolicy();

  static const int _maximumAiActionCount = 3;

  AnalysisVerdict merge({
    required AnalysisVerdict localVerdict,
    required RemoteAnalysisResult remoteResult,
  }) {
    final int mergedRiskScore = remoteResult.riskScore > localVerdict.riskScore
        ? remoteResult.riskScore
        : localVerdict.riskScore;
    final VerdictLevel mergedLevel =
        RiskAssessmentPolicy.determineLevel(mergedRiskScore);

    final ThreatFamily signalFamily = remoteResult.threatFamily ??
        _findStrongestLocalFamily(localVerdict) ??
        ThreatFamily.phishing;

    final List<DetectedSignal> mergedSignals = <DetectedSignal>[
      ...localVerdict.signals,
      ..._convertRemoteSignals(remoteResult, signalFamily),
    ];

    // Strongest signals first, like in the local engine.
    mergedSignals.sort(
      (DetectedSignal firstSignal, DetectedSignal secondSignal) =>
          secondSignal.weight.compareTo(firstSignal.weight),
    );

    final List<String> mergedActions = _buildActions(
      mergedLevel: mergedLevel,
      mergedSignals: mergedSignals,
      remoteResult: remoteResult,
    );

    return AnalysisVerdict(
      level: mergedLevel,
      riskScore: mergedRiskScore,
      signals: mergedSignals,
      summary: VerdictSummaryCatalog.buildSummary(mergedLevel),
      recommendedActions: mergedActions,
      analyzedAt: DateTime.now(),
      source: AnalysisSource.hybrid,
      aiModelName: remoteResult.modelName,
    );
  }

  ThreatFamily? _findStrongestLocalFamily(AnalysisVerdict localVerdict) {
    if (localVerdict.signals.isEmpty) {
      return null;
    }

    // Local signals are already sorted: the first one is the strongest.
    return localVerdict.signals.first.family;
  }

  List<DetectedSignal> _convertRemoteSignals(
    RemoteAnalysisResult remoteResult,
    ThreatFamily signalFamily,
  ) {
    if (remoteResult.signals.isEmpty) {
      return const <DetectedSignal>[];
    }

    // AI signals have no weight of their own: the AI score is shared between them.
    final int sharedWeight = _clampWeight(
      (remoteResult.riskScore / remoteResult.signals.length).round(),
    );

    final List<DetectedSignal> convertedSignals = <DetectedSignal>[];

    for (int position = 0; position < remoteResult.signals.length; position++) {
      final RemoteSignal remoteSignal = remoteResult.signals[position];

      convertedSignals.add(
        DetectedSignal(
          ruleIdentifier: 'ai_signal_${position + 1}',
          title: remoteSignal.title,
          explanation: remoteSignal.explanation,
          weight: sharedWeight,
          family: signalFamily,
        ),
      );
    }

    return convertedSignals;
  }

  List<String> _buildActions({
    required VerdictLevel mergedLevel,
    required List<DetectedSignal> mergedSignals,
    required RemoteAnalysisResult remoteResult,
  }) {
    final List<ThreatFamily> orderedFamilies = mergedSignals
        .map((DetectedSignal signal) => signal.family)
        .toList(growable: false);

    // The vetted local advice always comes first.
    final List<String> mergedActions =
        SafetyAdviceCatalog.buildAdvice(orderedFamilies).toList();

    if (mergedLevel == VerdictLevel.noSignalFound) {
      return mergedActions;
    }

    int addedAiActionCount = 0;

    for (final String aiAction in remoteResult.recommendedActions) {
      if (addedAiActionCount >= _maximumAiActionCount) {
        break;
      }

      if (!mergedActions.contains(aiAction)) {
        mergedActions.add(aiAction);
        addedAiActionCount++;
      }
    }

    return mergedActions;
  }

  int _clampWeight(int weight) {
    if (weight < 1) {
      return 1;
    }

    if (weight > 100) {
      return 100;
    }

    return weight;
  }
}
