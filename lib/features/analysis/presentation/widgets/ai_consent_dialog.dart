import 'package:flutter/material.dart';

import '../../domain/models/ai_consent_status.dart';

const String _consentExplanation =
    "Pour mieux repérer les arnaques, l'application peut envoyer le texte ou la capture d'écran que vous analysez à notre serveur, qui le transmet au modèle d'intelligence artificielle Gemma 4 (via l'API Gemini de Google).\n\n"
    "• Notre serveur ne conserve pas votre contenu.\n"
    "• Le fournisseur d'IA peut le traiter selon ses propres conditions, qui peuvent inclure l'amélioration de ses produits sur l'offre gratuite.\n"
    "• N'envoyez pas de données très sensibles (codes, mots de passe, pièces d'identité).\n"
    "• Vous pouvez refuser : l'analyse locale, sur votre téléphone, reste disponible.\n"
    "• Vous pouvez changer d'avis à tout moment avec l'icône bouclier.";

/// Asks the user whether content may be sent to the AI service.
///
/// Closing the dialog in any other way counts as a refusal: no consent
/// means nothing is sent.
Future<AiConsentStatus> showAiConsentDialog(BuildContext context) async {
  final AiConsentStatus? decision = await showDialog<AiConsentStatus>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: const Text('Analyse par intelligence artificielle'),
        content: const SingleChildScrollView(
          child: Text(_consentExplanation),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(AiConsentStatus.declined),
            child: const Text('Rester hors-ligne'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(AiConsentStatus.granted),
            child: const Text("Autoriser l'analyse IA"),
          ),
        ],
      );
    },
  );

  return decision ?? AiConsentStatus.declined;
}
