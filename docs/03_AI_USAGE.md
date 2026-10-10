# 03 — Utilisation de l'IA

*Exigence du hackathon : l'IA doit jouer un rôle pertinent et identifiable, et les principaux modèles, APIs et outils IA doivent être déclarés. Ce document est mis à jour à chaque intégration.*

## État actuel (lot 1)

**Aucune IA n'est embarquée dans le produit pour l'instant.** Le moteur est un système de règles transparent et testable. L'intégration de l'IA est le prochain lot (voir [feuille de route](07_ROADMAP.md)).

## Rôle prévu de l'IA dans le produit

| Rôle | Description | État |
|---|---|---|
| Lecture des captures d'écran | Un modèle de vision extrait le texte d'une capture (SMS, discussion). | 🔜 |
| Transcription des vocaux | Un modèle de reconnaissance vocale convertit un vocal en texte. | 🔜 |
| Analyse du sens | Un modèle de langage évalue l'intention (urgence, usurpation, affirmation vérifiable) au-delà des mots-clés. | 🔜 |
| Explication | Le modèle rédige une explication claire et les conseils adaptés. | 🔜 |

Les règles locales restent en première ligne : elles sont rapides, gratuites et fonctionnent hors-ligne. L'IA complète ce que les règles ne savent pas voir.

## Déclaration des modèles, APIs et outils

| Élément | Type | Usage | Statut |
|---|---|---|---|
| *À renseigner* | Modèle / API | *Lecture des captures* | Non intégré |
| *À renseigner* | Modèle / API | *Analyse et explication* | Non intégré |
| Claude (Anthropic) | Outil d'aide au développement | Production et relecture assistée du code et de la documentation | Utilisé |

> Chaque ligne « à renseigner » sera remplacée par le nom exact du modèle ou de l'API, sa licence ou ses conditions d'usage, et la raison du choix.

## Limites assumées

- L'IA peut se tromper : les résultats sont présentés comme des **estimations**.
- Aucune promesse de détection fiable des images ou vidéos générées par IA.
- Les messages ne seront envoyés à un service externe qu'avec une information claire pour l'utilisateur (voir [confidentialité](05_PRIVACY_AND_SECURITY.md)).
