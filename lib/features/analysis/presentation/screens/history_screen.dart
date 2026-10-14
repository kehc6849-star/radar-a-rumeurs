import 'package:flutter/material.dart';

import '../../domain/models/analysis_history_entry.dart';
import '../../domain/models/analysis_input_kind.dart';
import '../../domain/repositories/analysis_history_repository.dart';
import '../widgets/verdict_level_presentation.dart';

/// Shows the past results. The analyzed content itself is never kept.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, required this.historyRepository});

  final AnalysisHistoryRepository historyRepository;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<AnalysisHistoryEntry>> _entriesFuture;

  @override
  void initState() {
    super.initState();
    _entriesFuture = widget.historyRepository.loadEntries();
  }

  Future<void> _clearHistory() async {
    await widget.historyRepository.clearEntries();

    if (!mounted) {
      return;
    }

    setState(() {
      _entriesFuture = widget.historyRepository.loadEntries();
    });
  }

  String _formatDate(DateTime date) {
    final DateTime localDate = date.toLocal();

    String twoDigits(int number) => number.toString().padLeft(2, '0');

    return '${twoDigits(localDate.day)}/${twoDigits(localDate.month)}/${localDate.year} '
        '${twoDigits(localDate.hour)}:${twoDigits(localDate.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique'),
        actions: <Widget>[
          IconButton(
            tooltip: "Effacer l'historique",
            icon: const Icon(Icons.delete_outline),
            onPressed: _clearHistory,
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<List<AnalysisHistoryEntry>>(
          future: _entriesFuture,
          builder: (
            BuildContext builderContext,
            AsyncSnapshot<List<AnalysisHistoryEntry>> snapshot,
          ) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            final List<AnalysisHistoryEntry> entries =
                snapshot.data ?? const <AnalysisHistoryEntry>[];

            if (entries.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    "Aucune analyse pour l'instant. Seuls les résultats sont gardés, jamais vos messages.",
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            return ListView.separated(
              itemCount: entries.length,
              separatorBuilder: (BuildContext separatorContext, int position) =>
                  const Divider(height: 1),
              itemBuilder: (BuildContext itemContext, int position) {
                final AnalysisHistoryEntry entry = entries[position];
                final VerdictLevelStyle levelStyle = entry.level.style;
                final String kindLabel =
                    entry.inputKind == AnalysisInputKind.screenshot
                        ? "Capture d'écran"
                        : 'Texte';

                return ListTile(
                  leading: Icon(levelStyle.icon, color: levelStyle.color),
                  title: Text(levelStyle.label),
                  subtitle: Text(
                    '${_formatDate(entry.analyzedAt)} • $kindLabel • risque ${entry.riskScore}/100',
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
