# 03 — Utilisation de l'IA

*Exigence du hackathon : l'IA doit jouer un rôle pertinent et identifiable, et les modèles, APIs et outils IA principaux doivent être déclarés. Mis à jour le 18 octobre 2026 (version 1.0).*

## Le modèle : Gemma 4

Nous utilisons **Gemma 4**, un modèle à poids ouverts de Google DeepMind, appelé via l'**API Gemini** (Google AI Studio).

| Rôle | Modèle | Pourquoi |
|---|---|---|
| Principal | `gemma-4-26b-a4b-it` | Plus léger, donc plus rapide et moins coûteux en quota |
| Secours | `gemma-4-31b-it` | Utilisé automatiquement si le principal est saturé ou indisponible |

Pourquoi Gemma 4 : modèle **ouvert** (cohérent avec la démarche open source du projet), **multimodal** (texte et images, ce qui permet l'analyse de captures d'écran), proposé par les organisateurs. Le projet vise les catégories de prix « Best Use of Gemma 4 » et « Best Open-Source AI Project » en plus du prix de l'événement.

## Ce que l'IA fait dans le produit

| Rôle | Description | État |
|---|---|---|
| Analyse du sens d'un message | Évalue l'intention (urgence, usurpation, demande d'argent ou de code, rumeur) au-delà des mots-clés | ✅ Lot 2 |
| Lecture des captures d'écran | Lit le texte visible d'une image, puis l'analyse | ✅ Lot 2 |
| Explication et conseils | Rédige des signaux et des conseils en français simple | ✅ Lot 2 |
| Contenu partagé depuis une autre application | Un texte ou une image envoyé à Zero Trust par « Partager » ou par la sélection de texte suit le même chemin que le texte collé ou la capture, avec le même accord avant tout envoi à l'IA | ✅ Version 1.0 |
| Transcription des vocaux | Reconnaissance vocale | ❌ Hors périmètre de la version 1.0 (l'analyse audio n'est pas confirmée par l'API) |

## Comment l'IA et les règles locales travaillent ensemble

1. Les **règles locales** analysent toujours le message en premier, sur le téléphone.
2. Si le serveur est configuré **et** que l'utilisateur a donné son accord, le message (ou la capture) est envoyé au serveur, qui interroge Gemma 4.
3. Les deux résultats sont **fusionnés** : le score final est le plus élevé des deux. **L'IA peut relever le risque, jamais le baisser sous ce qu'ont trouvé les règles locales.** C'est un garde-fou contre les messages qui tentent de manipuler le modèle.
4. Pour une capture, les règles locales sont aussi appliquées sur le texte lu par l'IA.
5. Si l'IA est indisponible, le résultat des règles locales est affiché avec une note claire.
6. Le serveur limite l'attente de l'IA à 36 secondes au total (modèle principal, puis modèle de secours s'il reste du temps), et journalise chaque échec avec des informations techniques seulement, jamais le contenu analysé.

## Protection contre la manipulation du modèle (« prompt injection »)

- Le message à analyser est présenté au modèle comme une **donnée non fiable**, entre des marqueurs, avec l'ordre explicite de ne suivre aucune instruction qu'il contient.
- La réponse du modèle est **vérifiée par du code** : format imposé, score borné, famille de menace limitée à une liste connue, nombre et longueur des textes limités.
- Le **niveau** affiché est calculé à partir du score, jamais à partir des mots du modèle. Il n'existe pas de niveau « sûr ».

## Déclaration des modèles, APIs et outils

| Élément | Type | Usage | Statut |
|---|---|---|---|
| Gemma 4 (`gemma-4-26b-a4b-it`, `gemma-4-31b-it`) | Modèle ouvert de Google DeepMind | Analyse de messages et lecture de captures d'écran | Intégré (lot 2) |
| API Gemini (Google AI Studio) | API d'accès au modèle | Appel du modèle depuis notre serveur | Intégré (lot 2) |
| Claude (Anthropic) | Assistant de développement | Production et relecture assistée du code et de la documentation, et préparation des fichiers d'icône à partir du logo | Utilisé |
| Chat-GPT (Open AI) | Générateur d'images par IA | Création du logo de l'application (plusieurs versions générées, une retenue) | Utilisé |

**Licence du modèle** : la page de licence de Gemma 4 renvoie à la licence Apache 2.0 (à revérifier avant la soumission).

**Précision honnête** : pendant la démonstration, le modèle est appelé via l'API hébergée par Google, et non exécuté sur nos propres machines. Notre serveur d'analyse, qui appelle cette API, est hébergé sur Render (offre gratuite). Les poids étant ouverts, un hébergement autonome reste possible à l'avenir.

## Limites assumées

- L'IA peut se tromper : les résultats sont des **estimations**.
- Aucune promesse de détection fiable des images ou vidéos générées par IA.
- Le serveur n'envoie à l'IA que ce que l'utilisateur a choisi d'analyser, et seulement après son accord (voir [confidentialité](05_PRIVACY_AND_SECURITY.md)).
- Certaines images peuvent échouer à l'analyse (cause à confirmer : limites de l'API ou délai) ; l'analyse d'un texte reste disponible hors-ligne, sur le téléphone.
- Les quotas du compte gratuit sont limités : voir [11 — Quotas et limites](11_AI_QUOTAS_AND_LIMITS.md).
