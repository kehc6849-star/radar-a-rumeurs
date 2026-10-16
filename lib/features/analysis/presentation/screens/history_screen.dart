import 'package:flutter/material.dart';

import '../../domain/models/analysis_history_entry.dart';
import '../../domain/models/analysis_input_kind.dart';
import '../../domain/repositories/analysis_history_repository.dart';
import '../widgets/verdict_level_presentation.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({
    super.key,
    required this.historyRepository,
  });

  final AnalysisHistoryRepository historyRepository;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<AnalysisHistoryEntry>> _entriesFuture;

  static const Color _primary = Color(0xFF2457D6);
  static const Color _background = Color(0xFFF5F7FC);
  static const Color _dark = Color(0xFF17233C);
  static const Color _muted = Color(0xFF7B879C);

  @override
  void initState() {
    super.initState();
    _entriesFuture = widget.historyRepository.loadEntries();
  }

  Future<void> _refreshHistory() async {
    setState(() {
      _entriesFuture = widget.historyRepository.loadEntries();
    });

    await _entriesFuture;
  }

  Future<void> _clearHistory() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          icon: const Icon(
            Icons.delete_outline_rounded,
            color: Colors.redAccent,
            size: 36,
          ),
          title: const Text(
            'Effacer l’historique ?',
            textAlign: TextAlign.center,
          ),
          content: const Text(
            'Tous les résultats enregistrés seront supprimés. '
                'Cette action ne peut pas être annulée.',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Effacer'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await widget.historyRepository.clearEntries();

    if (!mounted) return;

    setState(() {
      _entriesFuture = widget.historyRepository.loadEntries();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Historique supprimé avec succès.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final DateTime localDate = date.toLocal();

    String twoDigits(int number) => number.toString().padLeft(2, '0');

    return '${twoDigits(localDate.day)}/'
        '${twoDigits(localDate.month)}/'
        '${localDate.year} à '
        '${twoDigits(localDate.hour)}:'
        '${twoDigits(localDate.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Historique',
          style: TextStyle(
            color: _dark,
            fontSize: 25,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Effacer l’historique',
            onPressed: _clearHistory,
            icon: const Icon(
              Icons.delete_sweep_outlined,
              color: _dark,
              size: 25,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<List<AnalysisHistoryEntry>>(
          future: _entriesFuture,
          builder: (
              BuildContext context,
              AsyncSnapshot<List<AnalysisHistoryEntry>> snapshot,
              ) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(
                  color: _primary,
                ),
              );
            }

            if (snapshot.hasError) {
              return _buildErrorState();
            }

            final List<AnalysisHistoryEntry> entries =
                snapshot.data ?? const <AnalysisHistoryEntry>[];

            if (entries.isEmpty) {
              return _buildEmptyState();
            }

            return RefreshIndicator(
              color: _primary,
              onRefresh: _refreshHistory,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                children: [
                  _buildSummaryCard(entries.length),
                  const SizedBox(height: 26),
                  const Text(
                    'Analyses récentes',
                    style: TextStyle(
                      color: _dark,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Retrouve ici les résultats de tes précédentes analyses.',
                    style: TextStyle(
                      color: _muted,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 18),
                  ...entries.map(
                        (AnalysisHistoryEntry entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _buildHistoryCard(entry),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildPrivacyNote(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCard(int count) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF2457D6),
            Color(0xFF4779EF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.18),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.17),
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons.history_rounded,
              color: Colors.white,
              size: 29,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tes analyses',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '$count ${count > 1 ? 'résultats enregistrés' : 'résultat enregistré'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(AnalysisHistoryEntry entry) {
    final VerdictLevelStyle style = entry.level.style;

    final String kindLabel =
    entry.inputKind == AnalysisInputKind.screenshot
        ? 'Capture d’écran'
        : 'Texte';

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: const Color(0xFFE9EDF5),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF17233C).withOpacity(0.035),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 49,
            height: 49,
            decoration: BoxDecoration(
              color: style.color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              style.icon,
              color: style.color,
              size: 25,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  style.label,
                  style: const TextStyle(
                    color: _dark,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      color: _muted,
                      size: 14,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        _formatDate(entry.analyzedAt),
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    _buildTag(
                      icon: entry.inputKind == AnalysisInputKind.screenshot
                          ? Icons.image_outlined
                          : Icons.text_fields_rounded,
                      label: kindLabel,
                    ),
                    _buildTag(
                      icon: Icons.shield_outlined,
                      label: 'Risque ${entry.riskScore}/100',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F5FB),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: _muted,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: _dark,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFE8EEFF),
                borderRadius: BorderRadius.circular(32),
              ),
              child: const Icon(
                Icons.history_rounded,
                size: 48,
                color: _primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Aucune analyse pour le moment',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _dark,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Les résultats de tes analyses apparaîtront ici. '
                  'Le contenu de tes messages n’est pas conservé.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _muted,
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 52,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 16),
            const Text(
              'Impossible de charger l’historique',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _dark,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Vérifie le stockage local puis réessaie.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _muted,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _refreshHistory,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyNote() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF0FF),
        borderRadius: BorderRadius.circular(17),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lock_outline_rounded,
            color: _primary,
            size: 21,
          ),
          SizedBox(width: 11),
          Expanded(
            child: Text(
              'Confidentialité : seuls les résultats sont conservés, '
                  'pas le contenu des messages analysés.',
              style: TextStyle(
                color: _dark,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}