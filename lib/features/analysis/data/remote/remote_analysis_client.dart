import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../../../core/configuration/backend_configuration.dart';
import '../../domain/models/remote_analysis_result.dart';
import '../../domain/models/screenshot_input.dart';
import '../../domain/models/threat_family.dart';
import '../../domain/services/remote_analysis_gateway.dart';

/// Talks to the analysis server over HTTP.
///
/// It never logs anything: requests and answers can contain private messages.
class RemoteAnalysisClient implements RemoteAnalysisGateway {
  RemoteAnalysisClient({
    required this.configuration,
    http.Client? httpClient,
    this.requestTimeout = const Duration(seconds: 40),
  }) : _httpClient = httpClient ?? http.Client();

  static const String _accessTokenHeaderName = 'X-Radar-Access-Token';
  static const int _maximumSignalCount = 8;
  static const int _maximumActionCount = 6;

  final BackendConfiguration configuration;
  final Duration requestTimeout;
  final http.Client _httpClient;

  @override
  bool get isConfigured => configuration.isConfigured;

  @override
  Future<RemoteAnalysisResult> analyzeText(String text) async {
    final Uri requestAddress = _buildAddress('/v1/analyze');

    final http.Response response = await _send(() {
      return _httpClient
          .post(
            requestAddress,
            headers: _buildHeaders(<String, String>{
              'Content-Type': 'application/json; charset=utf-8',
            }),
            body: jsonEncode(<String, String>{'text': text}),
          )
          .timeout(requestTimeout);
    });

    return _parseResponse(response);
  }

  @override
  Future<RemoteAnalysisResult> analyzeScreenshot(
    ScreenshotInput screenshot,
  ) async {
    final Uri requestAddress = _buildAddress('/v1/analyze-image');

    final http.Response response = await _send(() async {
      final http.MultipartRequest request =
          http.MultipartRequest('POST', requestAddress)
            ..headers.addAll(_buildHeaders(const <String, String>{}))
            ..files.add(
              http.MultipartFile.fromBytes(
                'image',
                screenshot.imageBytes,
                filename: 'screenshot',
              ),
            );

      final http.StreamedResponse streamedResponse =
          await _httpClient.send(request).timeout(requestTimeout);

      return http.Response.fromStream(streamedResponse);
    });

    return _parseResponse(response);
  }

  void close() {
    _httpClient.close();
  }

  Uri _buildAddress(String path) {
    final String cleanedBaseUrl =
        configuration.baseUrl.trim().replaceAll(RegExp(r'/+$'), '');

    return Uri.parse('$cleanedBaseUrl$path');
  }

  Map<String, String> _buildHeaders(Map<String, String> baseHeaders) {
    final Map<String, String> headers = Map<String, String>.of(baseHeaders);

    if (configuration.accessToken.trim().isNotEmpty) {
      headers[_accessTokenHeaderName] = configuration.accessToken.trim();
    }

    return headers;
  }

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    if (!configuration.isConfigured) {
      throw const RemoteAnalysisException(
        RemoteAnalysisFailureKind.notConfigured,
        'No server address is configured.',
      );
    }

    try {
      return await request();
    } on TimeoutException {
      throw const RemoteAnalysisException(
        RemoteAnalysisFailureKind.network,
        'The server did not answer in time.',
      );
    } on SocketException {
      throw const RemoteAnalysisException(
        RemoteAnalysisFailureKind.network,
        'The server cannot be reached.',
      );
    } on http.ClientException {
      throw const RemoteAnalysisException(
        RemoteAnalysisFailureKind.network,
        'The network request failed.',
      );
    }
  }

  RemoteAnalysisResult _parseResponse(http.Response response) {
    final int statusCode = response.statusCode;

    if (statusCode == 429) {
      throw const RemoteAnalysisException(
        RemoteAnalysisFailureKind.rateLimited,
        'The server asked to slow down.',
      );
    }

    if (statusCode >= 500 || statusCode == 401 || statusCode == 403) {
      throw RemoteAnalysisException(
        RemoteAnalysisFailureKind.serverError,
        'The server answered with status $statusCode.',
      );
    }

    if (statusCode != 200) {
      throw RemoteAnalysisException(
        RemoteAnalysisFailureKind.invalidResponse,
        'The server refused the request (status $statusCode).',
      );
    }

    return _parseSuccessBody(response.bodyBytes);
  }

  RemoteAnalysisResult _parseSuccessBody(Uint8List bodyBytes) {
    final Object? decodedBody;

    try {
      // The body is decoded as UTF-8 on purpose: accents must stay correct.
      decodedBody = jsonDecode(utf8.decode(bodyBytes));
    } on FormatException {
      throw const RemoteAnalysisException(
        RemoteAnalysisFailureKind.invalidResponse,
        'The server answer is not valid JSON.',
      );
    }

    if (decodedBody is! Map<String, Object?>) {
      throw const RemoteAnalysisException(
        RemoteAnalysisFailureKind.invalidResponse,
        'The server answer has an unexpected shape.',
      );
    }

    final Object? rawRiskScore = decodedBody['riskScore'];

    if (rawRiskScore is! num) {
      throw const RemoteAnalysisException(
        RemoteAnalysisFailureKind.invalidResponse,
        'The server answer has no risk score.',
      );
    }

    final Object? rawModelName = decodedBody['modelName'];
    final Object? rawExtractedText = decodedBody['extractedText'];

    return RemoteAnalysisResult(
      riskScore: _clampRiskScore(rawRiskScore.round()),
      threatFamily: _parseThreatFamily(decodedBody['threatFamily']),
      signals: _parseSignals(decodedBody['signals']),
      recommendedActions: _parseActions(decodedBody['recommendedActions']),
      modelName: rawModelName is String && rawModelName.trim().isNotEmpty
          ? rawModelName.trim()
          : 'IA',
      extractedText: rawExtractedText is String ? rawExtractedText : null,
    );
  }

  int _clampRiskScore(int riskScore) {
    if (riskScore < 0) {
      return 0;
    }

    if (riskScore > 100) {
      return 100;
    }

    return riskScore;
  }

  ThreatFamily? _parseThreatFamily(Object? rawFamily) {
    if (rawFamily is! String) {
      return null;
    }

    for (final ThreatFamily family in ThreatFamily.values) {
      if (family.name == rawFamily) {
        return family;
      }
    }

    return null;
  }

  List<RemoteSignal> _parseSignals(Object? rawSignals) {
    if (rawSignals is! List<Object?>) {
      return const <RemoteSignal>[];
    }

    final List<RemoteSignal> signals = <RemoteSignal>[];

    for (final Object? rawSignal in rawSignals) {
      if (signals.length >= _maximumSignalCount) {
        break;
      }

      if (rawSignal is! Map<String, Object?>) {
        continue;
      }

      final Object? title = rawSignal['title'];
      final Object? explanation = rawSignal['explanation'];

      if (title is String &&
          explanation is String &&
          title.trim().isNotEmpty &&
          explanation.trim().isNotEmpty) {
        signals.add(
          RemoteSignal(title: title.trim(), explanation: explanation.trim()),
        );
      }
    }

    return signals;
  }

  List<String> _parseActions(Object? rawActions) {
    if (rawActions is! List<Object?>) {
      return const <String>[];
    }

    final List<String> actions = <String>[];

    for (final Object? rawAction in rawActions) {
      if (actions.length >= _maximumActionCount) {
        break;
      }

      if (rawAction is String && rawAction.trim().isNotEmpty) {
        actions.add(rawAction.trim());
      }
    }

    return actions;
  }
}
