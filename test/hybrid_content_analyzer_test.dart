import 'package:flutter_test/flutter_test.dart';
import 'package:radar_a_rumeurs/features/analysis/domain/models/ai_consent_status.dart';
import 'package:radar_a_rumeurs/features/analysis/domain/models/analysis_source.dart';
import 'package:radar_a_rumeurs/features/analysis/domain/models/analysis_verdict.dart';
import 'package:radar_a_rumeurs/features/analysis/domain/services/content_validation_exception.dart';
import 'package:radar_a_rumeurs/features/analysis/domain/services/hybrid_content_analyzer.dart';
import 'package:radar_a_rumeurs/features/analysis/domain/services/remote_analysis_gateway.dart';

import 'support/test_fakes.dart';

const String _harmlessMessage = 'Salut, on se retrouve demain à 18h ?';

HybridContentAnalyzer buildAnalyzer({
  required FakeRemoteAnalysisGateway gateway,
  required AiConsentStatus consentStatus,
}) {
  return HybridContentAnalyzer(
    localAnalyzer: buildLocalAnalyzer(),
    remoteGateway: gateway,
    consentRepository: FakeAiConsentRepository(consentStatus),
  );
}

void main() {
  group('HybridContentAnalyzer', () {
    test('uses only the local rules when no server is configured', () async {
      final FakeRemoteAnalysisGateway gateway = FakeRemoteAnalysisGateway(
        isConfigured: false,
        result: buildRemoteResult(),
      );

      final AnalysisVerdict verdict = await buildAnalyzer(
        gateway: gateway,
        consentStatus: AiConsentStatus.granted,
      ).analyzeContent(_harmlessMessage);

      expect(verdict.source, AnalysisSource.localRules);
      expect(gateway.textCallCount, 0);
    });

    test('sends nothing when the user has not decided or has declined', () async {
      for (final AiConsentStatus status in <AiConsentStatus>[
        AiConsentStatus.undecided,
        AiConsentStatus.declined,
      ]) {
        final FakeRemoteAnalysisGateway gateway =
            FakeRemoteAnalysisGateway(result: buildRemoteResult());

        final AnalysisVerdict verdict = await buildAnalyzer(
          gateway: gateway,
          consentStatus: status,
        ).analyzeContent(_harmlessMessage);

        expect(verdict.source, AnalysisSource.localRules);
        expect(gateway.textCallCount, 0);
      }
    });

    test('combines local rules and AI when the user agreed', () async {
      final FakeRemoteAnalysisGateway gateway =
          FakeRemoteAnalysisGateway(result: buildRemoteResult(riskScore: 70));

      final AnalysisVerdict verdict = await buildAnalyzer(
        gateway: gateway,
        consentStatus: AiConsentStatus.granted,
      ).analyzeContent(_harmlessMessage);

      expect(verdict.source, AnalysisSource.hybrid);
      expect(verdict.riskScore, 70);
      expect(gateway.textCallCount, 1);
    });

    test('falls back to local rules with a notice when the AI is rate limited', () async {
      final FakeRemoteAnalysisGateway gateway = FakeRemoteAnalysisGateway(
        failure: const RemoteAnalysisException(
          RemoteAnalysisFailureKind.rateLimited,
          'slow down',
        ),
      );

      final AnalysisVerdict verdict = await buildAnalyzer(
        gateway: gateway,
        consentStatus: AiConsentStatus.granted,
      ).analyzeContent(_harmlessMessage);

      expect(verdict.source, AnalysisSource.localRules);
      expect(verdict.notice, contains('sollicitée'));
    });

    test('falls back to local rules with a notice when the network fails', () async {
      final FakeRemoteAnalysisGateway gateway = FakeRemoteAnalysisGateway(
        failure: const RemoteAnalysisException(
          RemoteAnalysisFailureKind.network,
          'offline',
        ),
      );

      final AnalysisVerdict verdict = await buildAnalyzer(
        gateway: gateway,
        consentStatus: AiConsentStatus.granted,
      ).analyzeContent(_harmlessMessage);

      expect(verdict.source, AnalysisSource.localRules);
      expect(verdict.notice, contains('indisponible'));
    });

    test('bad input is refused before any network call', () async {
      final FakeRemoteAnalysisGateway gateway =
          FakeRemoteAnalysisGateway(result: buildRemoteResult());

      await expectLater(
        buildAnalyzer(
          gateway: gateway,
          consentStatus: AiConsentStatus.granted,
        ).analyzeContent('   '),
        throwsA(isA<ContentValidationException>()),
      );

      expect(gateway.textCallCount, 0);
    });
  });
}
