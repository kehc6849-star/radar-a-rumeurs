import '../models/analysis_verdict.dart';
import '../models/screenshot_input.dart';

/// Contract for any engine that can analyze a screenshot.
abstract interface class ScreenshotAnalyzer {
  Future<AnalysisVerdict> analyzeScreenshot(ScreenshotInput screenshot);
}
