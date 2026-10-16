import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
import '../features/analysis/domain/services/shared_content_receiver.dart';
import '../features/analysis/presentation/controllers/analysis_controller.dart';
import '../features/analysis/presentation/screens/home_screen.dart';

class RadarApplication extends StatefulWidget {
  const RadarApplication({
    super.key,
    this.backendConfiguration = const BackendConfiguration.disabled(),
    this.screenshotPicker,
    this.sharedContentReceiver,
  });

  final BackendConfiguration backendConfiguration;
  final ScreenshotPicker? screenshotPicker;

  /// Receives texts and images shared from other apps. Optional: without it,
  /// shared content is ignored (this is the case in most tests).
  final SharedContentReceiver? sharedContentReceiver;

  @override
  State<RadarApplication> createState() => _RadarApplicationState();
}

class _RadarApplicationState extends State<RadarApplication> {
  static const String _darkModePreferenceKey = 'dark_mode';

  late final RemoteAnalysisClient _remoteAnalysisClient;
  late final AiConsentRepository _consentRepository;
  late final AnalysisHistoryRepository _historyRepository;
  late final ScreenshotPicker _screenshotPicker;
  late final AnalysisController _analysisController;

  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();

    // Local analysis: works without internet.
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

    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    try {
      final SharedPreferences preferences =
      await SharedPreferences.getInstance();
      final bool savedDarkMode =
          preferences.getBool(_darkModePreferenceKey) ?? false;

      if (!mounted) {
        return;
      }

      setState(() {
        _isDarkMode = savedDarkMode;
      });
    } catch (error) {
      debugPrint('Could not load the saved theme: $error');
    }
  }

  Future<void> _toggleTheme(bool isDark) async {
    setState(() {
      _isDarkMode = isDark;
    });

    try {
      final SharedPreferences preferences =
      await SharedPreferences.getInstance();

      await preferences.setBool(_darkModePreferenceKey, isDark);
    } catch (error) {
      debugPrint('Could not save the theme: $error');
    }
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
      darkTheme: ApplicationTheme.buildDarkTheme(),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: HomeScreen(
        analysisController: _analysisController,
        consentRepository: _consentRepository,
        historyRepository: _historyRepository,
        screenshotPicker: _screenshotPicker,
        sharedContentReceiver: widget.sharedContentReceiver,
        isAiAvailable: _remoteAnalysisClient.isConfigured,
        isDarkMode: _isDarkMode,
        onThemeChanged: _toggleTheme,
      ),
    );
  }
}