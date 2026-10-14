import 'package:flutter_test/flutter_test.dart';
import 'package:radar_a_rumeurs/features/analysis/domain/models/analysis_source.dart';
import 'package:radar_a_rumeurs/features/analysis/domain/models/analysis_verdict.dart';
import 'package:radar_a_rumeurs/features/analysis/domain/models/detected_signal.dart';
import 'package:radar_a_rumeurs/features/analysis/domain/models/remote_analysis_result.dart';
import 'package:radar_a_rumeurs/features/analysis/domain/models/threat_family.dart';
import 'package:radar_a_rumeurs/features/analysis/domain/models/verdict_level.dart';
import 'package:radar_a_rumeurs/features/analysis/domain/services/verdict_fusion_policy.dart';

import 'support/test_fakes.dart';

void main() {
  const VerdictFusionPolicy fusionPolicy = VerdictFusionPolicy();

  group('VerdictFusionPolicy', () {
    test('the AI can never lower the risk found by the local rules', () async {
      final AnalysisVerdict localVerdict = await buildLocalAnalyzer().analyzeContent(
        'Bonjour, je vous ai envoyé 25 000 FCFA par erreur, merci de me les renvoyer.',
      );
      final RemoteAnalysisResult remoteResult = buildRemoteResult(
        riskScore: 5,
        signals: const <RemoteSignal>[],
        recommendedActions: const <String>[],
      );

      final AnalysisVerdict mergedVerdict = fusionPolicy.merge(
        localVerdict: localVerdict,
        remoteResult: remoteResult,
      );

      expect(mergedVerdict.riskScore, localVerdict.riskScore);
      expect(mergedVerdict.level, VerdictLevel.dangerous);
      expect(mergedVerdict.source, AnalysisSource.hybrid);
    });

    test('the AI can raise the risk and adds its signals', () async {
      final AnalysisVerdict localVerdict = await buildLocalAnalyzer()
          .analyzeContent('Salut, on se retrouve demain à 18h ?');

      final AnalysisVerdict mergedVerdict = fusionPolicy.merge(
        localVerdict: localVerdict,
        remoteResult: buildRemoteResult(riskScore: 70),
      );

      expect(localVerdict.level, VerdictLevel.noSignalFound);
      expect(mergedVerdict.level, VerdictLevel.dangerous);
      expect(mergedVerdict.riskScore, 70);
      expect(mergedVerdict.aiModelName, 'Gemma test');
      expect(
        mergedVerdict.signals.any(
          (DetectedSignal signal) => signal.ruleIdentifier == 'ai_signal_1',
        ),
        isTrue,
      );
      expect(mergedVerdict.recommendedActions, contains('Action IA 1'));
    });

    test('at most three AI actions are added, after the local advice', () async {
      final AnalysisVerdict localVerdict = await buildLocalAnalyzer()
          .analyzeContent('Salut, on se retrouve demain à 18h ?');

      final AnalysisVerdict mergedVerdict = fusionPolicy.merge(
        localVerdict: localVerdict,
        remoteResult: buildRemoteResult(
          recommendedActions: const <String>[
            'Action IA 1',
            'Action IA 2',
            'Action IA 3',
            'Action IA 4',
          ],
        ),
      );

      expect(mergedVerdict.recommendedActions, contains('Action IA 3'));
      expect(mergedVerdict.recommendedActions, isNot(contains('Action IA 4')));
      expect(mergedVerdict.recommendedActions.first, isNot('Action IA 1'));
    });

    test('a low AI score on a harmless message gives no AI advice', () async {
      final AnalysisVerdict localVerdict = await buildLocalAnalyzer()
          .analyzeContent('Salut, on se retrouve demain à 18h ?');

      final AnalysisVerdict mergedVerdict = fusionPolicy.merge(
        localVerdict: localVerdict,
        remoteResult: buildRemoteResult(
          riskScore: 3,
          threatFamily: null,
          signals: const <RemoteSignal>[],
        ),
      );

      expect(mergedVerdict.level, VerdictLevel.noSignalFound);
      expect(mergedVerdict.recommendedActions, isEmpty);
    });

    test('AI signals without a family use the family of the strongest local signal', () async {
      final AnalysisVerdict localVerdict = await buildLocalAnalyzer().analyzeContent(
        'Payez 15 000 FCFA de frais de dossier pour votre bourse.',
      );

      final AnalysisVerdict mergedVerdict = fusionPolicy.merge(
        localVerdict: localVerdict,
        remoteResult: buildRemoteResult(riskScore: 40, threatFamily: null),
      );

      final DetectedSignal aiSignal = mergedVerdict.signals.firstWhere(
        (DetectedSignal signal) => signal.ruleIdentifier == 'ai_signal_1',
      );

      expect(aiSignal.family, ThreatFamily.scholarshipScam);
    });
  });
}
