import '../models/ai_consent_status.dart';
import '../models/analysis_verdict.dart';
import '../models/remote_analysis_result.dart';
import '../models/screenshot_input.dart';
import '../models/verdict_level.dart';
import '../repositories/ai_consent_repository.dart';
import 'analysis_unavailable_exception.dart';
import 'content_analyzer.dart';
import 'content_validation_exception.dart';
import 'content_validator.dart';
import 'remote_analysis_gateway.dart';
import 'screenshot_analyzer.dart';
import 'verdict_fusion_policy.dart';
import 'verdict_summary_catalog.dart';

/// Screenshot analysis: the AI reads the image, then the local rules
/// check the text that was read, and both results are combined.
class ScreenshotVerdictAnalyzer implements ScreenshotAnalyzer {
  ScreenshotVerdictAnalyzer({
    required this.localAnalyzer,
    required this.remoteGateway,
    required this.consentRepository,
    this.fusionPolicy = const VerdictFusionPolicy(),
  });

  final ContentAnalyzer localAnalyzer;
  final RemoteAnalysisGateway remoteGateway;
  final AiConsentRepository consentRepository;
  final VerdictFusionPolicy fusionPolicy;

  @override
  Future<AnalysisVerdict> analyzeScreenshot(ScreenshotInput screenshot) async {
    if (screenshot.imageBytes.isEmpty) {
      throw const ContentValidationException('Image vide ou illisible.');
    }

    if (screenshot.imageBytes.length > ScreenshotInput.maximumImageBytes) {
      throw const ContentValidationException(
        'Image trop volumineuse. Choisissez une image plus légère.',
      );
    }

    if (!remoteGateway.isConfigured) {
      throw const AnalysisUnavailableException(
        "L'analyse de captures d'écran n'est pas disponible dans cette version de l'application.",
      );
    }

    final AiConsentStatus consentStatus = await consentRepository.loadStatus();

    if (consentStatus != AiConsentStatus.granted) {
      throw const AnalysisUnavailableException(
        "Autorisez l'analyse par IA (icône bouclier) pour analyser une capture d'écran.",
      );
    }

    final RemoteAnalysisResult remoteResult;

    try {
      remoteResult = await remoteGateway.analyzeScreenshot(screenshot);
    } on RemoteAnalysisException catch (remoteError) {
      throw AnalysisUnavailableException(_buildFailureMessage(remoteError.kind));
    }

    final AnalysisVerdict localVerdict =
        await _analyzeExtractedText(remoteResult.extractedText);

    return fusionPolicy.merge(
      localVerdict: localVerdict,
      remoteResult: remoteResult,
    );
  }

  Future<AnalysisVerdict> _analyzeExtractedText(String? extractedText) async {
    final String cleanedText = (extractedText ?? '').trim();

    if (cleanedText.isEmpty) {
      return _buildEmptyVerdict();
    }

    final String boundedText =
        cleanedText.length > ContentValidator.maximumContentLength
            ? cleanedText.substring(0, ContentValidator.maximumContentLength)
            : cleanedText;

    return localAnalyzer.analyzeContent(boundedText);
  }

  // Used when the image contains no readable text: only the AI result remains.
  AnalysisVerdict _buildEmptyVerdict() {
    return AnalysisVerdict(
      level: VerdictLevel.noSignalFound,
      riskScore: 0,
      signals: const [],
      summary: VerdictSummaryCatalog.buildSummary(VerdictLevel.noSignalFound),
      recommendedActions: const [],
      analyzedAt: DateTime.now(),
    );
  }

  String _buildFailureMessage(RemoteAnalysisFailureKind failureKind) {
    return switch (failureKind) {
      RemoteAnalysisFailureKind.rateLimited =>
        "L'analyse IA est très sollicitée en ce moment. Réessayez dans une minute.",
      RemoteAnalysisFailureKind.network =>
        "Impossible de joindre le serveur d'analyse. Vérifiez votre connexion.",
      RemoteAnalysisFailureKind.notConfigured ||
      RemoteAnalysisFailureKind.serverError ||
      RemoteAnalysisFailureKind.invalidResponse =>
        "Le serveur d'analyse est indisponible pour le moment. Réessayez plus tard.",
    };
  }
}
