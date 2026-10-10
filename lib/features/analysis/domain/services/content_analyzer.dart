import '../models/analysis_verdict.dart';

/// Contract for any analysis engine.
///
/// The screens only know this interface. Today a local rule engine
/// implements it; an AI-powered engine will be added behind the same contract.
abstract interface class ContentAnalyzer {
  Future<AnalysisVerdict> analyzeContent(String rawContent);
}
