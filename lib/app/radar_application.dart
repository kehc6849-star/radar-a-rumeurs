import 'package:flutter/material.dart';

import '../core/configuration/backend_configuration.dart';
import '../core/theme/application_theme.dart';
import '../features/analysis/data/device/gallery_screenshot_picker.dart';
import '../features/analysis/data/local/shared_preferences_ai_consent_repository.dart';
import '../features/analysis/data/local/shared_preferences_history_repository.dart';
import '../features/analysis/data/remote/remote_analysis_client.dart';
import '../features/analysis/domain/repositories/ai_consent_repository.dart';
import '../features/analysis/domain/repositories/analysis_history_repository.dart';
import '../features/analysis/domain/rules/scam_rule_catalog.dart';
import '../features/analysis/domain/services/hybrid_content_analyzer.dart';
import '../features/analysis/domain/services/rule_based_content_analyzer.dart';
import '../features/analysis/domain/services/screenshot_picker.dart';
import '../features/analysis/domain/services/screenshot_verdict_analyzer.dart';
import '../features/analysis/presentation/controllers/analysis_controller.dart';
import '../features/analysis/presentation/screens/home_screen.dart';

/// Root widget. It builds the dependencies once and gives them to the screens.
class RadarApplication extends StatefulWidget {
  const RadarApplication({
    super.key,
    this.backendConfiguration = const BackendConfiguration.disabled(),
    this.screenshotPicker,
  });

  /// Without a configured server, the application works with local rules only.
  final BackendConfiguration backendConfiguration;

  /// Can be replaced in tests. The default one opens the phone gallery.
  final ScreenshotPicker? screenshotPicker;

  @override
  State<RadarApplication> createState() => _RadarApplicationState();
}

class _RadarApplicationState extends State<RadarApplication> {
  late final RemoteAnalysisClient _remoteAnalysisClient;
  late final AiConsentRepository _consentRepository;
  late final AnalysisHistoryRepository _historyRepository;
  late final ScreenshotPicker _screenshotPicker;
  late final AnalysisController _analysisController;

  @override
  void initState() {
    super.initState();

    final RuleBasedContentAnalyzer localAnalyzer = RuleBasedContentAnalyzer(
      rules: ScamRuleCatalog.buildDefaultRules(),
    );

    _remoteAnalysisClient = RemoteAnalysisClient(
      configuration: widget.backendConfiguration,
    );
    _consentRepository = SharedPreferencesAiConsentRepository();
    _historyRepository = SharedPreferencesHistoryRepository();
    _screenshotPicker = widget.screenshotPicker ?? GalleryScreenshotPicker();

    _analysisController = AnalysisController(
      contentAnalyzer: HybridContentAnalyzer(
        localAnalyzer: localAnalyzer,
        remoteGateway: _remoteAnalysisClient,
        consentRepository: _consentRepository,
      ),
      screenshotAnalyzer: ScreenshotVerdictAnalyzer(
        localAnalyzer: localAnalyzer,
        remoteGateway: _remoteAnalysisClient,
        consentRepository: _consentRepository,
      ),
      historyRepository: _historyRepository,
    );
  }

  @override
  void dispose() {
    _analysisController.dispose();
    _remoteAnalysisClient.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Radar à Rumeurs',
      debugShowCheckedModeBanner: false,
      theme: ApplicationTheme.buildLightTheme(),
      home: HomeScreen(
        analysisController: _analysisController,
        consentRepository: _consentRepository,
        historyRepository: _historyRepository,
        screenshotPicker: _screenshotPicker,
        isAiAvailable: _remoteAnalysisClient.isConfigured,
      ),
    );
  }
}
