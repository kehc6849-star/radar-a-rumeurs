import 'package:flutter/material.dart';

import '../../domain/models/analysis_verdict.dart';
import '../../domain/models/verdict_level.dart';
import 'verdict_level_presentation.dart';

/// Top card of the result screen: level, icon and risk bar.
class VerdictHeaderCard extends StatelessWidget {
  const VerdictHeaderCard({super.key, required this.verdict});

  final AnalysisVerdict verdict;

  @override
  Widget build(BuildContext context) {
    final VerdictLevelStyle levelStyle = verdict.level.style;

    // Weak signals exist but are below the warning threshold:
    // saying "no signal" would contradict the list shown below.
    final bool hasOnlyWeakSignals =
        verdict.level == VerdictLevel.noSignalFound && verdict.signals.isNotEmpty;
    final String levelLabel =
        hasOnlyWeakSignals ? 'Peu de signaux détectés' : levelStyle.label;

    return Card(
      color: levelStyle.color.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: <Widget>[
            Icon(levelStyle.icon, size: 56, color: levelStyle.color),
            const SizedBox(height: 12),
            Text(
              levelLabel,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: levelStyle.color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: verdict.riskScore / 100,
                minHeight: 10,
                color: levelStyle.color,
                backgroundColor: levelStyle.color.withValues(alpha: 0.2),
              ),
            ),
            const SizedBox(height: 8),
            Text('Niveau de risque estimé : ${verdict.riskScore}/100'),
          ],
        ),
      ),
    );
  }
}
