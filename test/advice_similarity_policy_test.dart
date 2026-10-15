import 'package:flutter_test/flutter_test.dart';
import 'package:radar_a_rumeurs/features/analysis/domain/services/advice_similarity_policy.dart';

void main() {
  const String localAdviceAboutLinks =
      "Ne cliquez sur aucun lien et n'ouvrez aucune pièce jointe de ce message.";
  const String localAdviceAboutOfficialService =
      "Si le message prétend venir d'un service connu, ouvrez son application officielle ou appelez son numéro officiel.";
  const String localAdviceAboutUnknownSender =
      "Si le message vient d'un inconnu, bloquez et signalez l'expéditeur.";

  const List<String> localAdvice = <String>[
    localAdviceAboutLinks,
    localAdviceAboutOfficialService,
    localAdviceAboutUnknownSender,
  ];

  group('AdviceSimilarityPolicy', () {
    test('treats the same text as a repeat, ignoring case and spaces', () {
      expect(
        AdviceSimilarityPolicy.isTooSimilar(
          candidateAdvice: '  NE CLIQUEZ SUR AUCUN LIEN ET N\'OUVREZ AUCUNE '
              'PIÈCE JOINTE DE CE MESSAGE.  ',
          existingAdvices: localAdvice,
        ),
        isTrue,
      );
    });

    test('treats the same advice in other words as a repeat', () {
      expect(
        AdviceSimilarityPolicy.isTooSimilar(
          candidateAdvice: 'Ne cliquez sur aucun lien contenu dans ce message.',
          existingAdvices: localAdvice,
        ),
        isTrue,
      );
    });

    test('keeps advice that only shares a few words with local advice', () {
      expect(
        AdviceSimilarityPolicy.isTooSimilar(
          candidateAdvice: 'Signalez le message comme spam, puis supprimez-le.',
          existingAdvices: localAdvice,
        ),
        isFalse,
      );
    });

    test('keeps advice that names a specific service', () {
      expect(
        AdviceSimilarityPolicy.isTooSimilar(
          candidateAdvice:
              "Contactez directement le service client officiel de Wave pour vérifier l'information.",
          existingAdvices: localAdvice,
        ),
        isFalse,
      );
    });

    test('keeps texts that differ only by a number', () {
      expect(
        AdviceSimilarityPolicy.isTooSimilar(
          candidateAdvice: 'Action IA 2',
          existingAdvices: const <String>['Action IA 1'],
        ),
        isFalse,
      );
    });

    test('ignores an empty advice', () {
      expect(
        AdviceSimilarityPolicy.isTooSimilar(
          candidateAdvice: '   ',
          existingAdvices: localAdvice,
        ),
        isTrue,
      );
    });

    test('keeps any advice when nothing is shown yet', () {
      expect(
        AdviceSimilarityPolicy.isTooSimilar(
          candidateAdvice: 'Ne cliquez sur aucun lien.',
          existingAdvices: const <String>[],
        ),
        isFalse,
      );
    });
  });
}
