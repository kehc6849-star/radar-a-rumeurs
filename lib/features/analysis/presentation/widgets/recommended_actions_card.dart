import 'package:flutter/material.dart';

/// Lists what the user should do now, in simple steps.
class RecommendedActionsCard extends StatelessWidget {
  const RecommendedActionsCard({super.key, required this.actions});

  final List<String> actions;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Que faire maintenant ?',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            for (final String action in actions)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Icon(Icons.check_circle_outline, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(action)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
