import 'dart:typed_data';
import 'package:radar_a_rumeurs/features/analysis/domain/models/remote_analysis_result.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:radar_a_rumeurs/features/analysis/domain/models/ai_consent_status.dart';
import 'package:radar_a_rumeurs/features/analysis/domain/models/analysis_source.dart';
import 'package:radar_a_rumeurs/features/analysis/domain/models/analysis_verdict.dart';
import 'package:radar_a_rumeurs/features/analysis/domain/models/detected_signal.dart';
import 'package:radar_a_rumeurs/features/analysis/domain/models/screenshot_input.dart';
import 'package:radar_a_rumeurs/features/analysis/domain/models/verdict_level.dart';
import 'package:radar_a_rumeurs/features/analysis/domain/services/analysis_unavailable_exception.dart';
import 'package:radar_a_rumeurs/features/analysis/domain/services/content_validation_exception.dart';
import 'package:radar_a_rumeurs/features/analysis/domain/services/remote_analysis_gateway.dart';
import 'package:radar_a_rumeurs/features/analysis/domain/services/screenshot_verdict_analyzer.dart';

import 'support/test_fakes.dart';

final ScreenshotInput _screenshot = ScreenshotInput(
  imageBytes: Uint8List.fromList(<int>[1, 2, 3, 4]),
  mimeType: 'image/png',
);

ScreenshotVerdictAnalyzer buildAnalyzer({
  required FakeRemoteAnalysisGateway gateway,
  AiConsentStatus consentStatus = AiConsentStatus.granted,
}) {
  return ScreenshotVerdictAnalyzer(
    localAnalyzer: buildLocalAnalyzer(),
    remoteGateway: gateway,
    consentRepository: FakeAiConsentRepository(consentStatus),
  );
}

void main() {
  group('ScreenshotVerdictAnalyzer', () {
    test('is unavailable when no server is configured', () async {
      final FakeRemoteAnalysisGateway gateway = FakeRemoteAnalysisGateway(
        isConfigured: false,
        result: buildRemoteResult(),
      );

      await expectLater(
        buildAnalyzer(gateway: gateway).analyzeScreenshot(_screenshot),
        throwsA(isA<AnalysisUnavailableException>()),
      );
    });

    test('is unavailable without the consent of the user', () async {
      final FakeRemoteAnalysisGateway gateway =
          FakeRemoteAnalysisGateway(result: buildRemoteResult());

      await expectLater(
        buildAnalyzer(
          gateway: gateway,
          consentStatus: AiConsentStatus.undecided,
        ).analyzeScreenshot(_screenshot),
        throwsA(isA<AnalysisUnavailableException>()),
      );

      expect(gateway.screenshotCallCount, 0);
    });

    test('runs the local rules on the text read by the AI', () async {
      final FakeRemoteAnalysisGateway gateway = FakeRemoteAnalysisGateway(
        result: buildRemoteResult(
          riskScore: 10,
          signals: const <RemoteSignal>[],
          extractedText:
              'Bonjour, je vous ai envoyé 25 000 FCFA par erreur, merci de me les renvoyer.',
        ),
      );

      final AnalysisVerdict verdict =
          await buildAnalyzer(gateway: gateway).analyzeScreenshot(_screenshot);

      expect(verdict.level, VerdictLevel.dangerous);
      expect(verdict.source, AnalysisSource.hybrid);
      expect(
        verdict.signals.any(
          (DetectedSignal signal) =>
              signal.ruleIdentifier == 'mistaken_transfer_claim',
        ),
        isTrue,
      );
    });

    test('still gives a verdict when the image contains no readable text', () async {
      final FakeRemoteAnalysisGateway gateway = FakeRemoteAnalysisGateway(
        result: buildRemoteResult(riskScore: 60, extractedText: ''),
      );

      final AnalysisVerdict verdict =
          await buildAnalyzer(gateway: gateway).analyzeScreenshot(_screenshot);

      expect(verdict.riskScore, 60);
      expect(verdict.level, VerdictLevel.dangerous);
    });

    test('server failures become a message for the user', () async {
      final FakeRemoteAnalysisGateway gateway = FakeRemoteAnalysisGateway(
        failure: const RemoteAnalysisException(
          RemoteAnalysisFailureKind.network,
          'offline',
        ),
      );

      await expectLater(
        buildAnalyzer(gateway: gateway).analyzeScreenshot(_screenshot),
        throwsA(isA<AnalysisUnavailableException>()),
      );
    });

    test('an empty image is refused', () async {
      final FakeRemoteAnalysisGateway gateway =
          FakeRemoteAnalysisGateway(result: buildRemoteResult());

      await expectLater(
        buildAnalyzer(gateway: gateway).analyzeScreenshot(
          ScreenshotInput(imageBytes: Uint8List(0), mimeType: 'image/png'),
        ),
        throwsA(isA<ContentValidationException>()),
      );

      expect(gateway.screenshotCallCount, 0);
    });
  });
}
