import '../models/threat_family.dart';

/// Practical advice shown after an analysis, by theme.
class SafetyAdviceCatalog {
  const SafetyAdviceCatalog._();

  static const String _genericAdvice =
      "Si le message vient d'un inconnu, bloquez et signalez l'expéditeur.";

  static const Map<ThreatFamily, List<String>> _adviceByFamily =
      <ThreatFamily, List<String>>{
    ThreatFamily.mobileMoneyFraud: <String>[
      'Ne communiquez jamais votre code secret ni les codes reçus par SMS, même à une personne qui se dit du service client.',
      "Vérifiez votre solde et votre historique dans l'application officielle, jamais via un lien reçu.",
      'En cas de transfert « par erreur », ne renvoyez rien vous-même : demandez à votre opérateur de traiter la réclamation.',
    ],
    ThreatFamily.scholarshipScam: <String>[
      'Une bourse légitime ne demande normalement pas de frais pour être sélectionné : ne payez rien.',
      "Vérifiez l'offre sur le site officiel de l'organisme, en tapant vous-même l'adresse dans le navigateur.",
    ],
    ThreatFamily.phishing: <String>[
      "Ne cliquez sur aucun lien et n'ouvrez aucune pièce jointe de ce message.",
      "Si le message prétend venir d'un service connu, ouvrez son application officielle ou appelez son numéro officiel.",
    ],
    ThreatFamily.misinformation: <String>[
      "Avant de partager, cherchez la même information chez plusieurs médias reconnus ou sur des sites de vérification.",
      "Méfiez-vous des messages qui demandent de partager à tout prix : c'est un signe classique de rumeur.",
    ],
    ThreatFamily.fraudulentOffer: <String>[
      "Une offre d'emploi, de visa ou d'investissement sérieuse ne demande pas de payer avant d'avoir commencé : ne versez rien.",
      "Méfiez-vous des gains « garantis » ou rapides : renseignez-vous auprès d'une institution officielle avant tout paiement.",
    ],
  };

  /// Builds the advice list for the given themes, without duplicates.
  /// The order follows the order of the themes (strongest signal first).
  static List<String> buildAdvice(Iterable<ThreatFamily> families) {
    final Set<String> orderedAdvice = <String>{};

    for (final ThreatFamily family in families) {
      orderedAdvice.addAll(_adviceByFamily[family] ?? const <String>[]);
    }

    if (orderedAdvice.isEmpty) {
      return const <String>[];
    }

    orderedAdvice.add(_genericAdvice);

    return orderedAdvice.toList(growable: false);
  }
}
