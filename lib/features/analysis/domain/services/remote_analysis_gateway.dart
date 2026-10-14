import '../models/remote_analysis_result.dart';
import '../models/screenshot_input.dart';

enum RemoteAnalysisFailureKind {
  notConfigured,
  network,
  rateLimited,
  serverError,
  invalidResponse,
}

class RemoteAnalysisException implements Exception {
  const RemoteAnalysisException(this.kind, this.message);

  final RemoteAnalysisFailureKind kind;

  /// Technical text for developers. It never contains the user content.
  final String message;
}

/// Contract for the analysis server.
abstract interface class RemoteAnalysisGateway {
  bool get isConfigured;

  Future<RemoteAnalysisResult> analyzeText(String text);

  Future<RemoteAnalysisResult> analyzeScreenshot(ScreenshotInput screenshot);
}
