import 'package:flutter_test/flutter_test.dart';
import 'package:radar_a_rumeurs/features/analysis/domain/models/analysis_verdict.dart';
import 'package:radar_a_rumeurs/features/analysis/domain/models/detected_signal.dart';
import 'package:radar_a_rumeurs/features/analysis/domain/models/threat_family.dart';
import 'package:radar_a_rumeurs/features/analysis/domain/models/verdict_level.dart';
import 'package:radar_a_rumeurs/features/analysis/domain/rules/scam_rule_catalog.dart';
import 'package:radar_a_rumeurs/features/analysis/domain/services/content_validation_exception.dart';
import 'package:radar_a_rumeurs/features/analysis/domain/services/content_validator.dart';
import 'package:radar_a_rumeurs/features/analysis/domain/services/rule_based_content_analyzer.dart';
import 'package:radar_a_rumeurs/features/analysis/domain/services/text_normalizer.dart';

RuleBasedContentAnalyzer buildAnalyzer() {
  return RuleBasedContentAnalyzer(rules: ScamRuleCatalog.buildDefaultRules());
}

bool containsRule(AnalysisVerdict verdict, String ruleIdentifierPrefix) {
  return verdict.signals.any(
    (DetectedSignal signal) => signal.ruleIdentifier.startsWith(ruleIdentifierPrefix),
  );
}

void main() {
  group('RuleBasedContentAnalyzer', () {
    test('flags a fake customer service asking for a confirmation code', () async {
      final AnalysisVerdict verdict = await buildAnalyzer().analyzeContent(
        'Bonjour, ici le service client Wave. Veuillez nous communiquer le code '
        'de confirmation reçu par SMS pour sécuriser votre compte.',
      );

      expect(verdict.level, VerdictLevel.dangerous);
      expect(containsRule(verdict, 'one_time_code_request'), isTrue);
      expect(containsRule(verdict, 'provider_impersonation'), isTrue);
    });

    test('flags a fake scholarship that asks for fees', () async {
      final AnalysisVerdict verdict = await buildAnalyzer().analyzeContent(
        "Félicitations ! Vous êtes sélectionné pour une bourse d'études. "
        'Payez 15 000 FCFA de frais de dossier via Wave.',
      );

      expect(verdict.level, VerdictLevel.dangerous);
      expect(
        verdict.signals.any(
          (DetectedSignal signal) => signal.family == ThreatFamily.scholarshipScam,
        ),
        isTrue,
      );
    });

    test('flags the "transfer by mistake" scam', () async {
      final AnalysisVerdict verdict = await buildAnalyzer().analyzeContent(
        'Bonjour, je vous ai envoyé 25 000 FCFA par erreur, merci de me les renvoyer.',
      );

      expect(verdict.level, VerdictLevel.dangerous);
      expect(containsRule(verdict, 'mistaken_transfer_claim'), isTrue);
    });

    test('flags a link that imitates a known service', () async {
      final AnalysisVerdict verdict = await buildAnalyzer().analyzeContent(
        'Cliquez sur http://wave-secure-sn.com/gagnant pour récupérer votre cadeau',
      );

      expect(verdict.level, isNot(VerdictLevel.noSignalFound));
      expect(containsRule(verdict, 'suspicious_link_brand_imitation'), isTrue);
    });

    test('flags a chain message pressure', () async {
      final AnalysisVerdict verdict = await buildAnalyzer().analyzeContent(
        'Info urgente ! Partagez ce message à tous vos contacts avant qu’ils ne le suppriment.',
      );

      expect(verdict.level, isNot(VerdictLevel.noSignalFound));
      expect(containsRule(verdict, 'chain_message_pressure'), isTrue);
    });

    test('flags a relative who "changed number" and asks for money', () async {
      final AnalysisVerdict verdict = await buildAnalyzer().analyzeContent(
        "Maman c'est moi, j'ai changé de numéro. Envoie moi 50000 FCFA svp c'est urgent",
      );

      expect(verdict.level, VerdictLevel.dangerous);
      expect(containsRule(verdict, 'relative_number_change'), isTrue);
    });

    test('flags a fake account verification link message', () async {
      final AnalysisVerdict verdict = await buildAnalyzer().analyzeContent(
        'Cher client, votre compte Orange Money sera bloqué. '
        'Cliquez sur ce lien pour vérifier votre compte.',
      );

      expect(verdict.level, VerdictLevel.dangerous);
      expect(containsRule(verdict, 'account_verification_link'), isTrue);
    });

    test('flags a guaranteed investment promise', () async {
      final AnalysisVerdict verdict = await buildAnalyzer().analyzeContent(
        'Doublez votre argent en 24h, gains garantis, investissez maintenant avec 10000 FCFA',
      );

      expect(verdict.level, VerdictLevel.dangerous);
      expect(containsRule(verdict, 'guaranteed_investment_promise'), isTrue);
    });

    test('flags English scam phrases', () async {
      final AnalysisVerdict verdict = await buildAnalyzer().analyzeContent(
        'Congratulations! You have won 1,000,000 FCFA. Click here to claim your prize',
      );

      expect(verdict.level, VerdictLevel.dangerous);
      expect(containsRule(verdict, 'english_scam_phrases'), isTrue);
    });

    test('does not flag a harmless "new number" message from a relative', () async {
      final AnalysisVerdict verdict = await buildAnalyzer().analyzeContent(
        "Maman, j'ai changé de numéro, voici le nouveau. Appelle-moi quand tu veux",
      );

      expect(verdict.level, VerdictLevel.noSignalFound);
    });

    test('finds no signal in a normal message', () async {
      final AnalysisVerdict verdict = await buildAnalyzer().analyzeContent(
        'Salut, on se retrouve demain à 18h devant le restaurant ?',
      );

      expect(verdict.level, VerdictLevel.noSignalFound);
      expect(verdict.riskScore, 0);
      expect(verdict.signals, isEmpty);
    });

    test('rejects a blank message', () async {
      await expectLater(
        buildAnalyzer().analyzeContent('   '),
        throwsA(isA<ContentValidationException>()),
      );
    });

    test('rejects a message that is too long', () async {
      final String tooLongContent = 'a' * (ContentValidator.maximumContentLength + 1);

      await expectLater(
        buildAnalyzer().analyzeContent(tooLongContent),
        throwsA(isA<ContentValidationException>()),
      );
    });
  });

  group('TextNormalizer', () {
    test('removes accents, capital letters and extra spaces', () {
      final String matchingText =
          const TextNormalizer().normalize('  FÉLICITATIONS   été  ').matchingText;

      expect(matchingText, 'felicitations ete');
    });
  });
}
