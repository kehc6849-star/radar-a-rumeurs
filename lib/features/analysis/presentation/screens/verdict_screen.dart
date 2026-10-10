import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Résultat de l'analyse")),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            VerdictHeaderCard(verdict: verdict),
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
