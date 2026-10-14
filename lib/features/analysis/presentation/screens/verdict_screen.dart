import 'package:flutter/material.dart';

import '../../domain/models/analysis_source.dart';
import '../../domain/models/analysis_verdict.dart';
import '../../domain/models/detected_signal.dart';
import '../widgets/detected_signal_tile.dart';
import '../widgets/recommended_actions_card.dart';
import '../widgets/verdict_header_card.dart';

/// Result screen: verdict, detected signals and advice.
class VerdictScreen extends StatelessWidget {
  const VerdictScreen({super.key, required this.verdict});

  final AnalysisVerdict verdict;

  static const String _disclaimer =
      'Cette analyse est une estimation automatique, pas une preuve. '
      'En cas de doute, vérifiez toujours auprès de la source officielle.';

  String _buildSourceLabel() {
    if (verdict.source == AnalysisSource.hybrid) {
      return 'Analyse : règles locales + IA (${verdict.aiModelName ?? 'IA'})';
    }

    return 'Analyse : règles locales (sur votre téléphone)';
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String? notice = verdict.notice;

    return Scaffold(
      appBar: AppBar(title: const Text("Résultat de l'analyse")),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            VerdictHeaderCard(verdict: verdict),
            const SizedBox(height: 8),
            Text(_buildSourceLabel(), style: textTheme.bodySmall),
            if (notice != null) ...<Widget>[
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.cloud_off_outlined),
                  title: Text(notice),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text(verdict.summary, style: textTheme.bodyLarge),
            if (verdict.signals.isNotEmpty) ...<Widget>[
              const SizedBox(height: 24),
              Text('Signaux repérés', style: textTheme.titleMedium),
              const SizedBox(height: 8),
              for (final DetectedSignal signal in verdict.signals)
                DetectedSignalTile(signal: signal),
            ],
            if (verdict.recommendedActions.isNotEmpty) ...<Widget>[
              const SizedBox(height: 16),
              RecommendedActionsCard(actions: verdict.recommendedActions),
            ],
            const SizedBox(height: 24),
            Text(_disclaimer, style: textTheme.bodySmall),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Analyser un autre message'),
            ),
          ],
        ),
      ),
    );
  }
}
