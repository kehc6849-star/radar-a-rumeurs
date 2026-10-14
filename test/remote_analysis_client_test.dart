import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:radar_a_rumeurs/core/configuration/backend_configuration.dart';
import 'package:radar_a_rumeurs/features/analysis/data/remote/remote_analysis_client.dart';
import 'package:radar_a_rumeurs/features/analysis/domain/models/remote_analysis_result.dart';
import 'package:radar_a_rumeurs/features/analysis/domain/models/screenshot_input.dart';
import 'package:radar_a_rumeurs/features/analysis/domain/models/threat_family.dart';
import 'package:radar_a_rumeurs/features/analysis/domain/services/remote_analysis_gateway.dart';

const BackendConfiguration _configuration = BackendConfiguration(
  baseUrl: 'http://127.0.0.1:8000/',
  accessToken: 'test-token',
);

http.Response buildJsonResponse(Object? body, {int statusCode = 200}) {
  return http.Response.bytes(
    utf8.encode(jsonEncode(body)),
    statusCode,
    headers: <String, String>{'content-type': 'application/json'},
  );
}

Matcher throwsRemoteFailure(RemoteAnalysisFailureKind expectedKind) {
  return throwsA(
    isA<RemoteAnalysisException>().having(
      (RemoteAnalysisException error) => error.kind,
      'kind',
      expectedKind,
    ),
  );
}

void main() {
  group('RemoteAnalysisClient', () {
    test('parses a successful answer and keeps the accents', () async {
      late http.Request receivedRequest;

      final RemoteAnalysisClient client = RemoteAnalysisClient(
        configuration: _configuration,
        httpClient: MockClient((http.Request request) async {
          receivedRequest = request;

          return buildJsonResponse(<String, Object?>{
            'riskScore': 82,
            'threatFamily': 'mobileMoneyFraud',
            'signals': <Object?>[
              <String, Object?>{
                'title': 'Code demandé',
                'explanation': 'Le message réclame un code.',
              },
              'not a signal',
            ],
            'recommendedActions': <Object?>['Ne donnez jamais votre code.', ''],
            'extractedText': null,
            'modelName': 'gemma-4-26b-a4b-it',
          });
        }),
      );

      final RemoteAnalysisResult result = await client.analyzeText('Bonjour');

      expect(receivedRequest.url.path, '/v1/analyze');
      expect(receivedRequest.headers['X-Radar-Access-Token'], 'test-token');
      expect(jsonDecode(receivedRequest.body), <String, Object?>{'text': 'Bonjour'});

      expect(result.riskScore, 82);
      expect(result.threatFamily, ThreatFamily.mobileMoneyFraud);
      expect(result.signals.single.title, 'Code demandé');
      expect(result.recommendedActions, <String>['Ne donnez jamais votre code.']);
      expect(result.modelName, 'gemma-4-26b-a4b-it');
      expect(result.extractedText, isNull);
    });

    test('sends a screenshot to the image address', () async {
      late http.Request receivedRequest;

      final RemoteAnalysisClient client = RemoteAnalysisClient(
        configuration: _configuration,
        httpClient: MockClient((http.Request request) async {
          receivedRequest = request;

          return buildJsonResponse(<String, Object?>{
            'riskScore': 40,
            'extractedText': 'texte lu',
          });
        }),
      );

      final RemoteAnalysisResult result = await client.analyzeScreenshot(
        ScreenshotInput(
          imageBytes: Uint8List.fromList(<int>[1, 2, 3]),
          mimeType: 'image/png',
        ),
      );

      expect(receivedRequest.url.path, '/v1/analyze-image');
      expect(result.extractedText, 'texte lu');
      expect(result.threatFamily, isNull);
    });

    test('clamps the risk score and ignores unknown families', () async {
      final RemoteAnalysisClient client = RemoteAnalysisClient(
        configuration: _configuration,
        httpClient: MockClient((http.Request request) async {
          return buildJsonResponse(<String, Object?>{
            'riskScore': 250,
            'threatFamily': 'safe',
          });
        }),
      );

      final RemoteAnalysisResult result = await client.analyzeText('x');

      expect(result.riskScore, 100);
      expect(result.threatFamily, isNull);
    });

    test('maps HTTP errors to failure kinds', () async {
      final Map<int, RemoteAnalysisFailureKind> expectations =
          <int, RemoteAnalysisFailureKind>{
        429: RemoteAnalysisFailureKind.rateLimited,
        500: RemoteAnalysisFailureKind.serverError,
        503: RemoteAnalysisFailureKind.serverError,
        401: RemoteAnalysisFailureKind.serverError,
        422: RemoteAnalysisFailureKind.invalidResponse,
      };

      for (final MapEntry<int, RemoteAnalysisFailureKind> expectation
          in expectations.entries) {
        final RemoteAnalysisClient client = RemoteAnalysisClient(
          configuration: _configuration,
          httpClient: MockClient((http.Request request) async {
            return buildJsonResponse(<String, Object?>{}, statusCode: expectation.key);
          }),
        );

        await expectLater(
          client.analyzeText('x'),
          throwsRemoteFailure(expectation.value),
        );
      }
    });

    test('rejects an answer that is not valid', () async {
      final List<http.Response> badAnswers = <http.Response>[
        http.Response('not json', 200),
        buildJsonResponse(<Object?>[1, 2]),
        buildJsonResponse(<String, Object?>{'signals': <Object?>[]}),
      ];

      for (final http.Response badAnswer in badAnswers) {
        final RemoteAnalysisClient client = RemoteAnalysisClient(
          configuration: _configuration,
          httpClient: MockClient((http.Request request) async => badAnswer),
        );

        await expectLater(
          client.analyzeText('x'),
          throwsRemoteFailure(RemoteAnalysisFailureKind.invalidResponse),
        );
      }
    });

    test('reports a network failure', () async {
      final RemoteAnalysisClient client = RemoteAnalysisClient(
        configuration: _configuration,
        httpClient: MockClient((http.Request request) async {
          throw http.ClientException('connection lost');
        }),
      );

      await expectLater(
        client.analyzeText('x'),
        throwsRemoteFailure(RemoteAnalysisFailureKind.network),
      );
    });

    test('does not call the network when no server is configured', () async {
      int callCount = 0;

      final RemoteAnalysisClient client = RemoteAnalysisClient(
        configuration: const BackendConfiguration.disabled(),
        httpClient: MockClient((http.Request request) async {
          callCount++;
          return buildJsonResponse(<String, Object?>{'riskScore': 1});
        }),
      );

      expect(client.isConfigured, isFalse);

      await expectLater(
        client.analyzeText('x'),
        throwsRemoteFailure(RemoteAnalysisFailureKind.notConfigured),
      );

      expect(callCount, 0);
    });
  });

  group('BackendConfiguration', () {
    test('needs a real web address', () {
      expect(const BackendConfiguration.disabled().isConfigured, isFalse);
      expect(
        const BackendConfiguration(baseUrl: 'not an address', accessToken: '').isConfigured,
        isFalse,
      );
      expect(
        const BackendConfiguration(baseUrl: 'ftp://server', accessToken: '').isConfigured,
        isFalse,
      );
      expect(
        const BackendConfiguration(baseUrl: 'https://api.example.org', accessToken: '').isConfigured,
        isTrue,
      );
    });
  });
}
