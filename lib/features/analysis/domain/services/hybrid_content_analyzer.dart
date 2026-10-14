import '../models/ai_consent_status.dart';
import '../models/analysis_verdict.dart';
import '../models/remote_analysis_result.dart';
import '../repositories/ai_consent_repository.dart';
import 'content_analyzer.dart';
import 'remote_analysis_gateway.dart';
import 'verdict_fusion_policy.dart';

/// Text analysis: local rules first, AI as a complement.
///
/// If the AI is not available for any reason, the user still gets
/// the local verdict. The application never stops working offline.
class HybridContentAnalyzer implements ContentAnalyzer {
  HybridContentAnalyzer({
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
  Future<AnalysisVerdict> analyzeContent(String rawContent) async {
    // The local analyzer validates the input: bad input stops here, before any network call.
    final AnalysisVerdict localVerdict =
        await localAnalyzer.analyzeContent(rawContent);

    if (!remoteGateway.isConfigured) {
      return localVerdict;
    }

    final AiConsentStatus consentStatus = await consentRepository.loadStatus();

    if (consentStatus != AiConsentStatus.granted) {
      return localVerdict;
    }

    try {
      final RemoteAnalysisResult remoteResult =
          await remoteGateway.analyzeText(rawContent.trim());

      return fusionPolicy.merge(
        localVerdict: localVerdict,
        remoteResult: remoteResult,
      );
    } on RemoteAnalysisException catch (remoteError) {
      return localVerdict.withNotice(_buildNotice(remoteError.kind));
    }
  }

  String _buildNotice(RemoteAnalysisFailureKind failureKind) {
    return switch (failureKind) {
      RemoteAnalysisFailureKind.rateLimited =>
        "L'analyse IA est très sollicitée en ce moment : ce résultat est basé sur les règles locales.",
      RemoteAnalysisFailureKind.notConfigured ||
      RemoteAnalysisFailureKind.network ||
      RemoteAnalysisFailureKind.serverError ||
      RemoteAnalysisFailureKind.invalidResponse =>
        "L'analyse IA est indisponible (connexion ou serveur) : ce résultat est basé sur les règles locales.",
    };
  }
}
