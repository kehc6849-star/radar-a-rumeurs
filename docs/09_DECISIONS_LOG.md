# 09 — Journal des décisions

*Une ligne par décision importante. Les plus récentes sont en bas.*

| Date | Décision | Raison |
|---|---|---|
| 2026-10-07 | Track **Civic Tech & services publics** | L'application protège les citoyens contre la fraude et la désinformation. |
| 2026-10-07 | **Flutter / Dart** (mobile) | Aucune stack imposée par l'événement ; matériel déjà prêt. |
| 2026-10-07 | Un **moteur unique** pour tous les types de contenu | Rend le périmètre global réalisable dans le temps imparti. |
| 2026-10-07 | Pas de détection fiable d'images ou vidéos générées par IA | Aucun outil fiable aujourd'hui : on affichera des indices, jamais un verdict. |
| 2026-10-07 | Jamais de verdict « sûr » | L'absence de signal ne prouve pas la fiabilité. |
| 2026-10-07 | Licence **MIT** pour le code source | Simple, permissive, largement reconnue comme open source. |
| 2026-10-08 | Règles locales d'abord, IA ensuite | Rapide, gratuit, hors-ligne, transparent ; l'IA complète. |
| 2026-10-10 | Documentation en plusieurs fichiers dans `docs/` | Exigence du hackathon et suivi au fil de l'eau. |
| 2026-10-12 | **Gemma 4** via l'API Gemini comme fournisseur d'IA | Proposé par les organisateurs, modèle ouvert, multimodal ; vise le prix « Best Use of Gemma 4 ». |
| 2026-10-12 | Modèle principal `gemma-4-26b-a4b-it`, secours `gemma-4-31b-it` | Rapidité et économie de quota ; chaque modèle a son propre quota. |
| 2026-10-12 | Serveur intermédiaire (FastAPI) | La clé d'API ne doit pas être dans l'application mobile. |
| 2026-10-12 | L'IA ne peut jamais baisser le risque trouvé par les règles locales | Garde-fou contre la manipulation du modèle. |
| 2026-10-12 | Le niveau affiché vient du score, jamais des mots du modèle | Pas de niveau « sûr » ; résiste à la manipulation. |
| 2026-10-12 | Images envoyées dans la requête, pas téléversées comme fichiers | Rien ne reste chez le fournisseur sous forme de fichier. |
| 2026-10-12 | Historique local sans le contenu analysé | Ne peut pas révéler les messages reçus. |
| 2026-10-12 | Envoi à l'IA seulement après accord explicite ; fermer l'écran = refus | Transparence sur les conditions du fournisseur gratuit. |
| 2026-10-12 | Peu de dépendances (serveur : FastAPI, HTTPX, Uvicorn, python-multipart) | Moins de risques de licence et de maintenance. |

## Licence : notes

- La licence couvre **le code source du dépôt public** (pas l'événement).
- Le fichier `LICENSE` est à la racine du dépôt. Il est mentionné dans le README.
- Le titulaire du droit d'auteur indiqué est actuellement « Radar à Rumeurs contributors ». Il peut être remplacé par le nom du ou des auteurs.
- Alternatives considérées : Apache-2.0 (permissive avec clause explicite sur les brevets) ; GPL ou AGPL (obligent à partager les modifications).
- Cette note n'est pas un avis juridique.
