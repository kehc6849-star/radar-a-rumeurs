import 'package:flutter/material.dart';

import '../core/theme/application_theme.dart';
import '../features/analysis/domain/rules/scam_rule_catalog.dart';
import '../features/analysis/domain/services/rule_based_content_analyzer.dart';
import '../features/analysis/presentation/controllers/analysis_controller.dart';
import '../features/analysis/presentation/screens/home_screen.dart';

/// Root widget. It builds the dependencies once and gives them to the screens.
class RadarApplication extends StatefulWidget {
  const RadarApplication({super.key});

  @override
  State<RadarApplication> createState() => _RadarApplicationState();
}

class _RadarApplicationState extends State<RadarApplication> {
  late final AnalysisController _analysisController;

  @override
  void initState() {
    super.initState();

    _analysisController = AnalysisController(
      contentAnalyzer: RuleBasedContentAnalyzer(
        rules: ScamRuleCatalog.buildDefaultRules(),
      ),
    );
  }

  @override
  void dispose() {
    _analysisController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Radar à Rumeurs',
      debugShowCheckedModeBanner: false,
      theme: ApplicationTheme.buildLightTheme(),
      home: HomeScreen(analysisController: _analysisController),
    );
  }
}
