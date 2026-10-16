import 'package:flutter/material.dart';

import '../../domain/models/analysis_source.dart';
import '../../domain/models/analysis_verdict.dart';
import '../../domain/models/detected_signal.dart';
import '../widgets/detected_signal_tile.dart';
import '../widgets/recommended_actions_card.dart';
import '../widgets/verdict_header_card.dart';

/// Écran de résultat : verdict, signaux détectés et conseils.
class VerdictScreen extends StatelessWidget {
  const VerdictScreen({
    super.key,
    required this.verdict,
  });

  final AnalysisVerdict verdict;

  static const String _disclaimer =
      'Cette analyse est une estimation automatique, pas une preuve. '
      'En cas de doute, vérifiez toujours auprès de la source officielle.';

  static const Color _navy = Color(0xFF102344);
  static const Color _blue = Color(0xFF246BFD);
  static const Color _background = Color(0xFFF4F7FC);
  static const Color _muted = Color(0xFF718096);

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
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          tooltip: 'Retour',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: _navy,
            size: 20,
          ),
        ),
        title: const Text(
          'Résultat de l’analyse',
          style: TextStyle(
            color: _navy,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
          children: [
            // En-tête du verdict existant
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: _navy.withValues(alpha: 0.04),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: VerdictHeaderCard(verdict: verdict),
            ),

            const SizedBox(height: 14),

            // Origine de l'analyse
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF1FF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFD8E5FF),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: _blue,
                    size: 19,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _buildSourceLabel(),
                      style: const TextStyle(
                        color: _navy,
                        fontSize: 12,
                        height: 1.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Avertissement éventuel
            if (notice != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF6E5),
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(
                    color: const Color(0xFFFFE4B2),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.cloud_off_outlined,
                      color: Color(0xFF9A6200),
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        notice,
                        style: const TextStyle(
                          color: Color(0xFF765018),
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 25),

            // Résumé
            _SectionTitle(
              icon: Icons.subject_rounded,
              title: 'Comprendre le résultat',
            ),
            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFE5EAF3),
                ),
              ),
              child: Text(
                verdict.summary,
                style: textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF34445D),
                  fontSize: 14,
                  height: 1.75,
                ),
              ),
            ),

            // Signaux repérés
            if (verdict.signals.isNotEmpty) ...[
              const SizedBox(height: 27),
              _SectionTitle(
                icon: Icons.manage_search_rounded,
                title: 'Signaux repérés',
                count: verdict.signals.length,
              ),
              const SizedBox(height: 12),
              ...verdict.signals.map(
                    (DetectedSignal signal) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(
                        color: const Color(0xFFE5EAF3),
                      ),
                    ),
                    child: DetectedSignalTile(signal: signal),
                  ),
                ),
              ),
            ],

            // Conseils
            if (verdict.recommendedActions.isNotEmpty) ...[
              const SizedBox(height: 17),
              _SectionTitle(
                icon: Icons.lightbulb_outline_rounded,
                title: 'Que faire maintenant ?',
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(21),
                  border: Border.all(
                    color: const Color(0xFFE5EAF3),
                  ),
                ),
                child: RecommendedActionsCard(
                  actions: verdict.recommendedActions,
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Limites de l'analyse
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF4FF),
                borderRadius: BorderRadius.circular(17),
                border: Border.all(
                  color: const Color(0xFFD9E9FF),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.verified_user_outlined,
                    color: Color(0xFF2864B8),
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Gardez votre esprit critique',
                          style: TextStyle(
                            color: _navy,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          _disclaimer,
                          style: const TextStyle(
                            color: Color(0xFF34557E),
                            fontSize: 12,
                            height: 1.65,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 23),

            // Retour à l'écran d'accueil
            SizedBox(
              height: 54,
              child: FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.add_rounded, size: 22),
                label: const Text(
                  'Analyser un autre message',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: _blue,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shadowColor: _blue.withValues(alpha: 0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            Center(
              child: Text(
                'RADAR À RUMEURS • VÉRIFIER AVANT DE PARTAGER',
                textAlign: TextAlign.center,
                style: textTheme.labelSmall?.copyWith(
                  color: _muted,
                  fontSize: 9,
                  letterSpacing: 0.7,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.title,
    this.count,
  });

  final IconData icon;
  final String title;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFE5EDFF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF246BFD),
            size: 21,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF102344),
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
        ),
        if (count != null)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFE5EDFF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Color(0xFF246BFD),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    );
  }
}